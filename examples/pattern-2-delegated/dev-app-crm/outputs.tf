# ============================================================================
# OUTPUTS - CRM Application
# ============================================================================
# 🎓 THESE VALUES are printed after "terraform apply" and can be used by:
#    1. Developers: to find endpoints, names, URLs for their app
#    2. CI/CD: to capture values for deployment scripts
#    3. Other Terraform configs: via terraform_remote_state data source
# ============================================================================

output "resource_group_name" {
  description = "Resource group name"
  value       = azurerm_resource_group.crm.name
}

output "app_service_url" {
  description = "App Service URL"
  value       = "https://${azurerm_linux_web_app.crm.default_hostname}"
}

output "app_service_name" {
  description = "App Service name"
  value       = azurerm_linux_web_app.crm.name
}

output "cosmos_endpoint" {
  description = "Cosmos DB endpoint"
  value       = azurerm_cosmosdb_account.crm.endpoint
}

output "cosmos_database_name" {
  description = "Cosmos DB database name"
  value       = azurerm_cosmosdb_sql_database.crm.name
}

output "cosmos_containers" {
  description = "Cosmos DB containers"
  value = {
    customers = {
      name          = azurerm_cosmosdb_sql_container.customers.name
      partition_key = azurerm_cosmosdb_sql_container.customers.partition_key_path
    }
    interactions = {
      name          = azurerm_cosmosdb_sql_container.interactions.name
      partition_key = azurerm_cosmosdb_sql_container.interactions.partition_key_path
    }
  }
}

output "key_vault_name" {
  description = "Key Vault name"
  value       = azurerm_key_vault.crm.name
}

output "managed_identity_client_id" {
  description = "Managed Identity client ID (use in your app)"
  value       = azurerm_user_assigned_identity.crm.client_id
}

# ============================================================================
# NETWORKING REFERENCE (Read from Platform team)
# ============================================================================
# 🎓 These outputs confirm which Platform VNet/subnet we're using.
#    Useful for verifying the data sources resolved correctly.
# ============================================================================

output "vnet_name_used" {
  description = "VNet name (created by Platform team)"
  value       = data.azurerm_virtual_network.crm.name
}

output "subnet_id_used" {
  description = "Subnet ID used for App Service"
  value       = data.azurerm_subnet.crm_app.id
}

# ============================================================================
# DEPLOYMENT COMMAND (for convenience)
# ============================================================================

output "deployment_command" {
  description = "Command to deploy your app to App Service"
  value       = "az webapp deployment source config-zip --resource-group ${azurerm_resource_group.crm.name} --name ${azurerm_linux_web_app.crm.name} --src app.zip"
}
