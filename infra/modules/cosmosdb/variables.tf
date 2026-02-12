variable "resource_group_name" {
  description = "Name of the resource group for Cosmos DB resources"
  type        = string
}

variable "account_name" {
  description = "Cosmos DB account name (must be globally unique)"
  type        = string
}

variable "location" {
  description = "Azure region for the Cosmos DB account"
  type        = string
}

variable "kind" {
  description = "Kind of Cosmos DB account (GlobalDocumentDB, MongoDB, or Cassandra)"
  type        = string
  default     = "GlobalDocumentDB"
}

variable "consistency_level" {
  description = "Consistency level (Eventual, Session, BoundedStaleness, Strong, ConsistentPrefix)"
  type        = string
  default     = "Session"
  validation {
    condition     = contains(["Eventual", "Session", "BoundedStaleness", "Strong", "ConsistentPrefix"], var.consistency_level)
    error_message = "Invalid consistency level."
  }
}

variable "max_interval_in_seconds" {
  description = "Max lag time for BoundedStaleness consistency"
  type        = number
  default     = 300
}

variable "max_staleness_prefix" {
  description = "Max stale requests for BoundedStaleness consistency"
  type        = number
  default     = 100000
}

variable "failover_locations" {
  description = "Additional failover locations"
  type = list(object({
    location          = string
    failover_priority = number
  }))
  default = []
}

variable "public_network_access_enabled" {
  description = "Enable public network access"
  type        = bool
  default     = true
}

variable "enable_virtual_network_filter" {
  description = "Enable virtual network filtering"
  type        = bool
  default     = false
}

variable "virtual_network_rules" {
  description = "List of subnet IDs for virtual network rules"
  type        = list(string)
  default     = []
}

variable "backup_type" {
  description = "Backup type (Periodic or Continuous)"
  type        = string
  default     = "Periodic"
}

variable "backup_interval_in_minutes" {
  description = "Backup interval in minutes for periodic backup"
  type        = number
  default     = 240
}

variable "backup_retention_in_hours" {
  description = "Backup retention in hours for periodic backup"
  type        = number
  default     = 8
}

variable "backup_storage_redundancy" {
  description = "Backup storage redundancy (Geo, Local, Zone) - Not all regions support all types"
  type        = string
  default     = "Local" # Changed from Geo - more regions support Local
}

variable "enable_automatic_failover" {
  description = "Enable automatic failover"
  type        = bool
  default     = true
}

variable "enable_multiple_write_locations" {
  description = "Enable multi-region writes"
  type        = bool
  default     = false
}

variable "local_authentication_disabled" {
  description = "Disable local authentication (use Azure AD only)"
  type        = bool
  default     = false
}

variable "sql_databases" {
  description = "Map of SQL databases to create"
  type = map(object({
    throughput               = optional(number)
    autoscale_max_throughput = optional(number)
  }))
  default = {}
}

variable "sql_containers" {
  description = "Map of SQL containers to create"
  type = map(object({
    database_name            = string
    partition_key_paths      = list(string)
    partition_key_version    = optional(number, 2)
    throughput               = optional(number)
    autoscale_max_throughput = optional(number)
    indexing_mode            = optional(string, "consistent")
    included_paths           = optional(list(string), ["/*"])
    excluded_paths           = optional(list(string), [])
    default_ttl              = optional(number, -1)
    analytical_storage_ttl   = optional(number)
  }))
  default = {}
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for diagnostics"
  type        = string
  default     = null
}

variable "enable_private_endpoint" {
  description = "Create private endpoint for Cosmos DB"
  type        = bool
  default     = false
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID for private endpoint"
  type        = string
  default     = null
}

variable "vnet_id" {
  description = "VNet ID for private DNS zone linking (required for PE DNS resolution)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
