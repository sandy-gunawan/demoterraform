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

output "application_insights_id" {
  description = "Application Insights ID"
  value       = var.enable_application_insights ? azurerm_application_insights.main[0].id : null
}

output "application_insights_instrumentation_key" {
  description = "Application Insights instrumentation key"
  value       = var.enable_application_insights ? azurerm_application_insights.main[0].instrumentation_key : null
  sensitive   = true
}

output "deployment_info" {
  description = "Deployment information"
  value = {
    environment        = "Production"
    resource_group     = azurerm_resource_group.main.name
    location           = var.location
    vnet_name          = module.networking.vnet_name
    vnet_address_space = "10.3.0.0/16"
    log_analytics      = azurerm_log_analytics_workspace.main.name
    retention_days     = 90
    app_insights       = var.enable_application_insights ? azurerm_application_insights.main[0].name : null
    nat_gateway        = "Enabled"
  }
}
