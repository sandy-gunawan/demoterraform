# Security Module - Azure Key Vault
# =============================================================================
# This module creates Key Vault in the provided resource group.
# Supports feature toggles for purge protection and private endpoints.
# =============================================================================

resource "azurerm_key_vault" "kv" {
  name                = var.key_vault_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = var.tenant_id
  sku_name            = var.sku_name

  enabled_for_deployment          = var.enabled_for_deployment
  enabled_for_disk_encryption     = var.enabled_for_disk_encryption
  enabled_for_template_deployment = var.enabled_for_template_deployment
  enable_rbac_authorization       = var.enable_rbac_authorization
  purge_protection_enabled        = var.purge_protection_enabled
  soft_delete_retention_days      = var.soft_delete_retention_days

  # Network rules
  network_acls {
    bypass                     = var.network_acls_bypass
    default_action             = var.network_acls_default_action
    ip_rules                   = var.network_acls_ip_rules
    virtual_network_subnet_ids = var.virtual_network_subnet_ids
  }

  tags = var.tags
}

# Diagnostic settings - send Key Vault logs to Log Analytics
resource "azurerm_monitor_diagnostic_setting" "kv_diagnostics" {
  count                      = var.log_analytics_workspace_id != null ? 1 : 0
  name                       = "${var.key_vault_name}-diagnostics"
  target_resource_id         = azurerm_key_vault.kv.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "AuditEvent"
  }

  enabled_log {
    category = "AzurePolicyEvaluationDetails"
  }

  metric {
    category = "AllMetrics"
  }
}

# Optional: Create secrets
resource "azurerm_key_vault_secret" "secrets" {
  for_each     = var.secrets
  name         = each.key
  value        = each.value.value
  key_vault_id = azurerm_key_vault.kv.id
  content_type = try(each.value.content_type, null)

  depends_on = [
    azurerm_key_vault.kv
  ]
}

# Optional: Private endpoint for VNet integration
resource "azurerm_private_endpoint" "kv_endpoint" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = "${var.key_vault_name}-endpoint"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.key_vault_name}-connection"
    private_connection_resource_id = azurerm_key_vault.kv.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  tags = var.tags
}

# Private DNS Zone for private endpoint
resource "azurerm_private_dns_zone" "kv_dns" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.resource_group_name

  tags = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "kv_dns_link" {
  count                 = var.enable_private_endpoint && var.vnet_id != null ? 1 : 0
  name                  = "${var.key_vault_name}-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.kv_dns[0].name
  virtual_network_id    = var.vnet_id

  tags = var.tags
}

resource "azurerm_private_dns_a_record" "kv_dns_a" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = azurerm_key_vault.kv.name
  zone_name           = azurerm_private_dns_zone.kv_dns[0].name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.kv_endpoint[0].private_service_connection[0].private_ip_address]

  tags = var.tags
}
