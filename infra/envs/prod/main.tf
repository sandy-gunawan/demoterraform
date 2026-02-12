# Production Environment Configuration
# =============================================================================
# PHILOSOPHY: Maximum security, high availability, compliance-ready
# - All security features enabled
# - Auto-scaling, geo-redundancy, continuous backup
# =============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.45.0"
    }
  }
}

# =============================================================================
# PROVIDER CONFIGURATION
# =============================================================================
provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
  }
}

provider "azuread" {}

# =============================================================================
# RESOURCE GROUP - Always created
# =============================================================================
resource "azurerm_resource_group" "main" {
  name     = "${var.project_name}-rg-prod"
  location = var.location
  tags     = module.global_standards.common_tags
}

# =============================================================================
# GLOBAL STANDARDS - Naming, tagging, etc.
# =============================================================================
module "global_standards" {
  source = "../../global"

  organization_name = var.organization_name
  project_name      = var.project_name
  environment       = "prod"
  location          = var.location
  cost_center       = var.cost_center
  owner_email       = var.owner_email
  repository_url    = var.repository_url
}

# =============================================================================
# NETWORKING - With NAT Gateway and tighter security
# =============================================================================
module "networking" {
  source = "../../modules/networking"

  resource_group_name = azurerm_resource_group.main.name
  network_name        = "${var.project_name}-vnet-prod"
  location            = var.location
  address_space       = ["10.3.0.0/16"] # Different IP range for production

  subnets = {
    "aks-subnet" = {
      address_prefixes  = ["10.3.1.0/23"] # Larger subnet for production scale
      service_endpoints = ["Microsoft.Sql", "Microsoft.Storage", "Microsoft.KeyVault", "Microsoft.AzureCosmosDB"]
    }
    "app-subnet" = {
      address_prefixes  = ["10.3.3.0/24"]
      service_endpoints = ["Microsoft.Sql", "Microsoft.Storage", "Microsoft.AzureCosmosDB"]
    }
    "data-subnet" = {
      address_prefixes  = ["10.3.4.0/24"]
      service_endpoints = ["Microsoft.Sql", "Microsoft.Storage"]
    }
    "pe-subnet" = {
      address_prefixes  = ["10.3.5.0/24"] # For private endpoints
      service_endpoints = []
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
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        }
        "deny-all-inbound" = {
          priority                   = 4096
          direction                  = "Inbound"
          access                     = "Deny"
          protocol                   = "*"
          source_port_range          = "*"
          destination_port_range     = "*"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        }
      }
    }
    "app-nsg" = {
      security_rules = {
        "allow-https-from-vnet" = {
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "443"
          source_address_prefix      = "VirtualNetwork"
          destination_address_prefix = "*"
        }
        "deny-all-inbound" = {
          priority                   = 4096
          direction                  = "Inbound"
          access                     = "Deny"
          protocol                   = "*"
          source_port_range          = "*"
          destination_port_range     = "*"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        }
      }
    }
    "data-nsg" = {
      security_rules = {
        "allow-sql-from-app" = {
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "1433"
          source_address_prefix      = "10.3.3.0/24" # app-subnet
          destination_address_prefix = "*"
        }
        "deny-all-inbound" = {
          priority                   = 4096
          direction                  = "Inbound"
          access                     = "Deny"
          protocol                   = "*"
          source_port_range          = "*"
          destination_port_range     = "*"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        }
      }
    }
  }

  subnet_nsg_associations = {
    "aks-subnet"  = "aks-nsg"
    "app-subnet"  = "app-nsg"
    "data-subnet" = "data-nsg"
  }

  # Feature toggle: NAT Gateway ENABLED for production
  create_nat_gateway = var.enable_nat_gateway # true

  tags = module.global_standards.common_tags
}

# =============================================================================
# LOG ANALYTICS - With longer retention
# =============================================================================
resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.project_name}-logs-prod"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days # 90 days for production

  tags = module.global_standards.common_tags
}

# =============================================================================
# APPLICATION INSIGHTS - ENABLED for production monitoring
# =============================================================================
resource "azurerm_application_insights" "main" {
  count = var.enable_application_insights ? 1 : 0

  name                = "${var.project_name}-insights-prod"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"

  tags = module.global_standards.common_tags
}

# =============================================================================
# KEY VAULT - Full security: purge protection, network ACLs
# =============================================================================
module "security" {
  count  = var.enable_key_vault ? 1 : 0
  source = "../../modules/security"

  resource_group_name = azurerm_resource_group.main.name
  key_vault_name      = "${var.project_name}kvprod" # Alphanumeric + hyphens, 3-24 chars
  location            = var.location
  tenant_id           = var.tenant_id

  # Feature toggles - Production has all security features
  purge_protection_enabled    = var.key_vault_purge_protection # true
  network_acls_default_action = var.network_acl_default_action # Deny

  # Private endpoint for Key Vault (if enabled)
  enable_private_endpoint    = var.enable_private_endpoints
  private_endpoint_subnet_id = var.enable_private_endpoints ? module.networking.subnet_ids["pe-subnet"] : null
  vnet_id                    = module.networking.vnet_id

  tags = module.global_standards.common_tags
}

# =============================================================================
# AKS - With auto-scaling enabled
# =============================================================================
module "aks" {
  count  = var.enable_aks ? 1 : 0
  source = "../../modules/aks"

  resource_group_name = azurerm_resource_group.main.name
  cluster_name        = "${var.project_name}-aks-prod"
  location            = var.location
  dns_prefix          = "${var.project_name}-prod"

  # Networking
  vnet_subnet_id = module.networking.subnet_ids["aks-subnet"]

  # Scaling - Production has auto-scaling
  node_count          = var.aks_node_count      # 3 minimum
  max_node_count      = var.aks_max_node_count  # Scale to 10
  vm_size             = var.aks_node_size       # Standard_D4s_v3
  enable_auto_scaling = var.enable_auto_scaling # true

  # Monitoring
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  tags = module.global_standards.common_tags
}

# =============================================================================
# CONTAINER APPS - Optional (controlled by feature toggle)
# =============================================================================
module "container_apps" {
  count  = var.enable_container_apps ? 1 : 0
  source = "../../modules/container-app"

  resource_group_name = azurerm_resource_group.main.name
  environment_name    = "${var.project_name}-cae-prod"
  location            = var.location

  # Networking
  infrastructure_subnet_id = module.networking.subnet_ids["app-subnet"]

  # Monitoring
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  tags = module.global_standards.common_tags
}

# =============================================================================
# COSMOS DB - With geo-redundancy and continuous backup
# =============================================================================
module "cosmosdb" {
  count  = var.enable_cosmosdb ? 1 : 0
  source = "../../modules/cosmosdb"

  resource_group_name = azurerm_resource_group.main.name
  account_name        = "${var.project_name}cosmosprod" # No hyphens
  location            = var.location

  # Feature toggles - Production has all reliability features
  enable_automatic_failover       = true                          # Auto-failover
  enable_multiple_write_locations = var.enable_geo_redundancy     # Multi-region writes
  public_network_access_enabled   = !var.enable_private_endpoints # Private only if PE enabled
  backup_type                     = var.enable_continuous_backup ? "Continuous" : "Periodic"

  # Private endpoint for Cosmos DB (if enabled)
  enable_private_endpoint    = var.enable_private_endpoints
  private_endpoint_subnet_id = var.enable_private_endpoints ? module.networking.subnet_ids["pe-subnet"] : null
  vnet_id                    = module.networking.vnet_id

  tags = module.global_standards.common_tags
}

# =============================================================================
# WEB APP - Optional (controlled by feature toggle)
# =============================================================================
module "webapp" {
  count  = var.enable_webapp ? 1 : 0
  source = "../../modules/webapp"

  resource_group_name = azurerm_resource_group.main.name
  app_name            = "${var.project_name}-app-prod"
  location            = var.location

  # SKU - Production uses premium tier
  sku_name = "P1v3" # Premium for production

  tags = module.global_standards.common_tags
}

# =============================================================================
# DDOS PROTECTION PLAN - For production (expensive but important)
# =============================================================================
resource "azurerm_network_ddos_protection_plan" "main" {
  count = var.enable_ddos_protection ? 1 : 0

  name                = "${var.project_name}-ddos-prod"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  tags = module.global_standards.common_tags
}
