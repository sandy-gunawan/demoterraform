# Application Layer - Production Environment (Pattern 1)
# =============================================================================
# PHILOSOPHY: Maximum security, high availability, compliance-ready
# - All app-level features enabled
# - Auto-scaling, geo-redundancy, continuous backup
#
# 🎓 LAYERED INFRASTRUCTURE:
#    Layer 1: infra/platform/prod/  → VNets, Security, Log Analytics (DEPLOY FIRST!)
#    Layer 2: infra/envs/prod/      → THIS FILE: Applications only
#
# 🎓 DEPLOY ORDER:
#    Step 1: cd infra/platform/prod && terraform apply -var-file="prod.tfvars"
#    Step 2: cd infra/envs/prod && terraform apply -var-file="prod.tfvars"
#
# 🎓 HOW PROD DIFFERS FROM DEV AND STAGING:
#    ┌────────────────────────────┬─────────┬───────────┬─────────────┐
#    │ Feature                     │ Dev     │ Staging   │ Prod          │
#    ├────────────────────────────┼─────────┼───────────┼─────────────┤
#    │ AKS Auto-scaling            │ OFF     │ OFF       │ ON (3→10)     │
#    │ Cosmos DB Failover          │ OFF     │ OFF       │ ON            │
#    │ Continuous Backup           │ OFF     │ OFF       │ ON            │
#    │ App Insights                │ OFF     │ ON        │ ON            │
#    └────────────────────────────┴─────────┴───────────┴─────────────┘
#    (NAT Gateway, DDoS, Private Endpoints, NSGs are now in Platform layer)
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
# RESOURCE GROUP - Application layer's own resource group
# =============================================================================
resource "azurerm_resource_group" "main" {
  name     = "${var.project_name}-apps-rg-prod"
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
# DATA SOURCES - Read Platform layer's infrastructure
# =============================================================================
# 🎓 VNets, NSGs, NAT Gateway, DDoS, Key Vault, Log Analytics are ALL in
#    infra/platform/prod/main.tf (Platform layer). We READ them here.
#
# ⚠️  PREREQUISITE: Platform layer MUST be deployed FIRST!
#    Run: cd infra/platform/prod && terraform apply -var-file="prod.tfvars"
# =============================================================================

data "azurerm_virtual_network" "platform" {
  name                = "${var.project_name}-vnet-prod"
  resource_group_name = "${var.project_name}-platform-rg-prod"
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
  name                = "${var.project_name}-logs-prod"
  resource_group_name = "${var.project_name}-platform-rg-prod"
}

# =============================================================================
# APPLICATION INSIGHTS - ENABLED for production monitoring
# =============================================================================
resource "azurerm_application_insights" "main" {
  count = var.enable_application_insights ? 1 : 0

  name                = "${var.project_name}-insights-prod"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  workspace_id        = data.azurerm_log_analytics_workspace.platform.id
  application_type    = "web"

  tags = module.global_standards.common_tags
}

# =============================================================================
# AKS - With auto-scaling (3→10 nodes based on load)
# =============================================================================
# 🎓 PROD DIFFERENCES:
#    - Auto-scaling ON: cluster grows/shrinks based on CPU/memory demand
#    - 3 minimum nodes: high availability (survives 1 node failure)
#    - Standard_D4s_v3: larger VMs (4 vCPU, 16GB) for production workloads
# =============================================================================
module "aks" {
  count  = var.enable_aks ? 1 : 0
  source = "../../modules/aks"

  resource_group_name = azurerm_resource_group.main.name
  cluster_name        = "${var.project_name}-aks-prod"
  location            = var.location
  dns_prefix          = "${var.project_name}-prod"

  # Networking — reads from Platform layer's subnet (via data source)
  vnet_subnet_id = data.azurerm_subnet.aks.id

  # Scaling - Production has auto-scaling
  node_count          = var.aks_node_count
  max_node_count      = var.aks_max_node_count
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
  environment_name    = "${var.project_name}-cae-prod"
  location            = var.location

  # Networking — reads from Platform layer's app-subnet (via data source)
  infrastructure_subnet_id = data.azurerm_subnet.app.id

  # Monitoring — reads from Platform layer's Log Analytics (via data source)
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.platform.id

  tags = module.global_standards.common_tags
}

# =============================================================================
# COSMOS DB - With geo-redundancy, auto-failover, continuous backup
# =============================================================================
# 🎓 PROD DIFFERENCES:
#    - Auto-failover: if primary region is down, automatically switch to secondary
#    - Multi-region writes: data can be written from multiple regions (if geo enabled)
#    - Private access only: no public internet access (uses private endpoint)
#    - Continuous backup: point-in-time restore (vs periodic snapshots in dev)
# =============================================================================
module "cosmosdb" {
  count  = var.enable_cosmosdb ? 1 : 0
  source = "../../modules/cosmosdb"

  resource_group_name = azurerm_resource_group.main.name
  account_name        = "${var.project_name}cosmosprod" # No hyphens
  location            = var.location

  # Feature toggles — Production has ALL reliability features
  enable_automatic_failover       = true
  enable_multiple_write_locations = var.enable_geo_redundancy
  public_network_access_enabled   = true
  backup_type                     = var.enable_continuous_backup ? "Continuous" : "Periodic"

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
