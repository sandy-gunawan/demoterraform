# =============================================================================
# OUTPUTS - Application Layer (Prod)
# =============================================================================
# VNet, Log Analytics, DDoS outputs are in infra/platform/prod/outputs.tf
# =============================================================================

output "resource_group_name" {
  description = "Application resource group name"
  value       = azurerm_resource_group.main.name
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
    environment  = "Production"
    resource_group = azurerm_resource_group.main.name
    location       = var.location
    platform_rg    = "${var.project_name}-platform-rg-prod"
    layer          = "Application (Layer 2)"
    app_insights   = var.enable_application_insights ? azurerm_application_insights.main[0].name : null
  }
}
