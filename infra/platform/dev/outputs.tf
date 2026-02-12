# =============================================================================
# PLATFORM LAYER OUTPUTS - Dev Environment
# =============================================================================
# 🎓 WHO READS THESE?
#    App teams (Pattern 1 & Pattern 2) use data sources to read the VNets
#    and subnets created by this platform layer.
#
#    Pattern 1 (infra/envs/dev/): reads platform VNet via data source
#    Pattern 2 (examples/...):    reads team-specific VNets via data source
# =============================================================================

output "resource_group_name" {
  description = "Platform resource group name"
  value       = azurerm_resource_group.main.name
}

# Platform shared VNet
output "platform_vnet" {
  description = "Platform shared VNet information"
  value = {
    vnet_id    = module.networking.vnet_id
    vnet_name  = module.networking.vnet_name
    subnet_ids = module.networking.subnet_ids
  }
}

# Pattern 2: CRM team's VNet
output "crm_vnet" {
  description = "CRM team's VNet information (Pattern 2)"
  value = {
    vnet_id    = module.networking_crm.vnet_id
    vnet_name  = module.networking_crm.vnet_name
    subnet_ids = module.networking_crm.subnet_ids
  }
}

# Pattern 2: E-commerce team's VNet
output "ecommerce_vnet" {
  description = "E-commerce team's VNet information (Pattern 2)"
  value = {
    vnet_id    = module.networking_ecommerce.vnet_id
    vnet_name  = module.networking_ecommerce.vnet_name
    subnet_ids = module.networking_ecommerce.subnet_ids
  }
}

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID (app teams can send logs here)"
  value       = azurerm_log_analytics_workspace.main.id
}

output "log_analytics_workspace_name" {
  description = "Log Analytics workspace name"
  value       = azurerm_log_analytics_workspace.main.name
}
