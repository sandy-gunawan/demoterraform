# Networking Module
# =============================================================================
# 🎓 WHAT IS THIS MODULE? Creates VNet + Subnets + NSGs + optional NAT Gateway.
#    This module is the FOUNDATION — all other modules need networking first.
#
# 🎓 WHY A MODULE? Reusability! This same module is used 3 times in dev/main.tf:
#    1. module "networking"           → Platform's VNet  (10.1.0.0/16)
#    2. module "networking_crm"       → CRM team's VNet  (10.2.0.0/16)
#    3. module "networking_ecommerce" → E-com team's VNet (10.3.0.0/16)
#
# 🎓 IMPORTANT: This module does NOT create its own resource group.
#    The calling environment (dev/staging/prod) creates the RG and passes it in.
#    This is a design pattern called "resource group injection".
# =============================================================================

# 🎓 VIRTUAL NETWORK: Your private network in Azure.
#    All subnets, NSGs, and connected resources live inside this VNet.
resource "azurerm_virtual_network" "vnet" {
  name                = var.network_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space

  tags = var.tags
}

# 🎓 SUBNETS: Created using for_each = var.subnets (a map).
#    for_each creates one subnet PER entry in the map.
#    each.key = subnet name (e.g., "aks-subnet")
#    each.value = config (address_prefixes, service_endpoints, delegation)
resource "azurerm_subnet" "subnets" {
  for_each             = var.subnets
  name                 = each.key
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = each.value.address_prefixes
  service_endpoints    = each.value.service_endpoints

  # 🎓 DELEGATION: Some Azure services need exclusive use of a subnet.
  #    Example: Container Apps needs delegation to "Microsoft.App/environments".
  #    This "dynamic" block creates the delegation only if specified.
  dynamic "delegation" {
    for_each = each.value.delegation != null ? [each.value.delegation] : []
    content {
      name = delegation.value.name
      service_delegation {
        name    = delegation.value.service_name
        actions = delegation.value.actions
      }
    }
  }
}

# 🎓 NSG (Network Security Group): Firewall rules for subnets.
#    Created using for_each = var.network_security_groups.
resource "azurerm_network_security_group" "nsg" {
  for_each            = var.network_security_groups
  name                = each.key
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# 🎓 SECURITY RULES: Individual firewall rules inside each NSG.
#    Uses a merge + for expression to flatten NSG→rules into a single map.
#    Example: {"aks-nsg-allow-https": {priority: 100, ...}, ...}
resource "azurerm_network_security_rule" "rules" {
  for_each = merge([
    for nsg_key, nsg in var.network_security_groups : {
      for rule_key, rule in nsg.security_rules :
      "${nsg_key}-${rule_key}" => merge(rule, { nsg_name = nsg_key })
    }
  ]...)

  name                        = each.key
  priority                    = each.value.priority
  direction                   = each.value.direction
  access                      = each.value.access
  protocol                    = each.value.protocol
  source_port_range           = each.value.source_port_range
  destination_port_range      = each.value.destination_port_range
  source_address_prefix       = each.value.source_address_prefix
  destination_address_prefix  = each.value.destination_address_prefix
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg[each.value.nsg_name].name
}

# 🎓 NSG → SUBNET ASSOCIATION: Attach an NSG to a specific subnet.
#    Without this, the NSG rules have no effect!
resource "azurerm_subnet_network_security_group_association" "nsg_association" {
  for_each                  = var.subnet_nsg_associations
  subnet_id                 = azurerm_subnet.subnets[each.key].id
  network_security_group_id = azurerm_network_security_group.nsg[each.value].id
}

# 🎓 NAT GATEWAY: Gives ALL outbound traffic a single fixed public IP.
#    WHY? External services can whitelist this one IP instead of many.
#    count = 0 (dev), count = 1 (prod)
resource "azurerm_nat_gateway" "nat" {
  count               = var.create_nat_gateway ? 1 : 0
  name                = "${var.network_name}-nat"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "Standard"

  tags = var.tags
}

resource "azurerm_public_ip" "nat_ip" {
  count               = var.create_nat_gateway ? 1 : 0
  name                = "${var.network_name}-nat-ip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = var.tags
}

resource "azurerm_nat_gateway_public_ip_association" "nat_ip_assoc" {
  count                = var.create_nat_gateway ? 1 : 0
  nat_gateway_id       = azurerm_nat_gateway.nat[0].id
  public_ip_address_id = azurerm_public_ip.nat_ip[0].id
}
