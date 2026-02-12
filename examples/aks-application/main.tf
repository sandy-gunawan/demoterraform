# Complete AKS Application Deployment

terraform {
  required_version = ">= 1.5.0"
}

# Provider configuration
provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "app" {
  name     = "${var.project_name}-${var.app_name}-rg"
  location = var.location
  tags     = local.common_tags
}

# Networking Module
module "networking" {
  source = "../../infra/modules/networking"

  resource_group_name = azurerm_resource_group.app.name
  network_name        = "${var.project_name}-${var.app_name}-vnet"
  location            = var.location
  address_space       = ["10.10.0.0/16"]

  subnets = {
    "aks-subnet" = {
      address_prefixes = ["10.10.1.0/24"]
      service_endpoints = [
        "Microsoft.Sql",
        "Microsoft.Storage",
        "Microsoft.KeyVault",
        "Microsoft.AzureCosmosDB"
      ]
    }
    "app-subnet" = {
      address_prefixes = ["10.10.2.0/24"]
      service_endpoints = [
        "Microsoft.Storage",
        "Microsoft.KeyVault",
        "Microsoft.AzureCosmosDB"
      ]
    }
    "private-endpoints-subnet" = {
      address_prefixes = ["10.10.3.0/24"]
    }
  }

  network_security_groups = {
    "aks-nsg" = {
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
        "allow-http" = {
          priority                   = 110
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "80"
          source_address_prefix      = "VirtualNetwork"
          destination_address_prefix = "*"
        }
      }
    }
  }

  subnet_nsg_associations = {
    "aks-subnet" = "aks-nsg"
  }

  create_nat_gateway = true

  tags = local.common_tags
}

# Log Analytics for Monitoring
resource "azurerm_log_analytics_workspace" "app" {
  name                = "${var.project_name}-${var.app_name}-logs"
  location            = var.location
  resource_group_name = azurerm_resource_group.app.name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days

  tags = local.common_tags
}

# AKS Cluster
module "aks" {
  source = "../../infra/modules/aks"

  resource_group_name = azurerm_resource_group.app.name
  cluster_name        = "${var.project_name}-${var.app_name}-aks"
  location            = var.location
  dns_prefix          = "${var.project_name}-${var.app_name}"
  kubernetes_version  = var.kubernetes_version

  # Node pool configuration
  node_count          = var.aks_system_node_count
  vm_size             = var.aks_system_node_size
  enable_auto_scaling = true
  min_node_count      = var.aks_system_min_nodes
  max_node_count      = var.aks_system_max_nodes

  vnet_subnet_id             = module.networking.subnet_ids["aks-subnet"]
  log_analytics_workspace_id = azurerm_log_analytics_workspace.app.id
  tenant_id                  = var.tenant_id
  admin_group_object_ids     = var.admin_group_object_ids
  enable_azure_policy        = var.enable_azure_policy

  tags = local.common_tags
}

# Cosmos DB for Application Data
module "cosmosdb" {
  source = "../../infra/modules/cosmosdb"

  resource_group_name = azurerm_resource_group.app.name
  account_name        = "${var.project_name}${var.app_name}cosmos"
  location            = var.location
  consistency_level   = var.cosmos_consistency_level

  # Multi-region configuration
  failover_locations = var.cosmos_failover_locations

  # Network security
  public_network_access_enabled = var.cosmos_public_access
  enable_virtual_network_filter = !var.cosmos_public_access
  virtual_network_rules = var.cosmos_public_access ? [] : [
    module.networking.subnet_ids["app-subnet"],
    module.networking.subnet_ids["private-endpoints-subnet"]
  ]

  # Backup configuration
  backup_type                     = var.cosmos_backup_type
  backup_storage_redundancy       = "Geo"
  enable_automatic_failover       = true
  enable_multiple_write_locations = var.cosmos_multi_region_writes

  # Database and containers
  sql_databases = {
    "AppDatabase" = {
      autoscale_max_throughput = var.cosmos_database_max_throughput
    }
  }

  sql_containers = {
    "users" = {
      database_name            = "AppDatabase"
      partition_key_paths      = ["/userId"]
      partition_key_version    = 2
      autoscale_max_throughput = 4000
      indexing_mode            = "consistent"
      included_paths           = ["/*"]
      excluded_paths           = ["/metadata/?", "/largeData/?"]
    }

    "products" = {
      database_name            = "AppDatabase"
      partition_key_paths      = ["/category"]
      partition_key_version    = 2
      autoscale_max_throughput = 2000
      analytical_storage_ttl   = -1 # Enable analytical store
    }

    "orders" = {
      database_name            = "AppDatabase"
      partition_key_paths      = ["/customerId", "/year"] # Hierarchical
      partition_key_version    = 2
      autoscale_max_throughput = 10000
      default_ttl              = 63072000 # 2 years
    }

    "sessions" = {
      database_name            = "AppDatabase"
      partition_key_paths      = ["/sessionId"]
      partition_key_version    = 2
      autoscale_max_throughput = 1000
      default_ttl              = 86400 # 24 hours
    }
  }

  log_analytics_workspace_id = azurerm_log_analytics_workspace.app.id

  tags = local.common_tags
}

# Key Vault for Secrets
resource "azurerm_key_vault" "app" {
  name                       = "${var.project_name}-${var.app_name}-kv"
  location                   = var.location
  resource_group_name        = azurerm_resource_group.app.name
  tenant_id                  = var.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = var.environment == "production"

  network_acls {
    default_action = var.key_vault_public_access ? "Allow" : "Deny"
    bypass         = "AzureServices"
    virtual_network_subnet_ids = var.key_vault_public_access ? [] : [
      module.networking.subnet_ids["aks-subnet"],
      module.networking.subnet_ids["app-subnet"]
    ]
  }

  tags = local.common_tags
}

# Store Cosmos DB connection string in Key Vault
resource "azurerm_key_vault_secret" "cosmosdb_connection" {
  name         = "cosmosdb-connection-string"
  value        = module.cosmosdb.cosmosdb_primary_sql_connection_string
  key_vault_id = azurerm_key_vault.app.id

  depends_on = [azurerm_key_vault.app]
}

# Key Vault access for AKS
resource "azurerm_key_vault_access_policy" "aks" {
  key_vault_id = azurerm_key_vault.app.id
  tenant_id    = var.tenant_id
  object_id    = module.aks.kubelet_identity_object_id

  secret_permissions = [
    "Get",
    "List"
  ]

  depends_on = [module.aks]
}

# Locals
locals {
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      Application = var.app_name
      ManagedBy   = "Terraform"
      Example     = "AKS-Application"
    }
  )
}
