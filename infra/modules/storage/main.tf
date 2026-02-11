# Azure Storage Account Module
# =============================================================================
# This module creates a Storage Account in the provided resource group.
# Supports feature toggles for network rules, private endpoints, and redundancy.
# =============================================================================

resource "azurerm_storage_account" "storage" {
  name                            = var.storage_account_name
  location                        = var.location
  resource_group_name             = var.resource_group_name
  account_tier                    = var.account_tier
  account_replication_type        = var.account_replication_type
  account_kind                    = var.account_kind
  min_tls_version                 = var.min_tls_version
  allow_nested_items_to_be_public = var.allow_blob_public_access
  enable_https_traffic_only       = true

  # Network rules
  dynamic "network_rules" {
    for_each = var.network_rules_default_action != null ? [1] : []
    content {
      default_action             = var.network_rules_default_action
      bypass                     = var.network_rules_bypass
      ip_rules                   = var.network_rules_ip_rules
      virtual_network_subnet_ids = var.network_rules_subnet_ids
    }
  }

  # Blob properties
  blob_properties {
    versioning_enabled       = var.blob_versioning_enabled
    change_feed_enabled      = var.blob_change_feed_enabled
    last_access_time_enabled = var.blob_last_access_time_enabled

    dynamic "delete_retention_policy" {
      for_each = var.blob_delete_retention_days != null ? [1] : []
      content {
        days = var.blob_delete_retention_days
      }
    }

    dynamic "container_delete_retention_policy" {
      for_each = var.container_delete_retention_days != null ? [1] : []
      content {
        days = var.container_delete_retention_days
      }
    }
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# Storage Containers
resource "azurerm_storage_container" "containers" {
  for_each = var.containers

  name                  = each.key
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = each.value.access_type
}

# Diagnostic settings
resource "azurerm_monitor_diagnostic_setting" "storage_diagnostics" {
  count                      = var.log_analytics_workspace_id != null ? 1 : 0
  name                       = "${var.storage_account_name}-diagnostics"
  target_resource_id         = azurerm_storage_account.storage.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  metric {
    category = "Transaction"
  }
}

# Optional: Private endpoint
resource "azurerm_private_endpoint" "storage_endpoint" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = "${var.storage_account_name}-endpoint"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.storage_account_name}-connection"
    private_connection_resource_id = azurerm_storage_account.storage.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  tags = var.tags
}
