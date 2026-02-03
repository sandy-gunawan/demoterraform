output "cosmosdb_id" {
  description = "Cosmos DB account ID"
  value       = azurerm_cosmosdb_account.db.id
}

output "cosmosdb_endpoint" {
  description = "Cosmos DB account endpoint"
  value       = azurerm_cosmosdb_account.db.endpoint
}

output "cosmosdb_primary_key" {
  description = "Cosmos DB primary key"
  value       = azurerm_cosmosdb_account.db.primary_key
  sensitive   = true
}

output "cosmosdb_connection_strings" {
  description = "Cosmos DB connection strings"
  value       = azurerm_cosmosdb_account.db.connection_strings
  sensitive   = true
}

output "database_names" {
  description = "Created database names"
  value       = [for db in azurerm_cosmosdb_sql_database.db : db.name]
}

output "container_names" {
  description = "Created container names"
  value       = [for container in azurerm_cosmosdb_sql_container.container : container.name]
}

output "resource_group_name" {
  description = "Resource group name"
  value       = azurerm_resource_group.cosmosdb.name
}
