# Azure Landing Zone Configuration

terraform {
  required_version = ">= 1.5.0"
}

provider "azurerm" {
  features {}
}

# Management Resource Group
resource "azurerm_resource_group" "hub" {
  name     = "${var.organization_name}-hub-rg"
  location = var.location
  tags     = local.common_tags
}

# Centralized Log Analytics
resource "azurerm_log_analytics_workspace" "hub" {
  name                = "${var.organization_name}-hub-logs"
  location            = var.location
  resource_group_name = azurerm_resource_group.hub.name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days

  tags = local.common_tags
}

# Hub Virtual Network
module "hub_network" {
  source = "../../infra/modules/networking"

  resource_group_name = azurerm_resource_group.hub.name
  network_name        = "${var.organization_name}-hub-vnet"
  location            = var.location
  address_space       = [var.hub_address_space]

  subnets = {
    "GatewaySubnet" = {
      address_prefixes  = [cidrsubnet(var.hub_address_space, 8, 1)]
      service_endpoints = []
    }
    "AzureFirewallSubnet" = {
      address_prefixes  = [cidrsubnet(var.hub_address_space, 8, 2)]
      service_endpoints = []
    }
    "AzureBastionSubnet" = {
      address_prefixes  = [cidrsubnet(var.hub_address_space, 8, 3)]
      service_endpoints = []
    }
    "shared-services-subnet" = {
      address_prefixes = [cidrsubnet(var.hub_address_space, 8, 4)]
      service_endpoints = [
        "Microsoft.Storage",
        "Microsoft.KeyVault",
        "Microsoft.ContainerRegistry",
        "Microsoft.AzureCosmosDB"
      ]
    }
  }

  network_security_groups = {
    "shared-services-nsg" = {
      security_rules = {
        "allow-https" = {
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "443"
          source_address_prefix      = "VirtualNetwork"
          destination_address_prefix = "*"
        }
      }
    }
  }

  subnet_nsg_associations = {
    "shared-services-subnet" = "shared-services-nsg"
  }

  tags = local.common_tags
}

# Shared Key Vault
resource "azurerm_key_vault" "shared" {
  name                       = "${var.organization_name}-shared-kv"
  location                   = var.location
  resource_group_name        = azurerm_resource_group.hub.name
  tenant_id                  = var.tenant_id
  sku_name                   = "premium"
  soft_delete_retention_days = 90
  purge_protection_enabled   = true

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
    virtual_network_subnet_ids = [
      module.hub_network.subnet_ids["shared-services-subnet"]
    ]
  }

  tags = local.common_tags
}

# Shared Azure Container Registry
resource "azurerm_container_registry" "shared" {
  name                = "${replace(var.organization_name, "-", "")}acr"
  location            = var.location
  resource_group_name = azurerm_resource_group.hub.name
  sku                 = "Premium"
  admin_enabled       = false

  georeplications {
    location                = var.secondary_location
    zone_redundancy_enabled = true
  }

  network_rule_set {
    default_action = "Deny"

    virtual_network {
      action    = "Allow"
      subnet_id = module.hub_network.subnet_ids["shared-services-subnet"]
    }
  }

  tags = local.common_tags
}

# Shared Cosmos DB
module "shared_cosmosdb" {
  source = "../../infra/modules/cosmosdb"

  resource_group_name = azurerm_resource_group.hub.name
  account_name        = "${var.organization_name}-shared-cosmos"
  location            = var.location
  consistency_level   = "Session"

  failover_locations = [
    {
      location          = var.secondary_location
      failover_priority = 1
    }
  ]

  public_network_access_enabled = false
  enable_virtual_network_filter = true
  virtual_network_rules = [
    module.hub_network.subnet_ids["shared-services-subnet"]
  ]

  backup_type                     = "Continuous"
  enable_automatic_failover       = true
  enable_multiple_write_locations = true

  sql_databases = {
    "SharedData" = {
      autoscale_max_throughput = 4000
    }
  }

  sql_containers = {
    "configuration" = {
      database_name            = "SharedData"
      partition_key_paths      = ["/tenantId"]
      autoscale_max_throughput = 1000
    }
  }

  log_analytics_workspace_id = azurerm_log_analytics_workspace.hub.id

  tags = local.common_tags
}

# Spoke Networks
module "spoke_networks" {
  source   = "../../infra/modules/networking"
  for_each = var.spoke_networks

  resource_group_name = azurerm_resource_group.hub.name
  network_name        = "${var.organization_name}-${each.key}-vnet"
  location            = var.location
  address_space       = [each.value.address_space]

  subnets = {
    "workload-subnet" = {
      address_prefixes = [cidrsubnet(each.value.address_space, 8, 1)]
      service_endpoints = [
        "Microsoft.Storage",
        "Microsoft.KeyVault",
        "Microsoft.ContainerRegistry",
        "Microsoft.AzureCosmosDB"
      ]
    }
    "data-subnet" = {
      address_prefixes = [cidrsubnet(each.value.address_space, 8, 2)]
      service_endpoints = [
        "Microsoft.Sql",
        "Microsoft.Storage",
        "Microsoft.AzureCosmosDB"
      ]
    }
    "private-endpoints-subnet" = {
      address_prefixes  = [cidrsubnet(each.value.address_space, 8, 3)]
      service_endpoints = []
    }
  }

  network_security_groups = {
    "workload-nsg" = {
      security_rules = {
        "allow-internal" = {
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "*"
          source_port_range          = "*"
          destination_port_range     = "*"
          source_address_prefix      = "VirtualNetwork"
          destination_address_prefix = "VirtualNetwork"
        }
      }
    }
  }

  subnet_nsg_associations = {
    "workload-subnet" = "workload-nsg"
    "data-subnet"     = "workload-nsg"
  }

  tags = merge(
    local.common_tags,
    {
      Environment = each.value.environment
      Application = each.value.application
      Spoke       = each.key
    }
  )
}

# VNet Peering: Spoke to Hub
resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  for_each = var.spoke_networks

  name                      = "${each.key}-to-hub"
  resource_group_name       = azurerm_resource_group.hub.name
  virtual_network_name      = module.spoke_networks[each.key].vnet_name
  remote_virtual_network_id = module.hub_network.vnet_id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

# VNet Peering: Hub to Spoke
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  for_each = var.spoke_networks

  name                      = "hub-to-${each.key}"
  resource_group_name       = azurerm_resource_group.hub.name
  virtual_network_name      = module.hub_network.vnet_name
  remote_virtual_network_id = module.spoke_networks[each.key].vnet_id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  use_remote_gateways          = false
}

# Locals
locals {
  common_tags = merge(
    var.tags,
    {
      ManagedBy      = "Terraform"
      LandingZone    = var.organization_name
      DeploymentType = "Hub-Spoke"
    }
  )
}
