output "resource_group_name" {
  description = "WebApp resource group name"
  value       = azurerm_resource_group.webapp.name
}

output "resource_group_id" {
  description = "WebApp resource group ID"
  value       = azurerm_resource_group.webapp.id
}

output "app_service_plan_id" {
  description = "App Service Plan ID"
  value       = azurerm_service_plan.plan.id
}

output "app_service_plan_name" {
  description = "App Service Plan name"
  value       = azurerm_service_plan.plan.name
}

output "webapp_id" {
  description = "Web App resource ID"
  value       = var.os_type == "Linux" ? azurerm_linux_web_app.webapp[0].id : azurerm_windows_web_app.webapp[0].id
}

output "webapp_name" {
  description = "Web App name"
  value       = var.webapp_name
}

output "webapp_default_hostname" {
  description = "Default hostname (app.azurewebsites.net)"
  value       = var.os_type == "Linux" ? azurerm_linux_web_app.webapp[0].default_hostname : azurerm_windows_web_app.webapp[0].default_hostname
}

output "webapp_url" {
  description = "Web App URL (https://...)"
  value       = "https://${var.os_type == "Linux" ? azurerm_linux_web_app.webapp[0].default_hostname : azurerm_windows_web_app.webapp[0].default_hostname}"
}

output "webapp_identity_principal_id" {
  description = "Managed identity principal ID"
  value       = var.os_type == "Linux" ? azurerm_linux_web_app.webapp[0].identity[0].principal_id : azurerm_windows_web_app.webapp[0].identity[0].principal_id
}

output "webapp_identity_tenant_id" {
  description = "Managed identity tenant ID"
  value       = var.os_type == "Linux" ? azurerm_linux_web_app.webapp[0].identity[0].tenant_id : azurerm_windows_web_app.webapp[0].identity[0].tenant_id
}

output "webapp_outbound_ips" {
  description = "Outbound IP addresses"
  value       = var.os_type == "Linux" ? azurerm_linux_web_app.webapp[0].outbound_ip_addresses : azurerm_windows_web_app.webapp[0].outbound_ip_addresses
}

output "webapp_possible_outbound_ips" {
  description = "Possible outbound IP addresses (includes scale-up IPs)"
  value       = var.os_type == "Linux" ? azurerm_linux_web_app.webapp[0].possible_outbound_ip_addresses : azurerm_windows_web_app.webapp[0].possible_outbound_ip_addresses
}
