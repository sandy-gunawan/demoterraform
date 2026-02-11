output "server_id" {
  description = "SQL Server ID"
  value       = azurerm_mssql_server.sql.id
}

output "server_name" {
  description = "SQL Server name"
  value       = azurerm_mssql_server.sql.name
}

output "server_fqdn" {
  description = "SQL Server fully qualified domain name"
  value       = azurerm_mssql_server.sql.fully_qualified_domain_name
}

output "database_ids" {
  description = "Map of database names to IDs"
  value       = { for k, v in azurerm_mssql_database.db : k => v.id }
}

output "resource_group_name" {
  description = "Resource group name"
  value       = var.resource_group_name
}

output "principal_id" {
  description = "System assigned identity principal ID"
  value       = azurerm_mssql_server.sql.identity[0].principal_id
}
