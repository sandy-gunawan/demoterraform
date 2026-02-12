# WebApp Module - Azure App Service
# =============================================================================
# 🎓 WHAT IS THIS MODULE? Creates App Service Plan + Web App.
#    App Service is Azure's managed web hosting (like Heroku or Vercel).
#    You deploy code or Docker containers, Azure handles the rest.
#
# 🎓 TWO RESOURCES NEEDED:
#    1. Service Plan = the "machine" (CPU, RAM, pricing tier)
#    2. Web App = your application running ON that machine
#
# 🎓 SUPPORTS:
#    - Linux or Windows hosting
#    - Docker, .NET, Java, Node.js, Python, PHP, Ruby, Go
#    - VNet integration, IP restrictions, custom domains
#    - Health checks, deployment slots, auto-scaling
# =============================================================================

resource "azurerm_service_plan" "plan" {
  name                = "${var.app_name}-plan"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = var.os_type
  sku_name            = var.sku_name

  tags = var.tags
}

# 🎓 LINUX WEB APP: Created only when os_type = "Linux" (count pattern).
#    Linux is cheaper than Windows for the same SKU tier.
resource "azurerm_linux_web_app" "webapp" {
  count               = var.os_type == "Linux" ? 1 : 0
  name                = var.app_name
  location            = var.location
  resource_group_name = var.resource_group_name
  service_plan_id     = azurerm_service_plan.plan.id

  https_only                    = var.https_only
  client_affinity_enabled       = var.client_affinity_enabled
  virtual_network_subnet_id     = var.virtual_network_subnet_id
  public_network_access_enabled = var.public_network_access_enabled

  site_config {
    always_on                         = var.always_on
    http2_enabled                     = var.http2_enabled
    minimum_tls_version               = var.minimum_tls_version
    ftps_state                        = var.ftps_state
    health_check_path                 = var.health_check_path
    health_check_eviction_time_in_min = var.health_check_eviction_time_in_min
    vnet_route_all_enabled            = var.vnet_route_all_enabled

    dynamic "application_stack" {
      for_each = var.linux_application_stack != null ? [var.linux_application_stack] : []
      content {
        docker_image_name        = try(application_stack.value.docker_image_name, null)
        docker_registry_url      = try(application_stack.value.docker_registry_url, null)
        docker_registry_username = try(application_stack.value.docker_registry_username, null)
        docker_registry_password = try(application_stack.value.docker_registry_password, null)
        dotnet_version           = try(application_stack.value.dotnet_version, null)
        java_version             = try(application_stack.value.java_version, null)
        node_version             = try(application_stack.value.node_version, null)
        php_version              = try(application_stack.value.php_version, null)
        python_version           = try(application_stack.value.python_version, null)
        go_version               = try(application_stack.value.go_version, null)
      }
    }

    dynamic "ip_restriction" {
      for_each = var.ip_restrictions
      content {
        name                      = ip_restriction.key
        action                    = ip_restriction.value.action
        priority                  = ip_restriction.value.priority
        ip_address                = try(ip_restriction.value.ip_address, null)
        virtual_network_subnet_id = try(ip_restriction.value.virtual_network_subnet_id, null)
        service_tag               = try(ip_restriction.value.service_tag, null)
      }
    }
  }

  app_settings = var.app_settings

  dynamic "connection_string" {
    for_each = var.connection_strings
    content {
      name  = connection_string.key
      type  = connection_string.value.type
      value = connection_string.value.value
    }
  }

  identity {
    type = var.identity_type
  }

  logs {
    detailed_error_messages = var.detailed_error_messages
    failed_request_tracing  = var.failed_request_tracing

    http_logs {
      file_system {
        retention_in_days = var.http_logs_retention_days
        retention_in_mb   = var.http_logs_retention_mb
      }
    }

    application_logs {
      file_system_level = var.app_logs_file_system_level
    }
  }

  tags = var.tags
}

resource "azurerm_windows_web_app" "webapp" {
  count               = var.os_type == "Windows" ? 1 : 0
  name                = var.app_name
  location            = var.location
  resource_group_name = var.resource_group_name
  service_plan_id     = azurerm_service_plan.plan.id

  https_only                    = var.https_only
  client_affinity_enabled       = var.client_affinity_enabled
  virtual_network_subnet_id     = var.virtual_network_subnet_id
  public_network_access_enabled = var.public_network_access_enabled

  site_config {
    always_on                         = var.always_on
    http2_enabled                     = var.http2_enabled
    minimum_tls_version               = var.minimum_tls_version
    ftps_state                        = var.ftps_state
    health_check_path                 = var.health_check_path
    health_check_eviction_time_in_min = var.health_check_eviction_time_in_min
    vnet_route_all_enabled            = var.vnet_route_all_enabled

    dynamic "application_stack" {
      for_each = var.windows_application_stack != null ? [var.windows_application_stack] : []
      content {
        current_stack  = try(application_stack.value.current_stack, null)
        dotnet_version = try(application_stack.value.dotnet_version, null)
        java_version   = try(application_stack.value.java_version, null)
        node_version   = try(application_stack.value.node_version, null)
        php_version    = try(application_stack.value.php_version, null)
        python         = try(application_stack.value.python, null)
      }
    }

    dynamic "ip_restriction" {
      for_each = var.ip_restrictions
      content {
        name                      = ip_restriction.key
        action                    = ip_restriction.value.action
        priority                  = ip_restriction.value.priority
        ip_address                = try(ip_restriction.value.ip_address, null)
        virtual_network_subnet_id = try(ip_restriction.value.virtual_network_subnet_id, null)
        service_tag               = try(ip_restriction.value.service_tag, null)
      }
    }
  }

  app_settings = var.app_settings

  dynamic "connection_string" {
    for_each = var.connection_strings
    content {
      name  = connection_string.key
      type  = connection_string.value.type
      value = connection_string.value.value
    }
  }

  identity {
    type = var.identity_type
  }

  logs {
    detailed_error_messages = var.detailed_error_messages
    failed_request_tracing  = var.failed_request_tracing

    http_logs {
      file_system {
        retention_in_days = var.http_logs_retention_days
        retention_in_mb   = var.http_logs_retention_mb
      }
    }

    application_logs {
      file_system_level = var.app_logs_file_system_level
    }
  }

  tags = var.tags
}

# Diagnostic settings
resource "azurerm_monitor_diagnostic_setting" "webapp_diagnostics" {
  count                      = var.log_analytics_workspace_id != null ? 1 : 0
  name                       = "${var.app_name}-diagnostics"
  target_resource_id         = var.os_type == "Linux" ? azurerm_linux_web_app.webapp[0].id : azurerm_windows_web_app.webapp[0].id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "AppServiceHTTPLogs"
  }

  enabled_log {
    category = "AppServiceConsoleLogs"
  }

  enabled_log {
    category = "AppServiceAppLogs"
  }

  metric {
    category = "AllMetrics"
  }
}
