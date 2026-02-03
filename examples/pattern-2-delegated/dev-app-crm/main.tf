# CRM Application - Terraform Configuration

terraform {
  required_version = ">= 1.6.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
  }
  
  # Remote state storage
  backend "azurerm" {
    resource_group_name  = "rg-contoso-dev-tfstate-001"
    storage_account_name = "stcontosodevtfstate001"
    container_name       = "tfstate"
    key                  = "dev-app-crm.tfstate"  # Separate state per app
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
  }
}

# ============================================================================
# DATA SOURCES
# ============================================================================

data "azurerm_client_config" "current" {}

# Reference VNet from landing zone
data "azurerm_virtual_network" "landing_zone" {
  name                = "vnet-contoso-dev-001"
  resource_group_name = "rg-contoso-dev-network-001"
}

# Reference App Service subnet
data "azurerm_subnet" "app_service" {
  name                 = "snet-contoso-dev-app-001"
  virtual_network_name = data.azurerm_virtual_network.landing_zone.name
  resource_group_name  = data.azurerm_virtual_network.landing_zone.resource_group_name
}

# ============================================================================
# NAMING MODULE
# ============================================================================

module "naming" {
  source = "../../../_shared/naming"
  
  company_name = var.company_name
  environment  = var.environment
  workload     = var.workload
}

# ============================================================================
# RESOURCE GROUP
# ============================================================================

resource "azurerm_resource_group" "crm" {
  name     = "rg-${var.company_name}-${var.environment}-${var.workload}-001"
  location = var.location
  
  tags = merge(var.default_tags, {
    Application = "CRM System"
    Team        = "CRM Team"
  })
}

# ============================================================================
# APP SERVICE
# ============================================================================

# App Service Plan
resource "azurerm_service_plan" "crm" {
  name                = "asp-${var.company_name}-${var.environment}-${var.workload}-001"
  location            = azurerm_resource_group.crm.location
  resource_group_name = azurerm_resource_group.crm.name
  os_type             = "Linux"
  sku_name            = var.app_service_sku
  
  tags = merge(var.default_tags, {
    Application = "CRM System"
  })
}

# App Service (Web App)
resource "azurerm_linux_web_app" "crm" {
  name                = "app-${var.company_name}-${var.environment}-${var.workload}-001"
  location            = azurerm_resource_group.crm.location
  resource_group_name = azurerm_resource_group.crm.name
  service_plan_id     = azurerm_service_plan.crm.id
  
  site_config {
    always_on = true
    
    application_stack {
      node_version = "18-lts"
    }
  }
  
  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.crm.id
    ]
  }
  
  app_settings = {
    "COSMOS_ENDPOINT"       = azurerm_cosmosdb_account.crm.endpoint
    "COSMOS_DATABASE"       = azurerm_cosmosdb_sql_database.crm.name
    "KEY_VAULT_NAME"        = azurerm_key_vault.crm.name
    "AZURE_CLIENT_ID"       = azurerm_user_assigned_identity.crm.client_id
    "WEBSITES_PORT"         = "3000"
  }
  
  tags = merge(var.default_tags, {
    Application = "CRM System"
  })
}

# ============================================================================
# COSMOS DB
# ============================================================================

resource "azurerm_cosmosdb_account" "crm" {
  name                = "cosmos-${var.company_name}-${var.environment}-${var.workload}-001"
  location            = azurerm_resource_group.crm.location
  resource_group_name = azurerm_resource_group.crm.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"
  
  consistency_policy {
    consistency_level = var.cosmos_consistency_level
  }
  
  geo_location {
    location          = azurerm_resource_group.crm.location
    failover_priority = 0
  }
  
  # Public access with IP rules (dev environment)
  public_network_access_enabled = true
  ip_range_filter              = var.cosmos_allowed_ips
  
  tags = merge(var.default_tags, {
    Application = "CRM System"
  })
}

# Cosmos DB - SQL Database
resource "azurerm_cosmosdb_sql_database" "crm" {
  name                = "crm-db"
  resource_group_name = azurerm_resource_group.crm.name
  account_name        = azurerm_cosmosdb_account.crm.name
}

# Container 1: Customers
resource "azurerm_cosmosdb_sql_container" "customers" {
  name                = "customers"
  resource_group_name = azurerm_resource_group.crm.name
  account_name        = azurerm_cosmosdb_account.crm.name
  database_name       = azurerm_cosmosdb_sql_database.crm.name
  partition_key_path  = "/companyId"
  throughput          = var.cosmos_customers_ru
}

# Container 2: Interactions
resource "azurerm_cosmosdb_sql_container" "interactions" {
  name                = "interactions"
  resource_group_name = azurerm_resource_group.crm.name
  account_name        = azurerm_cosmosdb_account.crm.name
  database_name       = azurerm_cosmosdb_sql_database.crm.name
  partition_key_path  = "/customerId"
  throughput          = var.cosmos_interactions_ru
}

# ============================================================================
# KEY VAULT
# ============================================================================

resource "azurerm_key_vault" "crm" {
  name                = "kv-${var.company_name}-${var.environment}-${var.workload}"
  location            = azurerm_resource_group.crm.location
  resource_group_name = azurerm_resource_group.crm.name
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
    Application = "CRM System"
  })
}

# Store Cosmos DB connection string in Key Vault
resource "azurerm_key_vault_secret" "cosmos_connection_string" {
  name         = "cosmos-connection-string"
  value        = azurerm_cosmosdb_account.crm.primary_sql_connection_string
  key_vault_id = azurerm_key_vault.crm.id
}

# ============================================================================
# MANAGED IDENTITY
# ============================================================================

resource "azurerm_user_assigned_identity" "crm" {
  name                = "id-${var.company_name}-${var.environment}-${var.workload}-001"
  location            = azurerm_resource_group.crm.location
  resource_group_name = azurerm_resource_group.crm.name
  
  tags = merge(var.default_tags, {
    Application = "CRM System"
  })
}

# Grant Managed Identity access to Key Vault
resource "azurerm_key_vault_access_policy" "app_identity" {
  key_vault_id = azurerm_key_vault.crm.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.crm.principal_id
  
  secret_permissions = [
    "Get", "List"
  ]
}

# Grant Managed Identity access to Cosmos DB
resource "azurerm_cosmosdb_sql_role_assignment" "app_identity" {
  resource_group_name = azurerm_resource_group.crm.name
  account_name        = azurerm_cosmosdb_account.crm.name
  role_definition_id  = "${azurerm_cosmosdb_account.crm.id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002"
  principal_id        = azurerm_user_assigned_identity.crm.principal_id
  scope               = azurerm_cosmosdb_account.crm.id
}
