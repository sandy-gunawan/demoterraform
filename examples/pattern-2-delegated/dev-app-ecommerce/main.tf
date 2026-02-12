# E-Commerce Application - Terraform Configuration
# =============================================================================
# 🎓 NEWBIE NOTE: Pattern 2 teams use the SAME terraform version, provider
# version, and backend storage as Platform team (Pattern 1).
# Only the backend "key" is different (separate state file per app).
#
# What's SAME as Pattern 1:
#   - Terraform version (>= 1.5.0)
#   - Provider version (~> 3.80)
#   - Backend storage account (stcontosotfstate001)
#   - Provider feature settings
#
# What's DIFFERENT from Pattern 1:
#   - Backend key (dev-app-ecommerce.tfstate vs dev.terraform.tfstate)
#   - No VNet creation (reads Platform's VNet via data sources)
#   - Own resource group, own apps
# =============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
  }

  # Remote state storage - SAME storage as Platform team!
  # 🎓 NEWBIE NOTE: Same storage account, different "key" (state file name)
  backend "azurerm" {
    resource_group_name  = "contoso-tfstate-rg"
    storage_account_name = "stcontosotfstate001"
    container_name       = "tfstate"
    key                  = "dev-app-ecommerce.tfstate" # Separate state per app!
    use_azuread_auth     = true
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
  }
}

# ============================================================================
# DATA SOURCES - Read Platform team's infrastructure
# ============================================================================
# 🎓 NEWBIE NOTE: We DON'T create the VNet here!
# The Platform team already created it in infra/envs/dev/main.tf (line 172)
# We just READ it using Terraform data sources below.
#
# Think of it like this:
# - Platform team: Builds the roads (VNet, subnets, security rules)
# - Your team: Builds the houses (AKS, CosmosDB, Key Vault)
# ============================================================================

data "azurerm_client_config" "current" {}

# Read E-commerce's dedicated VNet (created by Platform team in Pattern 1)
# This VNet was created by: infra/envs/dev/main.tf line 172 (module "networking_ecommerce")
data "azurerm_virtual_network" "ecommerce" {
  name                = "vnet-contoso-dev-ecommerce-001"
  resource_group_name = "contoso-platform-rg-dev"
}

# Read E-commerce's AKS subnet
data "azurerm_subnet" "ecom_aks" {
  name                 = "ecom-aks-subnet"
  virtual_network_name = data.azurerm_virtual_network.ecommerce.name
  resource_group_name  = data.azurerm_virtual_network.ecommerce.resource_group_name
}

# ============================================================================
# NAMING MODULE
# ============================================================================

module "naming" {
  source = "../../../infra/modules/_shared"

  project_name = "${var.company_name}-${var.workload}"
  environment  = var.environment
  location     = var.location
}

# ============================================================================
# RESOURCE GROUP
# ============================================================================

resource "azurerm_resource_group" "ecommerce" {
  name     = "rg-${var.company_name}-${var.environment}-${var.workload}-001"
  location = var.location

  tags = merge(var.default_tags, {
    Application = "E-commerce API"
    Team        = "E-commerce Team"
  })
}

# ============================================================================
# AKS - Shared cluster, dedicated namespace
# ============================================================================

# Reference existing AKS cluster (deployed by platform team or shared)
data "azurerm_kubernetes_cluster" "shared" {
  count = var.use_shared_aks ? 1 : 0

  name                = "aks-${var.company_name}-${var.environment}-001"
  resource_group_name = "rg-${var.company_name}-${var.environment}-aks-001"
}

# OR deploy dedicated AKS (if needed)
resource "azurerm_kubernetes_cluster" "dedicated" {
  count = var.use_shared_aks ? 0 : 1

  name                = "aks-${var.company_name}-${var.environment}-${var.workload}-001"
  location            = azurerm_resource_group.ecommerce.location
  resource_group_name = azurerm_resource_group.ecommerce.name
  dns_prefix          = "aks-${var.company_name}-${var.environment}-${var.workload}"

  kubernetes_version = var.kubernetes_version

  default_node_pool {
    name                = "default"
    node_count          = var.aks_node_count
    vm_size             = var.aks_vm_size
    vnet_subnet_id      = data.azurerm_subnet.ecom_aks.id
    enable_auto_scaling = true
    min_count           = 1
    max_count           = 5
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
    network_policy = "azure"
    service_cidr   = "10.2.0.0/16"
    dns_service_ip = "10.2.0.10"
  }

  tags = merge(var.default_tags, {
    Application = "E-commerce API"
  })
}

# ============================================================================
# COSMOS DB
# ============================================================================

resource "azurerm_cosmosdb_account" "ecommerce" {
  name                = "cosmos-${var.company_name}-${var.environment}-${var.workload}-001"
  location            = azurerm_resource_group.ecommerce.location
  resource_group_name = azurerm_resource_group.ecommerce.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  consistency_policy {
    consistency_level = var.cosmos_consistency_level
  }

  geo_location {
    location          = azurerm_resource_group.ecommerce.location
    failover_priority = 0
  }

  # Public access with IP rules (dev environment)
  public_network_access_enabled = true
  ip_range_filter               = var.cosmos_allowed_ips

  tags = merge(var.default_tags, {
    Application = "E-commerce API"
  })
}

# Cosmos DB - SQL Database
resource "azurerm_cosmosdb_sql_database" "ecommerce" {
  name                = "ecommerce-db"
  resource_group_name = azurerm_resource_group.ecommerce.name
  account_name        = azurerm_cosmosdb_account.ecommerce.name
}

# Container 1: Products
resource "azurerm_cosmosdb_sql_container" "products" {
  name                = "products"
  resource_group_name = azurerm_resource_group.ecommerce.name
  account_name        = azurerm_cosmosdb_account.ecommerce.name
  database_name       = azurerm_cosmosdb_sql_database.ecommerce.name
  partition_key_path  = "/categoryId"
  throughput          = var.cosmos_products_ru
}

# Container 2: Orders
resource "azurerm_cosmosdb_sql_container" "orders" {
  name                = "orders"
  resource_group_name = azurerm_resource_group.ecommerce.name
  account_name        = azurerm_cosmosdb_account.ecommerce.name
  database_name       = azurerm_cosmosdb_sql_database.ecommerce.name
  partition_key_path  = "/userId"
  throughput          = var.cosmos_orders_ru
}

# Container 3: Inventory
resource "azurerm_cosmosdb_sql_container" "inventory" {
  name                = "inventory"
  resource_group_name = azurerm_resource_group.ecommerce.name
  account_name        = azurerm_cosmosdb_account.ecommerce.name
  database_name       = azurerm_cosmosdb_sql_database.ecommerce.name
  partition_key_path  = "/warehouseId"
  throughput          = var.cosmos_inventory_ru
}

# ============================================================================
# KEY VAULT
# ============================================================================

resource "azurerm_key_vault" "ecommerce" {
  name                = "kv-${var.company_name}-${var.environment}-${var.workload}"
  location            = azurerm_resource_group.ecommerce.location
  resource_group_name = azurerm_resource_group.ecommerce.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  # Allow current user to manage secrets
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Purge"
    ]
  }

  tags = merge(var.default_tags, {
    Application = "E-commerce API"
  })
}

# Store Cosmos DB connection string in Key Vault
resource "azurerm_key_vault_secret" "cosmos_connection_string" {
  name         = "cosmos-connection-string"
  value        = azurerm_cosmosdb_account.ecommerce.primary_sql_connection_string
  key_vault_id = azurerm_key_vault.ecommerce.id
}

# ============================================================================
# MANAGED IDENTITY
# ============================================================================

resource "azurerm_user_assigned_identity" "ecommerce" {
  name                = "id-${var.company_name}-${var.environment}-${var.workload}-001"
  location            = azurerm_resource_group.ecommerce.location
  resource_group_name = azurerm_resource_group.ecommerce.name

  tags = merge(var.default_tags, {
    Application = "E-commerce API"
  })
}

# Grant Managed Identity access to Key Vault
resource "azurerm_key_vault_access_policy" "app_identity" {
  key_vault_id = azurerm_key_vault.ecommerce.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.ecommerce.principal_id

  secret_permissions = [
    "Get", "List"
  ]
}

# Grant Managed Identity access to Cosmos DB
resource "azurerm_cosmosdb_sql_role_assignment" "app_identity" {
  resource_group_name = azurerm_resource_group.ecommerce.name
  account_name        = azurerm_cosmosdb_account.ecommerce.name
  role_definition_id  = "${azurerm_cosmosdb_account.ecommerce.id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002"
  principal_id        = azurerm_user_assigned_identity.ecommerce.principal_id
  scope               = azurerm_cosmosdb_account.ecommerce.id
}
