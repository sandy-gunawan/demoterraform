variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "app_name" {
  description = "Name of the web app (must be globally unique)"
  type        = string
}

variable "os_type" {
  description = "Operating system type (Linux or Windows)"
  type        = string
  default     = "Linux"

  validation {
    condition     = contains(["Linux", "Windows"], var.os_type)
    error_message = "OS type must be either 'Linux' or 'Windows'."
  }
}

variable "sku_name" {
  description = "SKU name for App Service Plan (F1, B1, S1, P1V2, P1V3, etc.)"
  type        = string
  default     = "B1"
}

variable "https_only" {
  description = "Force HTTPS only traffic"
  type        = bool
  default     = true
}

variable "always_on" {
  description = "Keep app always on (required for production)"
  type        = bool
  default     = false
}

variable "http2_enabled" {
  description = "Enable HTTP/2"
  type        = bool
  default     = true
}

variable "minimum_tls_version" {
  description = "Minimum TLS version"
  type        = string
  default     = "1.2"

  validation {
    condition     = contains(["1.0", "1.1", "1.2", "1.3"], var.minimum_tls_version)
    error_message = "TLS version must be 1.0, 1.1, 1.2, or 1.3."
  }
}

variable "ftps_state" {
  description = "FTPS state (AllAllowed, FtpsOnly, Disabled)"
  type        = string
  default     = "Disabled"

  validation {
    condition     = contains(["AllAllowed", "FtpsOnly", "Disabled"], var.ftps_state)
    error_message = "FTPS state must be AllAllowed, FtpsOnly, or Disabled."
  }
}

variable "client_affinity_enabled" {
  description = "Enable session affinity (sticky sessions)"
  type        = bool
  default     = false
}

variable "health_check_path" {
  description = "Health check endpoint path"
  type        = string
  default     = null
}

variable "health_check_eviction_time_in_min" {
  description = "Time before unhealthy instance is removed"
  type        = number
  default     = null
}

variable "virtual_network_subnet_id" {
  description = "Subnet ID for VNet integration"
  type        = string
  default     = null
}

variable "public_network_access_enabled" {
  description = "Enable public network access"
  type        = bool
  default     = true
}

variable "vnet_route_all_enabled" {
  description = "Route all outbound traffic through VNet"
  type        = bool
  default     = false
}

variable "linux_application_stack" {
  description = "Linux application stack configuration"
  type = object({
    docker_image_name        = optional(string)
    docker_registry_url      = optional(string)
    docker_registry_username = optional(string)
    docker_registry_password = optional(string)
    dotnet_version           = optional(string)
    java_version             = optional(string)
    node_version             = optional(string)
    php_version              = optional(string)
    python_version           = optional(string)
    go_version               = optional(string)
  })
  default = null
}

variable "windows_application_stack" {
  description = "Windows application stack configuration"
  type = object({
    current_stack  = optional(string)
    dotnet_version = optional(string)
    java_version   = optional(string)
    node_version   = optional(string)
    php_version    = optional(string)
    python         = optional(bool)
  })
  default = null
}

variable "app_settings" {
  description = "Application settings (environment variables)"
  type        = map(string)
  default     = {}
}

variable "connection_strings" {
  description = "Connection strings"
  type = map(object({
    type  = string
    value = string
  }))
  default   = {}
  sensitive = true
}

variable "ip_restrictions" {
  description = "IP restriction rules"
  type = map(object({
    action                    = string
    priority                  = number
    ip_address                = optional(string)
    virtual_network_subnet_id = optional(string)
    service_tag               = optional(string)
  }))
  default = {}
}

variable "identity_type" {
  description = "Managed identity type (SystemAssigned, UserAssigned)"
  type        = string
  default     = "SystemAssigned"

  validation {
    condition     = contains(["SystemAssigned", "UserAssigned"], var.identity_type)
    error_message = "Identity type must be SystemAssigned or UserAssigned."
  }
}

variable "detailed_error_messages" {
  description = "Enable detailed error messages"
  type        = bool
  default     = false
}

variable "failed_request_tracing" {
  description = "Enable failed request tracing"
  type        = bool
  default     = false
}

variable "http_logs_retention_days" {
  description = "HTTP logs retention in days"
  type        = number
  default     = 7
}

variable "http_logs_retention_mb" {
  description = "HTTP logs retention in MB"
  type        = number
  default     = 35
}

variable "app_logs_file_system_level" {
  description = "Application logs level (Off, Error, Warning, Information, Verbose)"
  type        = string
  default     = "Information"

  validation {
    condition     = contains(["Off", "Error", "Warning", "Information", "Verbose"], var.app_logs_file_system_level)
    error_message = "Log level must be Off, Error, Warning, Information, or Verbose."
  }
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for diagnostics"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
}
