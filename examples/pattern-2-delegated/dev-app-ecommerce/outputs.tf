# ============================================================================
# OUTPUTS - E-Commerce Application
# ============================================================================

output "resource_group_name" {
  description = "Resource group name"
  value       = azurerm_resource_group.ecommerce.name
}

output "aks_cluster_name" {
  description = "AKS cluster name (if dedicated)"
  value       = var.use_shared_aks ? "Using shared cluster: aks-${var.company_name}-${var.environment}-001" : azurerm_kubernetes_cluster.dedicated[0].name
}

output "cosmos_endpoint" {
  description = "Cosmos DB endpoint"
  value       = azurerm_cosmosdb_account.ecommerce.endpoint
}

output "cosmos_database_name" {
  description = "Cosmos DB database name"
  value       = azurerm_cosmosdb_sql_database.ecommerce.name
}

output "cosmos_containers" {
  description = "Cosmos DB containers"
  value = {
    products = {
      name          = azurerm_cosmosdb_sql_container.products.name
      partition_key = azurerm_cosmosdb_sql_container.products.partition_key_path
    }
    orders = {
      name          = azurerm_cosmosdb_sql_container.orders.name
      partition_key = azurerm_cosmosdb_sql_container.orders.partition_key_path
    }
    inventory = {
      name          = azurerm_cosmosdb_sql_container.inventory.name
      partition_key = azurerm_cosmosdb_sql_container.inventory.partition_key_path
    }
  }
}

output "key_vault_name" {
  description = "Key Vault name"
  value       = azurerm_key_vault.ecommerce.name
}

output "managed_identity_client_id" {
  description = "Managed Identity client ID (use in your app)"
  value       = azurerm_user_assigned_identity.ecommerce.client_id
}

output "managed_identity_principal_id" {
  description = "Managed Identity principal ID"
  value       = azurerm_user_assigned_identity.ecommerce.principal_id
}

# ============================================================================
# CONNECTION INFORMATION (for app deployment)
# ============================================================================

output "app_deployment_info" {
  description = "Information needed to deploy your application"
  value = {
    namespace              = "ecommerce"
    managed_identity_id    = azurerm_user_assigned_identity.ecommerce.id
    key_vault_name         = azurerm_key_vault.ecommerce.name
    cosmos_endpoint        = azurerm_cosmosdb_account.ecommerce.endpoint
    cosmos_database        = azurerm_cosmosdb_sql_database.ecommerce.name
  }
  sensitive = false
}
