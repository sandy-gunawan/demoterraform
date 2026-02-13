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

# This is a separate experimental Pattern 1 root module for multi-team onboarding.
# Existing infra/envs/dev remains unchanged.
resource "azurerm_resource_group" "main" {
  name     = "contoso-apps-multi-rg-${var.environment}"
  location = var.location
  tags     = module.global_standards.common_tags
}

module "global_standards" {
  source = "../../global"

  organization_name = var.organization_name
  project_name      = var.project_name
  environment       = var.environment
  location          = var.location
  cost_center       = var.cost_center
  owner_email       = var.owner_email
  repository_url    = var.repository_url
}

# Read shared platform resources created in infra/platform/dev
data "azurerm_virtual_network" "platform" {
  name                = "vnet-${var.project_name}-${var.environment}-001"
  resource_group_name = "contoso-platform-rg-${var.environment}"
}

data "azurerm_subnet" "aks" {
  name                 = "aks-subnet"
  virtual_network_name = data.azurerm_virtual_network.platform.name
  resource_group_name  = data.azurerm_virtual_network.platform.resource_group_name
}

data "azurerm_log_analytics_workspace" "platform" {
  name                = "${var.project_name}-logs-${var.environment}"
  resource_group_name = "contoso-platform-rg-${var.environment}"
}

# ---------------------------
# Team A: Ecommerce
# ---------------------------
module "aks_ecommerce" {
  count  = var.enable_ecommerce_aks ? 1 : 0
  source = "../../modules/aks"

  resource_group_name = azurerm_resource_group.main.name
  cluster_name        = "${var.project_name}-ecommerce-aks-${var.environment}"
  location            = var.location
  dns_prefix          = "${var.project_name}-ecommerce-${var.environment}"
  vnet_subnet_id      = data.azurerm_subnet.aks.id

  node_count          = var.aks_node_count
  vm_size             = var.aks_node_size
  enable_auto_scaling = var.enable_auto_scaling

  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.platform.id

  tags = merge(module.global_standards.common_tags, {
    Team        = "Ecommerce"
    Application = "ecommerce"
  })
}

module "cosmosdb_ecommerce" {
  count  = var.enable_ecommerce_cosmosdb ? 1 : 0
  source = "../../modules/cosmosdb"

  resource_group_name = azurerm_resource_group.main.name
  account_name        = "${var.project_name}ecommercecosmos${var.environment}"
  location            = var.location

  enable_automatic_failover       = false
  enable_multiple_write_locations = false
  public_network_access_enabled   = true
  backup_type                     = "Periodic"
  backup_storage_redundancy       = var.cosmosdb_backup_storage_redundancy

  tags = merge(module.global_standards.common_tags, {
    Team        = "Ecommerce"
    Application = "ecommerce"
  })
}

# ---------------------------
# Team B: CRM
# ---------------------------
module "aks_crm" {
  count  = var.enable_crm_aks ? 1 : 0
  source = "../../modules/aks"

  resource_group_name = azurerm_resource_group.main.name
  cluster_name        = "${var.project_name}-crm-aks-${var.environment}"
  location            = var.location
  dns_prefix          = "${var.project_name}-crm-${var.environment}"
  vnet_subnet_id      = data.azurerm_subnet.aks.id

  node_count          = var.aks_node_count
  vm_size             = var.aks_node_size
  enable_auto_scaling = var.enable_auto_scaling

  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.platform.id

  tags = merge(module.global_standards.common_tags, {
    Team        = "CRM"
    Application = "crm"
  })
}

module "cosmosdb_crm" {
  count  = var.enable_crm_cosmosdb ? 1 : 0
  source = "../../modules/cosmosdb"

  resource_group_name = azurerm_resource_group.main.name
  account_name        = "${var.project_name}crmcosmos${var.environment}"
  location            = var.location

  enable_automatic_failover       = false
  enable_multiple_write_locations = false
  public_network_access_enabled   = true
  backup_type                     = "Periodic"
  backup_storage_redundancy       = var.cosmosdb_backup_storage_redundancy

  tags = merge(module.global_standards.common_tags, {
    Team        = "CRM"
    Application = "crm"
  })
}
