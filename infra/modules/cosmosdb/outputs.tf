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

output "cosmosdb_primary_sql_connection_string" {
  description = "Cosmos DB primary SQL connection string"
  value       = azurerm_cosmosdb_account.db.primary_sql_connection_string
  sensitive   = true
}

output "cosmosdb_secondary_sql_connection_string" {
  description = "Cosmos DB secondary SQL connection string"
  value       = azurerm_cosmosdb_account.db.secondary_sql_connection_string
  sensitive   = true
}

output "cosmosdb_primary_readonly_sql_connection_string" {
  description = "Cosmos DB primary readonly SQL connection string"
  value       = azurerm_cosmosdb_account.db.primary_readonly_sql_connection_string
  sensitive   = true
}

output "cosmosdb_secondary_readonly_sql_connection_string" {
  description = "Cosmos DB secondary readonly SQL connection string"
  value       = azurerm_cosmosdb_account.db.secondary_readonly_sql_connection_string
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
  value       = var.resource_group_name
}
