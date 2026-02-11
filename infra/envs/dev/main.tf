# Development Environment Configuration
# =============================================================================
# PHILOSOPHY: Simple, cheap, fast iteration
# - Minimal resources, no expensive security features
# - Everything still works, just simplified
# =============================================================================

terraform {
  required_version = ">= 1.5.0"
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
  name     = "${var.project_name}-rg-dev"
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
  environment       = "dev"
  location          = var.location
  cost_center       = var.cost_center
  owner_email       = var.owner_email
  repository_url    = var.repository_url
}

# =============================================================================
# NETWORKING - Always created (foundation)
# =============================================================================
module "networking" {
  source = "../../modules/networking"

  resource_group_name = azurerm_resource_group.main.name
  network_name        = "${var.project_name}-vnet-dev"
  location            = var.location
  address_space       = ["10.1.0.0/16"]

  subnets = {
    "aks-subnet" = {
      address_prefixes  = ["10.1.1.0/24"]
      service_endpoints = ["Microsoft.Sql", "Microsoft.Storage", "Microsoft.KeyVault"]
    }
    "app-subnet" = {
      address_prefixes  = ["10.1.2.0/24"]
      service_endpoints = ["Microsoft.Sql", "Microsoft.Storage"]
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
      }
    }
  }

  subnet_nsg_associations = {
    "aks-subnet" = "aks-nsg"
  }

  # Feature toggle: NAT Gateway
  create_nat_gateway = var.enable_nat_gateway

  tags = module.global_standards.common_tags
}

# =============================================================================
# LOG ANALYTICS - Always created (need to see what's happening)
# =============================================================================
resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.project_name}-logs-dev"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days

  tags = module.global_standards.common_tags
}

# =============================================================================
# APPLICATION INSIGHTS - Optional (controlled by feature toggle)
# =============================================================================
resource "azurerm_application_insights" "main" {
  count = var.enable_application_insights ? 1 : 0

  name                = "${var.project_name}-insights-dev"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"

  tags = module.global_standards.common_tags
}

# =============================================================================
# KEY VAULT - Recommended for all environments
# =============================================================================
module "security" {
  count  = var.enable_key_vault ? 1 : 0
  source = "../../modules/security"

  resource_group_name = azurerm_resource_group.main.name
  key_vault_name      = "${var.project_name}kvdev"  # Alphanumeric + hyphens, 3-24 chars
  location            = var.location
  tenant_id           = var.tenant_id

  # Feature toggles
  purge_protection_enabled   = var.key_vault_purge_protection
  network_acls_default_action = var.network_acl_default_action

  tags = module.global_standards.common_tags
}

# =============================================================================
# AKS - Optional (controlled by feature toggle)
# =============================================================================
module "aks" {
  count  = var.enable_aks ? 1 : 0
  source = "../../modules/aks"

  resource_group_name = azurerm_resource_group.main.name
  cluster_name        = "${var.project_name}-aks-dev"
  location            = var.location
  dns_prefix          = "${var.project_name}-dev"

  # Networking
  vnet_subnet_id = module.networking.subnet_ids["aks-subnet"]

  # Scaling - Dev uses fixed small size
  node_count     = var.aks_node_count
  vm_size        = var.aks_node_size
  enable_auto_scaling = var.enable_auto_scaling

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
  environment_name    = "${var.project_name}-cae-dev"
  location            = var.location

  # Networking
  infrastructure_subnet_id = module.networking.subnet_ids["app-subnet"]

  # Monitoring
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  tags = module.global_standards.common_tags
}

# =============================================================================
# COSMOS DB - Optional (controlled by feature toggle)
# =============================================================================
module "cosmosdb" {
  count  = var.enable_cosmosdb ? 1 : 0
  source = "../../modules/cosmosdb"

  resource_group_name = azurerm_resource_group.main.name
  account_name        = "${var.project_name}cosmosdev"  # No hyphens
  location            = var.location

  # Feature toggles - Dev uses minimal settings
  enable_automatic_failover       = false
  enable_multiple_write_locations = false
  public_network_access_enabled   = true  # Public access OK for dev
  backup_type                     = "Periodic"

  tags = module.global_standards.common_tags
}

# =============================================================================
# WEB APP - Optional (controlled by feature toggle)
# =============================================================================
module "webapp" {
  count  = var.enable_webapp ? 1 : 0
  source = "../../modules/webapp"

  resource_group_name = azurerm_resource_group.main.name
  app_name            = "${var.project_name}-app-dev"
  location            = var.location

  # SKU - Dev uses free/basic tier
  sku_name = "F1"  # Free tier for dev

  tags = module.global_standards.common_tags
}
