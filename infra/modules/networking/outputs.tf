output "vnet_id" {
  description = "Virtual network ID"
  value       = azurerm_virtual_network.vnet.id
}

output "vnet_name" {
  description = "Virtual network name"
  value       = azurerm_virtual_network.vnet.name
}

output "subnet_ids" {
  description = "Map of subnet names to IDs"
  value       = { for k, v in azurerm_subnet.subnets : k => v.id }
}

output "nsg_ids" {
  description = "Map of NSG names to IDs"
  value       = { for k, v in azurerm_network_security_group.nsg : k => v.id }
}

output "nat_gateway_id" {
  description = "NAT Gateway ID (if created)"
  value       = var.create_nat_gateway ? azurerm_nat_gateway.nat[0].id : null
}

output "resource_group_name" {
  description = "Resource group name (pass-through for convenience)"
  value       = var.resource_group_name
}
