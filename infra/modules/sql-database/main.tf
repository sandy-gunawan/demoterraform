# Azure SQL Database Module
# =============================================================================
# This module creates Azure SQL Server and databases in the provided resource group.
# Supports feature toggles for firewall rules, private endpoints, and auditing.
# =============================================================================

resource "azurerm_mssql_server" "sql" {
  name                         = var.server_name
  location                     = var.location
  resource_group_name          = var.resource_group_name
  version                      = var.sql_version
  administrator_login          = var.administrator_login
  administrator_login_password = var.administrator_login_password
  minimum_tls_version          = var.minimum_tls_version

  public_network_access_enabled = var.public_network_access_enabled

  azuread_administrator {
    login_username = var.azuread_admin_login
    object_id      = var.azuread_admin_object_id
    tenant_id      = var.tenant_id
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# SQL Databases
resource "azurerm_mssql_database" "db" {
  for_each = var.databases

  name         = each.key
  server_id    = azurerm_mssql_server.sql.id
  collation    = each.value.collation
  license_type = each.value.license_type
  max_size_gb  = each.value.max_size_gb
  sku_name     = each.value.sku_name

  zone_redundant     = each.value.zone_redundant
  read_scale         = each.value.read_scale
  read_replica_count = each.value.read_replica_count

  tags = var.tags
}

# Firewall Rules
resource "azurerm_mssql_firewall_rule" "rules" {
  for_each = var.firewall_rules

  name             = each.key
  server_id        = azurerm_mssql_server.sql.id
  start_ip_address = each.value.start_ip_address
  end_ip_address   = each.value.end_ip_address
}

# Allow Azure Services
resource "azurerm_mssql_firewall_rule" "allow_azure" {
  count = var.allow_azure_services ? 1 : 0

  name             = "AllowAllWindowsAzureIps"
  server_id        = azurerm_mssql_server.sql.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Virtual Network Rules
resource "azurerm_mssql_virtual_network_rule" "vnet_rules" {
  for_each = var.virtual_network_rules

  name      = each.key
  server_id = azurerm_mssql_server.sql.id
  subnet_id = each.value
}

# Diagnostic settings
resource "azurerm_monitor_diagnostic_setting" "sql_diagnostics" {
  count                      = var.log_analytics_workspace_id != null ? 1 : 0
  name                       = "${var.server_name}-diagnostics"
  target_resource_id         = azurerm_mssql_server.sql.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "SQLSecurityAuditEvents"
  }

  metric {
    category = "AllMetrics"
  }
}

# Optional: Private endpoint
resource "azurerm_private_endpoint" "sql_endpoint" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = "${var.server_name}-endpoint"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.server_name}-connection"
    private_connection_resource_id = azurerm_mssql_server.sql.id
    is_manual_connection           = false
    subresource_names              = ["sqlServer"]
  }

  tags = var.tags
}
