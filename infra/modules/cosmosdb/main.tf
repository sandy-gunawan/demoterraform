# Azure Cosmos DB Module
# =============================================================================
# This module creates Cosmos DB in the provided resource group.
# Supports feature toggles for backup, failover, and private endpoints.
# =============================================================================

resource "azurerm_cosmosdb_account" "db" {
  name                = var.account_name
  location            = var.location
  resource_group_name = var.resource_group_name
  offer_type          = "Standard"
  kind                = var.kind

  consistency_policy {
    consistency_level       = var.consistency_level
    max_interval_in_seconds = var.consistency_level == "BoundedStaleness" ? var.max_interval_in_seconds : null
    max_staleness_prefix    = var.consistency_level == "BoundedStaleness" ? var.max_staleness_prefix : null
  }

  geo_location {
    location          = var.location
    failover_priority = 0
  }

  dynamic "geo_location" {
    for_each = var.failover_locations
    content {
      location          = geo_location.value.location
      failover_priority = geo_location.value.failover_priority
    }
  }

  # Security features
  public_network_access_enabled     = var.public_network_access_enabled
  is_virtual_network_filter_enabled = var.enable_virtual_network_filter
  
  dynamic "virtual_network_rule" {
    for_each = var.virtual_network_rules
    content {
      id = virtual_network_rule.value
    }
  }

  # Backup configuration
  backup {
    type                = var.backup_type
    interval_in_minutes = var.backup_type == "Periodic" ? var.backup_interval_in_minutes : null
    retention_in_hours  = var.backup_type == "Periodic" ? var.backup_retention_in_hours : null
    storage_redundancy  = var.backup_storage_redundancy
  }

  # Enable automatic failover
  enable_automatic_failover = var.enable_automatic_failover

  # Enable multiple write locations for production
  enable_multiple_write_locations = var.enable_multiple_write_locations

  # Advanced threat protection
  local_authentication_disabled = var.local_authentication_disabled

  tags = var.tags
}

# Cosmos DB SQL Database
resource "azurerm_cosmosdb_sql_database" "db" {
  for_each            = var.sql_databases
  name                = each.key
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.db.name
  
  # Autoscale or manual throughput
  dynamic "autoscale_settings" {
    for_each = each.value.autoscale_max_throughput != null ? [1] : []
    content {
      max_throughput = each.value.autoscale_max_throughput
    }
  }

  throughput = each.value.autoscale_max_throughput == null ? each.value.throughput : null
}

# Cosmos DB SQL Container
resource "azurerm_cosmosdb_sql_container" "container" {
  for_each              = var.sql_containers
  name                  = each.key
  resource_group_name   = var.resource_group_name
  account_name          = azurerm_cosmosdb_account.db.name
  database_name         = azurerm_cosmosdb_sql_database.db[each.value.database_name].name
  partition_key_paths   = each.value.partition_key_paths
  partition_key_version = each.value.partition_key_version

  # Autoscale or manual throughput at container level
  dynamic "autoscale_settings" {
    for_each = each.value.autoscale_max_throughput != null ? [1] : []
    content {
      max_throughput = each.value.autoscale_max_throughput
    }
  }

  throughput = each.value.autoscale_max_throughput == null ? each.value.throughput : null

  # Indexing policy
  indexing_policy {
    indexing_mode = each.value.indexing_mode

    dynamic "included_path" {
      for_each = each.value.included_paths
      content {
        path = included_path.value
      }
    }

    dynamic "excluded_path" {
      for_each = each.value.excluded_paths
      content {
        path = excluded_path.value
      }
    }
  }

  # Note: Hierarchical partition keys are supported by providing multiple values
  # in partition_key_paths with partition_key_version = 2. No additional block needed.

  # Default TTL
  default_ttl = each.value.default_ttl

  # Analytical storage for HTAP scenarios
  analytical_storage_ttl = each.value.analytical_storage_ttl
}

# Diagnostic settings for monitoring
resource "azurerm_monitor_diagnostic_setting" "cosmosdb" {
  count                      = var.log_analytics_workspace_id != null ? 1 : 0
  name                       = "${var.account_name}-diagnostics"
  target_resource_id         = azurerm_cosmosdb_account.db.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "DataPlaneRequests"
  }

  enabled_log {
    category = "QueryRuntimeStatistics"
  }

  enabled_log {
    category = "PartitionKeyStatistics"
  }

  metric {
    category = "Requests"
    enabled  = true
  }
}

# Optional: Private endpoint for VNet integration
resource "azurerm_private_endpoint" "cosmosdb_endpoint" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = "${var.account_name}-endpoint"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.account_name}-connection"
    private_connection_resource_id = azurerm_cosmosdb_account.db.id
    is_manual_connection           = false
    subresource_names              = ["Sql"]
  }

  tags = var.tags
}

# Private DNS Zone for Cosmos DB private endpoint
resource "azurerm_private_dns_zone" "cosmosdb" {
  count               = var.enable_private_endpoint && var.vnet_id != null ? 1 : 0
  name                = "privatelink.documents.azure.com"
  resource_group_name = var.resource_group_name

  tags = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "cosmosdb" {
  count                 = var.enable_private_endpoint && var.vnet_id != null ? 1 : 0
  name                  = "${var.account_name}-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.cosmosdb[0].name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false

  tags = var.tags
}

resource "azurerm_private_dns_a_record" "cosmosdb" {
  count               = var.enable_private_endpoint && var.vnet_id != null ? 1 : 0
  name                = var.account_name
  zone_name           = azurerm_private_dns_zone.cosmosdb[0].name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.cosmosdb_endpoint[0].private_service_connection[0].private_ip_address]
}
