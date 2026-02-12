# =============================================================================
# OUTPUTS - Application Layer (Dev)
# =============================================================================
# 🎓 These outputs are for the APPLICATION layer only.
#    VNet and Log Analytics outputs are in infra/platform/dev/outputs.tf
# =============================================================================

output "resource_group_name" {
  description = "Application resource group name"
  value       = azurerm_resource_group.main.name
}

output "deployment_info" {
  description = "Deployment information"
  value = {
    environment    = "Development"
    resource_group = azurerm_resource_group.main.name
    location       = var.location
    platform_rg    = "contoso-platform-rg-${var.environment}"
    layer          = "Application (Layer 2)"
  }
}
