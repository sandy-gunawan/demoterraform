output "resource_group_name" {
  description = "Security resource group name"
  value       = azurerm_resource_group.security.name
}

output "resource_group_id" {
  description = "Security resource group ID"
  value       = azurerm_resource_group.security.id
}

output "key_vault_id" {
  description = "Key Vault resource ID"
  value       = azurerm_key_vault.kv.id
}

output "key_vault_name" {
  description = "Key Vault name"
  value       = azurerm_key_vault.kv.name
}

output "key_vault_uri" {
  description = "Key Vault URI (https://kv-name.vault.azure.net/)"
  value       = azurerm_key_vault.kv.vault_uri
}

output "key_vault_tenant_id" {
  description = "Key Vault tenant ID"
  value       = azurerm_key_vault.kv.tenant_id
}

output "secret_ids" {
  description = "Map of secret names to secret IDs"
  value       = { for k, v in azurerm_key_vault_secret.secrets : k => v.id }
}

output "private_endpoint_id" {
  description = "Private endpoint ID (if created)"
  value       = try(azurerm_private_endpoint.kv_endpoint[0].id, null)
}

output "private_endpoint_ip" {
  description = "Private endpoint IP address (if created)"
  value       = try(azurerm_private_endpoint.kv_endpoint[0].private_service_connection[0].private_ip_address, null)
}
