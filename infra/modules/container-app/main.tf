# Container App Module
# =============================================================================
# This module creates Container Apps in the provided resource group.
# Simplified for environment-based configuration.
# =============================================================================

resource "azurerm_container_app_environment" "env" {
  name                       = var.environment_name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  log_analytics_workspace_id = var.log_analytics_workspace_id
  infrastructure_subnet_id   = var.infrastructure_subnet_id

  tags = var.tags
}

# Note: Container apps are created separately when you deploy your application
# This module just creates the environment (the "home" for your apps)
