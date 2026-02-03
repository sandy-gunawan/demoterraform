# Landing Zone Module
# 
# This module creates the foundational infrastructure that ALL applications share.
# It orchestrates: Resource Group, Virtual Network, Subnets, NSGs, and Log Analytics.
#
# Deploy this ONCE, then all application teams connect to it.

#------------------------------------------------------------------------------
# Resource Group - Container for all Landing Zone resources
#------------------------------------------------------------------------------
resource "azurerm_resource_group" "landing_zone" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

#------------------------------------------------------------------------------
# Virtual Network - Shared network for all applications
#------------------------------------------------------------------------------
resource "azurerm_virtual_network" "main" {
  name                = var.vnet_name
  location            = azurerm_resource_group.landing_zone.location
  resource_group_name = azurerm_resource_group.landing_zone.name
  address_space       = var.address_space
  dns_servers         = var.dns_servers

  tags = var.tags
}

#------------------------------------------------------------------------------
# Subnets - Separate segments for different workload types
#------------------------------------------------------------------------------
resource "azurerm_subnet" "subnets" {
  for_each = var.subnets

  name                 = each.key
  resource_group_name  = azurerm_resource_group.landing_zone.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = each.value.address_prefixes
  service_endpoints    = lookup(each.value, "service_endpoints", [])

  # Delegation for specific Azure services (e.g., Container Apps, App Service)
  dynamic "delegation" {
    for_each = lookup(each.value, "delegation", null) != null ? [each.value.delegation] : []
    content {
      name = delegation.value.name
      service_delegation {
        name    = delegation.value.service_name
        actions = lookup(delegation.value, "actions", [])
      }
    }
  }
}

#------------------------------------------------------------------------------
# Network Security Groups - Firewall rules per subnet
#------------------------------------------------------------------------------
resource "azurerm_network_security_group" "nsgs" {
  for_each = var.network_security_groups

  name                = each.key
  location            = azurerm_resource_group.landing_zone.location
  resource_group_name = azurerm_resource_group.landing_zone.name

  tags = var.tags
}

resource "azurerm_network_security_rule" "rules" {
  for_each = merge([
    for nsg_key, nsg in var.network_security_groups : {
      for rule_key, rule in lookup(nsg, "security_rules", {}) :
      "${nsg_key}-${rule_key}" => merge(rule, { nsg_name = nsg_key })
    }
  ]...)

  name                        = each.key
  priority                    = each.value.priority
  direction                   = each.value.direction
  access                      = each.value.access
  protocol                    = each.value.protocol
  source_port_range           = lookup(each.value, "source_port_range", "*")
  destination_port_range      = lookup(each.value, "destination_port_range", "*")
  source_address_prefix       = lookup(each.value, "source_address_prefix", "*")
  destination_address_prefix  = lookup(each.value, "destination_address_prefix", "*")
  resource_group_name         = azurerm_resource_group.landing_zone.name
  network_security_group_name = azurerm_network_security_group.nsgs[each.value.nsg_name].name
}

resource "azurerm_subnet_network_security_group_association" "associations" {
  for_each = var.subnet_nsg_associations

  subnet_id                 = azurerm_subnet.subnets[each.key].id
  network_security_group_id = azurerm_network_security_group.nsgs[each.value].id
}

#------------------------------------------------------------------------------
# Log Analytics Workspace - Centralized logging for ALL applications
#------------------------------------------------------------------------------
resource "azurerm_log_analytics_workspace" "main" {
  name                = var.log_analytics_name
  location            = azurerm_resource_group.landing_zone.location
  resource_group_name = azurerm_resource_group.landing_zone.name
  sku                 = var.log_analytics_sku
  retention_in_days   = var.log_analytics_retention_days

  tags = var.tags
}

#------------------------------------------------------------------------------
# Application Insights (Optional) - For application performance monitoring
#------------------------------------------------------------------------------
resource "azurerm_application_insights" "main" {
  count = var.create_application_insights ? 1 : 0

  name                = var.application_insights_name
  location            = azurerm_resource_group.landing_zone.location
  resource_group_name = azurerm_resource_group.landing_zone.name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"

  tags = var.tags
}

#------------------------------------------------------------------------------
# NAT Gateway (Optional) - For outbound internet access from private subnets
#------------------------------------------------------------------------------
resource "azurerm_public_ip" "nat" {
  count = var.create_nat_gateway ? 1 : 0

  name                = "${var.vnet_name}-nat-pip"
  location            = azurerm_resource_group.landing_zone.location
  resource_group_name = azurerm_resource_group.landing_zone.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = var.tags
}

resource "azurerm_nat_gateway" "main" {
  count = var.create_nat_gateway ? 1 : 0

  name                    = "${var.vnet_name}-nat"
  location                = azurerm_resource_group.landing_zone.location
  resource_group_name     = azurerm_resource_group.landing_zone.name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10

  tags = var.tags
}

resource "azurerm_nat_gateway_public_ip_association" "main" {
  count = var.create_nat_gateway ? 1 : 0

  nat_gateway_id       = azurerm_nat_gateway.main[0].id
  public_ip_address_id = azurerm_public_ip.nat[0].id
}

resource "azurerm_subnet_nat_gateway_association" "main" {
  for_each = var.create_nat_gateway ? var.nat_gateway_subnet_associations : {}

  subnet_id      = azurerm_subnet.subnets[each.value].id
  nat_gateway_id = azurerm_nat_gateway.main[0].id
}
