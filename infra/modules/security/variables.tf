variable "resource_group_name" {
  description = "Name of the resource group for security resources"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "key_vault_name" {
  description = "Name of the Key Vault (must be globally unique, 3-24 alphanumeric characters)"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{3,24}$", var.key_vault_name))
    error_message = "Key Vault name must be 3-24 characters, alphanumeric and hyphens only."
  }
}

variable "tenant_id" {
  description = "Azure AD tenant ID"
  type        = string
}

variable "sku_name" {
  description = "SKU name for Key Vault (standard or premium)"
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["standard", "premium"], var.sku_name)
    error_message = "SKU must be either 'standard' or 'premium'."
  }
}

variable "enabled_for_deployment" {
  description = "Allow Azure Virtual Machines to retrieve certificates"
  type        = bool
  default     = false
}

variable "enabled_for_disk_encryption" {
  description = "Allow Azure Disk Encryption to retrieve secrets"
  type        = bool
  default     = false
}

variable "enabled_for_template_deployment" {
  description = "Allow Azure Resource Manager to retrieve secrets"
  type        = bool
  default     = true
}

variable "enable_rbac_authorization" {
  description = "Use Azure RBAC for access control (recommended over access policies)"
  type        = bool
  default     = true
}

variable "purge_protection_enabled" {
  description = "Prevent permanent deletion (required for production)"
  type        = bool
  default     = false
}

variable "soft_delete_retention_days" {
  description = "Days to retain deleted Key Vault (7-90 days)"
  type        = number
  default     = 90

  validation {
    condition     = var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 90
    error_message = "Soft delete retention must be between 7 and 90 days."
  }
}

variable "network_acls_bypass" {
  description = "Allow Azure services to bypass network rules"
  type        = string
  default     = "AzureServices"

  validation {
    condition     = contains(["AzureServices", "None"], var.network_acls_bypass)
    error_message = "Bypass must be 'AzureServices' or 'None'."
  }
}

variable "network_acls_default_action" {
  description = "Default action for network rules (Allow or Deny)"
  type        = string
  default     = "Deny"

  validation {
    condition     = contains(["Allow", "Deny"], var.network_acls_default_action)
    error_message = "Default action must be 'Allow' or 'Deny'."
  }
}

variable "network_acls_ip_rules" {
  description = "List of IP addresses or CIDR blocks allowed to access Key Vault"
  type        = list(string)
  default     = []
}

variable "virtual_network_subnet_ids" {
  description = "List of subnet IDs allowed to access Key Vault"
  type        = list(string)
  default     = []
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for diagnostics (optional)"
  type        = string
  default     = null
}

variable "secrets" {
  description = "Map of secrets to create in Key Vault"
  type = map(object({
    value        = string
    content_type = optional(string)
  }))
  default   = {}
  sensitive = true
}

variable "enable_private_endpoint" {
  description = "Create private endpoint for Key Vault (VNet integration)"
  type        = bool
  default     = false
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID for private endpoint"
  type        = string
  default     = null
}

variable "vnet_id" {
  description = "Virtual network ID for private DNS zone link"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
