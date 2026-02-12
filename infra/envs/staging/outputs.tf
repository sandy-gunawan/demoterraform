# =============================================================================
# OUTPUTS - Application Layer (Staging)
# =============================================================================
# VNet and Log Analytics outputs are in infra/platform/staging/outputs.tf
# =============================================================================

output "resource_group_name" {
  description = "Application resource group name"
  value       = azurerm_resource_group.main.name
}

output "deployment_info" {
  description = "Deployment information"
  value = {
    environment = "Staging"
    resource_group = azurerm_resource_group.main.name
    location       = var.location
    platform_rg    = "${var.project_name}-platform-rg-staging"
    layer          = "Application (Layer 2)"
  }
}
