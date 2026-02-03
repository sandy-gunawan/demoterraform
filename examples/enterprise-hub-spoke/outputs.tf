output "hub_resource_group" {
  description = "Hub resource group name"
  value       = azurerm_resource_group.hub.name
}

output "hub_vnet_id" {
  description = "Hub virtual network ID"
  value       = module.hub_network.vnet_id
}

output "spoke_vnet_ids" {
  description = "Spoke virtual network IDs"
  value       = { for k, v in module.spoke_networks : k => v.vnet_id }
}

output "shared_key_vault_name" {
  description = "Shared Key Vault name"
  value       = azurerm_key_vault.shared.name
}

output "shared_container_registry" {
  description = "Shared Container Registry name"
  value       = azurerm_container_registry.shared.name
}

output "shared_cosmosdb_endpoint" {
  description = "Shared Cosmos DB endpoint"
  value       = module.shared_cosmosdb.cosmosdb_endpoint
}

output "log_analytics_workspace_id" {
  description = "Centralized Log Analytics workspace ID"
  value       = azurerm_log_analytics_workspace.hub.id
}

output "deployment_summary" {
  description = "Landing Zone deployment summary"
  value = <<-EOT
    ========================================
    Azure Landing Zone Deployment Complete
    ========================================
    
    Organization: ${var.organization_name}
    Primary Region: ${var.location}
    Secondary Region: ${var.secondary_location}
    
    Hub Network:
    - VNet: ${module.hub_network.vnet_name}
    - Address Space: ${var.hub_address_space}
    
    Spoke Networks:
    %{for spoke_key, spoke in var.spoke_networks~}
    - ${spoke_key}: ${spoke.address_space} (${spoke.environment})
    %{endfor~}
    
    Shared Services:
    - Log Analytics: ${azurerm_log_analytics_workspace.hub.name}
    - Key Vault: ${azurerm_key_vault.shared.name}
    - Container Registry: ${azurerm_container_registry.shared.name}
    - Cosmos DB: ${module.shared_cosmosdb.cosmosdb_endpoint}
    
    Network Topology:
    - ${length(var.spoke_networks)} spoke networks connected to hub
    - All spokes peered with hub network
    - Centralized logging enabled
    
    Next Steps:
    1. Deploy applications to spoke networks
    2. Configure Azure Firewall rules (if needed)
    3. Set up VPN/ExpressRoute gateway (if needed)
    4. Configure Azure Bastion for VM access
    5. Implement additional Azure Policies
    6. Set up cost alerts and budgets
    
    Framework Reusability:
    - Use the AKS example to deploy to any spoke
    - Add new spokes by updating spoke_networks variable
    - All spokes use the same module structure
    - Consistent governance across all environments
    
    Estimated Monthly Cost: ~$2,700 (hub) + $500-5,000 per spoke
    ========================================
  EOT
}
