output "server_id" {
  description = "PostgreSQL Flexible Server ID"
  value       = azurerm_postgresql_flexible_server.pg.id
}

output "server_name" {
  description = "PostgreSQL Flexible Server name"
  value       = azurerm_postgresql_flexible_server.pg.name
}

output "server_fqdn" {
  description = "PostgreSQL Flexible Server FQDN"
  value       = azurerm_postgresql_flexible_server.pg.fqdn
}

output "database_ids" {
  description = "Map of database names to IDs"
  value       = { for k, v in azurerm_postgresql_flexible_server_database.db : k => v.id }
}

output "resource_group_name" {
  description = "Resource group name"
  value       = var.resource_group_name
}
