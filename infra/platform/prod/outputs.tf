output "resource_group_name" {
  description = "Platform resource group name"
  value       = azurerm_resource_group.main.name
}

output "platform_vnet" {
  description = "Platform shared VNet information"
  value = {
    vnet_id    = module.networking.vnet_id
    vnet_name  = module.networking.vnet_name
    subnet_ids = module.networking.subnet_ids
  }
}

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID"
  value       = azurerm_log_analytics_workspace.main.id
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
    retention_days     = var.log_retention_days
    nat_gateway        = var.enable_nat_gateway ? "Enabled" : "Disabled"
    ddos_protection    = var.enable_ddos_protection ? "Enabled" : "Disabled"
  }
}
