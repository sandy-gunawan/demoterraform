output "resource_group_name" {
  description = "Resource group for multi-team app layer"
  value       = azurerm_resource_group.main.name
}

output "deployed_services" {
  description = "What got deployed in this run"
  value = {
    ecommerce_aks      = var.enable_ecommerce_aks
    ecommerce_cosmosdb = var.enable_ecommerce_cosmosdb
    crm_aks            = var.enable_crm_aks
    crm_cosmosdb       = var.enable_crm_cosmosdb
  }
}

output "aks_names" {
  description = "AKS names if created"
  value = {
    ecommerce = try(module.aks_ecommerce[0].cluster_name, null)
    crm       = try(module.aks_crm[0].cluster_name, null)
  }
}

output "cosmosdb_names" {
  description = "CosmosDB account names if created"
  value = {
    ecommerce = try(module.cosmosdb_ecommerce[0].account_name, null)
    crm       = try(module.cosmosdb_crm[0].account_name, null)
  }
}
