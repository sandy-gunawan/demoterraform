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
    environment    = "Development"
    resource_group = azurerm_resource_group.main.name
    location       = var.location
    vnet_name      = module.networking.vnet_name
    log_analytics  = azurerm_log_analytics_workspace.main.name
  }
}

# =============================================================================
# PATTERN 2 NETWORKING OUTPUTS
# =============================================================================
# These outputs help Pattern 2 teams know what VNets Platform created for them
# Teams use data sources to read these (see examples/pattern-2-delegated/)
# =============================================================================

output "pattern2_crm_vnet" {
  description = "CRM team's VNet information (Pattern 2)"
  value = {
    vnet_id    = module.networking_crm.vnet_id
    vnet_name  = module.networking_crm.vnet_name
    subnet_ids = module.networking_crm.subnet_ids
  }
}

output "pattern2_ecommerce_vnet" {
  description = "E-commerce team's VNet information (Pattern 2)"
  value = {
    vnet_id    = module.networking_ecommerce.vnet_id
    vnet_name  = module.networking_ecommerce.vnet_name
    subnet_ids = module.networking_ecommerce.subnet_ids
  }
}
