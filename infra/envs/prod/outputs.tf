output "resource_group_name" {
  description = "Resource group name"
  value       = azurerm_resource_group.prod.name
}

output "vnet_id" {
  description = "Virtual network ID"
  value       = module.networking.vnet_id
}

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID"
  value       = azurerm_log_analytics_workspace.prod.id
}

output "application_insights_id" {
  description = "Application Insights ID"
  value       = azurerm_application_insights.prod.id
}

output "application_insights_instrumentation_key" {
  description = "Application Insights instrumentation key"
  value       = azurerm_application_insights.prod.instrumentation_key
  sensitive   = true
}

output "deployment_info" {
  description = "Deployment information"
  value = {
    environment        = "Production"
    resource_group     = azurerm_resource_group.prod.name
    location           = var.location
    vnet_name          = module.networking.vnet_name
    vnet_address_space = "10.3.0.0/16"
    log_analytics      = azurerm_log_analytics_workspace.prod.name
    retention_days     = 90
    app_insights       = azurerm_application_insights.prod.name
    nat_gateway        = "Enabled"
  }
}
