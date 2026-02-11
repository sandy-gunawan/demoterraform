output "storage_account_id" {
  description = "Storage account ID"
  value       = azurerm_storage_account.storage.id
}

output "storage_account_name" {
  description = "Storage account name"
  value       = azurerm_storage_account.storage.name
}

output "primary_blob_endpoint" {
  description = "Primary blob endpoint"
  value       = azurerm_storage_account.storage.primary_blob_endpoint
}

output "primary_access_key" {
  description = "Primary access key"
  value       = azurerm_storage_account.storage.primary_access_key
  sensitive   = true
}

output "primary_connection_string" {
  description = "Primary connection string"
  value       = azurerm_storage_account.storage.primary_connection_string
  sensitive   = true
}

output "resource_group_name" {
  description = "Resource group name"
  value       = var.resource_group_name
}

output "principal_id" {
  description = "System assigned identity principal ID"
  value       = azurerm_storage_account.storage.identity[0].principal_id
}
