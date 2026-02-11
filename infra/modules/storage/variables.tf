variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "storage_account_name" {
  description = "Name of the storage account (3-24 lowercase alphanumeric only)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "Storage account name must be 3-24 lowercase letters and numbers only."
  }
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "account_tier" {
  description = "Storage account tier (Standard or Premium)"
  type        = string
  default     = "Standard"
}

variable "account_replication_type" {
  description = "Replication type (LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS)"
  type        = string
  default     = "LRS"
}

variable "account_kind" {
  description = "Storage account kind"
  type        = string
  default     = "StorageV2"
}

variable "min_tls_version" {
  description = "Minimum TLS version"
  type        = string
  default     = "TLS1_2"
}

variable "allow_blob_public_access" {
  description = "Allow public access to blobs"
  type        = bool
  default     = false
}

variable "network_rules_default_action" {
  description = "Default action for network rules (Allow or Deny, null to skip)"
  type        = string
  default     = null
}

variable "network_rules_bypass" {
  description = "Services to bypass network rules"
  type        = list(string)
  default     = ["AzureServices"]
}

variable "network_rules_ip_rules" {
  description = "Allowed IP addresses"
  type        = list(string)
  default     = []
}

variable "network_rules_subnet_ids" {
  description = "Allowed subnet IDs"
  type        = list(string)
  default     = []
}

variable "blob_versioning_enabled" {
  description = "Enable blob versioning"
  type        = bool
  default     = false
}

variable "blob_change_feed_enabled" {
  description = "Enable blob change feed"
  type        = bool
  default     = false
}

variable "blob_last_access_time_enabled" {
  description = "Enable last access time tracking"
  type        = bool
  default     = false
}

variable "blob_delete_retention_days" {
  description = "Soft delete retention for blobs (null to disable)"
  type        = number
  default     = 7
}

variable "container_delete_retention_days" {
  description = "Soft delete retention for containers (null to disable)"
  type        = number
  default     = 7
}

variable "containers" {
  description = "Map of storage containers to create"
  type = map(object({
    access_type = optional(string, "private")
  }))
  default = {}
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
