output "resource_group_name" {
  description = "Resource group name"
  value       = azurerm_resource_group.app.name
}

output "aks_cluster_name" {
  description = "AKS cluster name"
  value       = module.aks.cluster_name
}

output "aks_cluster_id" {
  description = "AKS cluster ID"
  value       = module.aks.cluster_id
}

output "cosmosdb_endpoint" {
  description = "Cosmos DB endpoint"
  value       = module.cosmosdb.cosmosdb_endpoint
}

output "cosmosdb_account_name" {
  description = "Cosmos DB account name"
  value       = replace(module.cosmosdb.cosmosdb_endpoint, "https://", "")
}

output "key_vault_name" {
  description = "Key Vault name"
  value       = azurerm_key_vault.app.name
}

output "vnet_name" {
  description = "Virtual network name"
  value       = module.networking.vnet_name
}

output "vnet_id" {
  description = "Virtual network ID"
  value       = module.networking.vnet_id
}

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID"
  value       = azurerm_log_analytics_workspace.app.id
}

output "get_credentials_command" {
  description = "Command to get AKS credentials"
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.app.name} --name ${module.aks.cluster_name}"
}

output "deployment_summary" {
  description = "Deployment summary"
  value = <<-EOT
    ========================================
    AKS Application Deployment Complete
    ========================================
    
    Resource Group: ${azurerm_resource_group.app.name}
    Location: ${var.location}
    
    AKS Cluster: ${module.aks.cluster_name}
    - Get credentials: az aks get-credentials --resource-group ${azurerm_resource_group.app.name} --name ${module.aks.cluster_name}
    
    Cosmos DB: ${module.cosmosdb.cosmosdb_endpoint}
    - Connection string stored in Key Vault: ${azurerm_key_vault.app.name}
    
    Key Vault: ${azurerm_key_vault.app.name}
    
    Virtual Network: ${module.networking.vnet_name}
    
    Next Steps:
    1. Configure kubectl: Run the 'Get credentials' command above
    2. Verify cluster: kubectl get nodes
    3. Deploy application: kubectl apply -f kubernetes/
    4. View logs: kubectl logs -f deployment/myapp -n myapp
    
    Estimated Monthly Cost: ~$2,175 USD
    (Actual cost depends on usage and scaling)
    ========================================
  EOT
}
