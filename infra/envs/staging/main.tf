# Staging Environment Configuration
# =============================================================================
# PHILOSOPHY: Test before production
# - Add monitoring and basic hardening
# - Still cost-conscious, no expensive features
#
# 🎓 HOW STAGING DIFFERS FROM DEV (progressive security):
#    ┌────────────────────────────┬───────────┬────────────┐
#    │ Feature                     │ Dev        │ Staging      │
#    ├────────────────────────────┼───────────┼────────────┤
#    │ App Insights (monitoring)    │ OFF        │ ON           │
#    │ Key Vault purge protection  │ OFF        │ ON           │
#    │ Network ACLs                │ Allow      │ Deny         │
#    │ Log retention               │ 30 days    │ 60 days      │
#    │ AKS nodes                   │ 1          │ 2            │
#    │ Extra subnet (data)         │ NO         │ YES          │
#    └────────────────────────────┴───────────┴────────────┘
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
# 🎓 SAME provider settings as dev/main.tf — consistency across ALL environments.
# See infra/envs/dev/main.tf for detailed explanation of each feature.
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
  name     = "${var.project_name}-rg-staging"
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
  environment       = "staging"
  location          = var.location
  cost_center       = var.cost_center
  owner_email       = var.owner_email
  repository_url    = var.repository_url
}

# =============================================================================
# NETWORKING - Foundation (10.2.0.0/16 range for staging)
# =============================================================================
# 🎓 STAGING DIFFERENCES FROM DEV:
#    - Different IP range: 10.2.0.0/16 (dev uses 10.1.0.0/16)
#    - Extra subnet: "data-subnet" for database isolation
#    - App NSG restricts source to VirtualNetwork only (not open to all like dev)
# =============================================================================
module "networking" {
  source = "../../modules/networking"

  resource_group_name = azurerm_resource_group.main.name
  network_name        = "${var.project_name}-vnet-staging"
  location            = var.location
  address_space       = ["10.2.0.0/16"] # Different IP range for staging

  subnets = {
    "aks-subnet" = {
      address_prefixes  = ["10.2.1.0/24"]
      service_endpoints = ["Microsoft.Sql", "Microsoft.Storage", "Microsoft.KeyVault", "Microsoft.AzureCosmosDB"]
    }
    "app-subnet" = {
      address_prefixes  = ["10.2.2.0/24"]
      service_endpoints = ["Microsoft.Sql", "Microsoft.Storage", "Microsoft.AzureCosmosDB"]
    }
    "data-subnet" = {
      address_prefixes  = ["10.2.3.0/24"]
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
        "allow-http" = {
          priority                   = 110
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "80"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        }
      }
    }
    "app-nsg" = {
      security_rules = {
        "allow-https" = {
          priority               = 100
          direction              = "Inbound"
          access                 = "Allow"
          protocol               = "Tcp"
          source_port_range      = "*"
          destination_port_range = "443"
          # 🎓 STAGING: Source is "VirtualNetwork" only (dev allows "*" = anyone)
          # This is the progressive security — tighter rules as we approach production.
          source_address_prefix      = "VirtualNetwork"
          destination_address_prefix = "*"
        }
      }
    }
  }

  subnet_nsg_associations = {
    "aks-subnet" = "aks-nsg"
    "app-subnet" = "app-nsg"
  }

  # Feature toggle: NAT Gateway (disabled for staging)
  create_nat_gateway = var.enable_nat_gateway

  tags = module.global_standards.common_tags
}

# =============================================================================
# LOG ANALYTICS - Always created (longer retention than dev)
# =============================================================================
# 🎓 STAGING: 60 days retention (dev: 30 days, prod: 90 days)
#    Longer retention = more history for debugging, but costs more storage.
# =============================================================================
resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.project_name}-logs-staging"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days # 60 days for staging

  tags = module.global_standards.common_tags
}

# =============================================================================
# APPLICATION INSIGHTS - Enabled for staging (monitoring before prod)
# =============================================================================
resource "azurerm_application_insights" "main" {
  count = var.enable_application_insights ? 1 : 0

  name                = "${var.project_name}-insights-staging"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"

  tags = module.global_standards.common_tags
}

# =============================================================================
# KEY VAULT - With purge protection enabled (staging security hardening)
# =============================================================================
# 🎓 STAGING DIFFERENCE: purge_protection = true (dev = false)
#    This means: once a secret is deleted, it stays in "soft delete" for 90 days.
#    You CANNOT permanently delete it — protects against accidental secret loss.
# =============================================================================
module "security" {
  count  = var.enable_key_vault ? 1 : 0
  source = "../../modules/security"

  resource_group_name = azurerm_resource_group.main.name
  key_vault_name      = "${var.project_name}kvstaging" # Alphanumeric + hyphens, 3-24 chars
  location            = var.location
  tenant_id           = var.tenant_id

  # Feature toggles - Staging has purge protection
  purge_protection_enabled    = var.key_vault_purge_protection # true
  network_acls_default_action = var.network_acl_default_action # Deny

  tags = module.global_standards.common_tags
}

# =============================================================================
# AKS - Optional (controlled by feature toggle)
# =============================================================================
module "aks" {
  count  = var.enable_aks ? 1 : 0
  source = "../../modules/aks"

  resource_group_name = azurerm_resource_group.main.name
  cluster_name        = "${var.project_name}-aks-staging"
  location            = var.location
  dns_prefix          = "${var.project_name}-staging"

  # Networking
  vnet_subnet_id = module.networking.subnet_ids["aks-subnet"]

  # Scaling - Staging uses fixed medium size (no auto-scaling)
  node_count          = var.aks_node_count      # 2 nodes
  vm_size             = var.aks_node_size       # Standard_B2ms
  enable_auto_scaling = var.enable_auto_scaling # false

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
  environment_name    = "${var.project_name}-cae-staging"
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
  account_name        = "${var.project_name}cosmosstaging" # No hyphens
  location            = var.location

  # Feature toggles - Staging uses some prod-like settings for testing
  enable_automatic_failover       = false
  enable_multiple_write_locations = false
  public_network_access_enabled   = true # Still public for staging
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
  app_name            = "${var.project_name}-app-staging"
  location            = var.location

  # SKU - Staging uses standard tier
  sku_name = "S1" # Standard tier for staging

  tags = module.global_standards.common_tags
}
