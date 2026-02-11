# Azure Database for PostgreSQL Flexible Server Module
# =============================================================================
# This module creates a PostgreSQL Flexible Server in the provided resource group.
# Supports feature toggles for HA, backup, and private access.
# =============================================================================

resource "azurerm_postgresql_flexible_server" "pg" {
  name                          = var.server_name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  version                       = var.postgresql_version
  administrator_login           = var.administrator_login
  administrator_password        = var.administrator_password
  zone                          = var.availability_zone
  storage_mb                    = var.storage_mb
  sku_name                      = var.sku_name
  backup_retention_days         = var.backup_retention_days
  geo_redundant_backup_enabled  = var.geo_redundant_backup_enabled
  public_network_access_enabled = var.public_network_access_enabled

  # VNet integration (delegated subnet)
  delegated_subnet_id = var.delegated_subnet_id
  private_dns_zone_id = var.private_dns_zone_id

  # High availability
  dynamic "high_availability" {
    for_each = var.high_availability_mode != null ? [1] : []
    content {
      mode                      = var.high_availability_mode
      standby_availability_zone = var.standby_availability_zone
    }
  }

  # Authentication
  authentication {
    active_directory_auth_enabled = var.aad_auth_enabled
    password_auth_enabled         = var.password_auth_enabled
    tenant_id                     = var.aad_auth_enabled ? var.tenant_id : null
  }

  tags = var.tags
}

# PostgreSQL Databases
resource "azurerm_postgresql_flexible_server_database" "db" {
  for_each = var.databases

  name      = each.key
  server_id = azurerm_postgresql_flexible_server.pg.id
  collation = each.value.collation
  charset   = each.value.charset
}

# Server Configuration Parameters
resource "azurerm_postgresql_flexible_server_configuration" "config" {
  for_each = var.server_configurations

  name      = each.key
  server_id = azurerm_postgresql_flexible_server.pg.id
  value     = each.value
}

# Firewall Rules (only when public access is enabled)
resource "azurerm_postgresql_flexible_server_firewall_rule" "rules" {
  for_each = var.public_network_access_enabled ? var.firewall_rules : {}

  name             = each.key
  server_id        = azurerm_postgresql_flexible_server.pg.id
  start_ip_address = each.value.start_ip_address
  end_ip_address   = each.value.end_ip_address
}

# Diagnostic settings
resource "azurerm_monitor_diagnostic_setting" "pg_diagnostics" {
  count                      = var.log_analytics_workspace_id != null ? 1 : 0
  name                       = "${var.server_name}-diagnostics"
  target_resource_id         = azurerm_postgresql_flexible_server.pg.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "PostgreSQLLogs"
  }

  metric {
    category = "AllMetrics"
  }
}
