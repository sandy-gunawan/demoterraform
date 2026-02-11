variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "server_name" {
  description = "Name of the SQL Server (must be globally unique)"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "sql_version" {
  description = "SQL Server version"
  type        = string
  default     = "12.0"
}

variable "administrator_login" {
  description = "SQL Server administrator login"
  type        = string
  sensitive   = true
}

variable "administrator_login_password" {
  description = "SQL Server administrator password"
  type        = string
  sensitive   = true
}

variable "minimum_tls_version" {
  description = "Minimum TLS version"
  type        = string
  default     = "1.2"
}

variable "public_network_access_enabled" {
  description = "Enable public network access"
  type        = bool
  default     = true
}

variable "tenant_id" {
  description = "Azure AD tenant ID"
  type        = string
}

variable "azuread_admin_login" {
  description = "Azure AD admin login name"
  type        = string
}

variable "azuread_admin_object_id" {
  description = "Azure AD admin object ID"
  type        = string
}

variable "databases" {
  description = "Map of databases to create"
  type = map(object({
    collation          = optional(string, "SQL_Latin1_General_CP1_CI_AS")
    license_type       = optional(string, "LicenseIncluded")
    max_size_gb        = optional(number, 4)
    sku_name           = optional(string, "S0")
    zone_redundant     = optional(bool, false)
    read_scale         = optional(bool, false)
    read_replica_count = optional(number, 0)
  }))
  default = {}
}

variable "firewall_rules" {
  description = "Map of firewall rules"
  type = map(object({
    start_ip_address = string
    end_ip_address   = string
  }))
  default = {}
}

variable "allow_azure_services" {
  description = "Allow Azure services to access the server"
  type        = bool
  default     = true
}

variable "virtual_network_rules" {
  description = "Map of VNet rule names to subnet IDs"
  type        = map(string)
  default     = {}
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for diagnostics"
  type        = string
  default     = null
}

variable "enable_private_endpoint" {
  description = "Create private endpoint"
  type        = bool
  default     = false
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID for private endpoint"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
