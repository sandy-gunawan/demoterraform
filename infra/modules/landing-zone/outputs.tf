#------------------------------------------------------------------------------
# Resource Group Outputs
#------------------------------------------------------------------------------

output "resource_group_name" {
  description = "Name of the Landing Zone resource group"
  value       = azurerm_resource_group.landing_zone.name
}

output "resource_group_id" {
  description = "ID of the Landing Zone resource group"
  value       = azurerm_resource_group.landing_zone.id
}

output "resource_group_location" {
  description = "Location of the Landing Zone resource group"
  value       = azurerm_resource_group.landing_zone.location
}

#------------------------------------------------------------------------------
# Virtual Network Outputs
#------------------------------------------------------------------------------

output "vnet_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.main.name
}

output "vnet_address_space" {
  description = "Address space of the virtual network"
  value       = azurerm_virtual_network.main.address_space
}

#------------------------------------------------------------------------------
# Subnet Outputs
#------------------------------------------------------------------------------

output "subnet_ids" {
  description = "Map of subnet names to IDs"
  value = {
    for subnet_name, subnet in azurerm_subnet.subnets :
    subnet_name => subnet.id
  }
}

output "subnet_address_prefixes" {
  description = "Map of subnet names to address prefixes"
  value = {
    for subnet_name, subnet in azurerm_subnet.subnets :
    subnet_name => subnet.address_prefixes
  }
}

#------------------------------------------------------------------------------
# Network Security Group Outputs
#------------------------------------------------------------------------------

output "nsg_ids" {
  description = "Map of NSG names to IDs"
  value = {
    for nsg_name, nsg in azurerm_network_security_group.nsgs :
    nsg_name => nsg.id
  }
}

#------------------------------------------------------------------------------
# Log Analytics Outputs
#------------------------------------------------------------------------------

output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.id
}

output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.name
}

output "log_analytics_workspace_primary_key" {
  description = "Primary shared key for the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.primary_shared_key
  sensitive   = true
}

output "log_analytics_workspace_workspace_id" {
  description = "Workspace ID (GUID) of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.workspace_id
}

#------------------------------------------------------------------------------
# Application Insights Outputs
#------------------------------------------------------------------------------

output "application_insights_id" {
  description = "ID of the Application Insights resource"
  value       = var.create_application_insights ? azurerm_application_insights.main[0].id : null
}

output "application_insights_instrumentation_key" {
  description = "Instrumentation key for Application Insights"
  value       = var.create_application_insights ? azurerm_application_insights.main[0].instrumentation_key : null
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "Connection string for Application Insights"
  value       = var.create_application_insights ? azurerm_application_insights.main[0].connection_string : null
  sensitive   = true
}

#------------------------------------------------------------------------------
# NAT Gateway Outputs
#------------------------------------------------------------------------------

output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = var.create_nat_gateway ? azurerm_nat_gateway.main[0].id : null
}

output "nat_gateway_public_ip" {
  description = "Public IP address of the NAT Gateway"
  value       = var.create_nat_gateway ? azurerm_public_ip.nat[0].ip_address : null
}
