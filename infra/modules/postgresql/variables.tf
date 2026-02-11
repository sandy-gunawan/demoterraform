variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "server_name" {
  description = "Name of the PostgreSQL Flexible Server (must be globally unique)"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "postgresql_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "16"

  validation {
    condition     = contains(["13", "14", "15", "16"], var.postgresql_version)
    error_message = "PostgreSQL version must be 13, 14, 15, or 16."
  }
}

variable "administrator_login" {
  description = "Administrator login name"
  type        = string
  sensitive   = true
}

variable "administrator_password" {
  description = "Administrator password"
  type        = string
  sensitive   = true
}

variable "sku_name" {
  description = "SKU name (e.g., B_Standard_B1ms, GP_Standard_D2s_v3, MO_Standard_E4s_v3)"
  type        = string
  default     = "B_Standard_B1ms"
}

variable "storage_mb" {
  description = "Storage size in MB"
  type        = number
  default     = 32768
}

variable "backup_retention_days" {
  description = "Backup retention period in days (7-35)"
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_days >= 7 && var.backup_retention_days <= 35
    error_message = "Backup retention must be between 7 and 35 days."
  }
}

variable "geo_redundant_backup_enabled" {
  description = "Enable geo-redundant backups"
  type        = bool
  default     = false
}

variable "availability_zone" {
  description = "Availability zone"
  type        = string
  default     = null
}

variable "high_availability_mode" {
  description = "High availability mode (ZoneRedundant or SameZone, null to disable)"
  type        = string
  default     = null

  validation {
    condition     = var.high_availability_mode == null || contains(["ZoneRedundant", "SameZone"], var.high_availability_mode)
    error_message = "HA mode must be ZoneRedundant, SameZone, or null."
  }
}

variable "standby_availability_zone" {
  description = "Standby availability zone for HA"
  type        = string
  default     = null
}

variable "public_network_access_enabled" {
  description = "Enable public network access"
  type        = bool
  default     = true
}

variable "delegated_subnet_id" {
  description = "Delegated subnet ID for VNet integration"
  type        = string
  default     = null
}

variable "private_dns_zone_id" {
  description = "Private DNS zone ID for VNet integration"
  type        = string
  default     = null
}

variable "aad_auth_enabled" {
  description = "Enable Azure AD authentication"
  type        = bool
  default     = false
}

variable "password_auth_enabled" {
  description = "Enable password authentication"
  type        = bool
  default     = true
}

variable "tenant_id" {
  description = "Azure AD tenant ID (required when aad_auth_enabled is true)"
  type        = string
  default     = null
}

variable "databases" {
  description = "Map of databases to create"
  type = map(object({
    collation = optional(string, "en_US.utf8")
    charset   = optional(string, "UTF8")
  }))
  default = {}
}

variable "server_configurations" {
  description = "Map of server configuration parameters"
  type        = map(string)
  default     = {}
}

variable "firewall_rules" {
  description = "Map of firewall rules"
  type = map(object({
    start_ip_address = string
    end_ip_address   = string
  }))
  default = {}
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for diagnostics"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
