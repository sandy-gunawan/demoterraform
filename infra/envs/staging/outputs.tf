output "resource_group_name" {
  description = "Resource group name"
  value       = azurerm_resource_group.staging.name
}

output "vnet_id" {
  description = "Virtual network ID"
  value       = module.networking.vnet_id
}

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID"
  value       = azurerm_log_analytics_workspace.staging.id
}

output "deployment_info" {
  description = "Deployment information"
  value = {
    environment       = "Staging"
    resource_group    = azurerm_resource_group.staging.name
    location          = var.location
    vnet_name         = module.networking.vnet_name
    vnet_address_space = "10.2.0.0/16"
    log_analytics     = azurerm_log_analytics_workspace.staging.name
    retention_days    = 60
  }
}
