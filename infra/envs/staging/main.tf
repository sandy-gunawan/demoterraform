# Application Layer - Staging Environment (Pattern 1)
# =============================================================================
# PHILOSOPHY: Test before production
# - Add monitoring and basic hardening
# - Still cost-conscious, no expensive features
#
# 🎓 LAYERED INFRASTRUCTURE:
#    Layer 1: infra/platform/staging/ → VNets, Security, Log Analytics (DEPLOY FIRST!)
#    Layer 2: infra/envs/staging/     → THIS FILE: Applications only
#
# 🎓 DEPLOY ORDER:
#    Step 1: cd infra/platform/staging && terraform apply -var-file="staging.tfvars"
#    Step 2: cd infra/envs/staging && terraform apply -var-file="staging.tfvars"
#
# 🎓 HOW STAGING DIFFERS FROM DEV (progressive security):
#    ┌────────────────────────────┬───────────┬────────────┐
#    │ Feature                     │ Dev        │ Staging      │
#    ├────────────────────────────┼───────────┼────────────┤
#    │ App Insights (monitoring)    │ OFF        │ ON           │
#    │ AKS nodes                   │ 1          │ 2            │
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
# RESOURCE GROUP - Application layer's own resource group
# =============================================================================
resource "azurerm_resource_group" "main" {
  name     = "${var.project_name}-apps-rg-staging"
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
# DATA SOURCES - Read Platform layer's infrastructure
# =============================================================================
# 🎓 NEWBIE NOTE: VNets and Log Analytics are in infra/platform/staging/
#    We READ them using data sources (read-only, no modification).
#
# ⚠️  PREREQUISITE: Platform layer MUST be deployed FIRST!
#    Run: cd infra/platform/staging && terraform apply -var-file="staging.tfvars"
# =============================================================================

data "azurerm_virtual_network" "platform" {
  name                = "${var.project_name}-vnet-staging"
  resource_group_name = "${var.project_name}-platform-rg-staging"
}

data "azurerm_subnet" "aks" {
  name                 = "aks-subnet"
  virtual_network_name = data.azurerm_virtual_network.platform.name
  resource_group_name  = data.azurerm_virtual_network.platform.resource_group_name
}

data "azurerm_subnet" "app" {
  name                 = "app-subnet"
  virtual_network_name = data.azurerm_virtual_network.platform.name
  resource_group_name  = data.azurerm_virtual_network.platform.resource_group_name
}

data "azurerm_log_analytics_workspace" "platform" {
  name                = "${var.project_name}-logs-staging"
  resource_group_name = "${var.project_name}-platform-rg-staging"
}

# =============================================================================
# APPLICATION INSIGHTS - Enabled for staging (monitoring before prod)
# =============================================================================
resource "azurerm_application_insights" "main" {
  count = var.enable_application_insights ? 1 : 0

  name                = "${var.project_name}-insights-staging"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  workspace_id        = data.azurerm_log_analytics_workspace.platform.id
  application_type    = "web"

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

  # Networking — reads from Platform layer's subnet (via data source)
  vnet_subnet_id = data.azurerm_subnet.aks.id

  # Scaling - Staging uses fixed medium size
  node_count          = var.aks_node_count
  vm_size             = var.aks_node_size
  enable_auto_scaling = var.enable_auto_scaling

  # Monitoring — reads from Platform layer's Log Analytics (via data source)
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.platform.id

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

  # Networking — reads from Platform layer's app-subnet (via data source)
  infrastructure_subnet_id = data.azurerm_subnet.app.id

  # Monitoring — reads from Platform layer's Log Analytics (via data source)
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.platform.id

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
