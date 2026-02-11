output "resource_group_name" {
  description = "Resource group name"
  value       = azurerm_resource_group.main.name
}

output "vnet_id" {
  description = "Virtual network ID"
  value       = module.networking.vnet_id
}

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID"
  value       = azurerm_log_analytics_workspace.main.id
}

output "deployment_info" {
  description = "Deployment information"
  value = {
    environment       = "Development"
    resource_group    = azurerm_resource_group.main.name
    location          = var.location
    vnet_name         = module.networking.vnet_name
    log_analytics     = azurerm_log_analytics_workspace.main.name
  }
}
