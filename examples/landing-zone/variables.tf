variable "organization_name" {
  description = "Organization name (used for resource naming)"
  type        = string
}

variable "location" {
  description = "Primary Azure region"
  type        = string
  default     = "eastus"
}

variable "secondary_location" {
  description = "Secondary Azure region for geo-redundancy"
  type        = string
  default     = "westus"
}

variable "tenant_id" {
  description = "Azure tenant ID"
  type        = string
}

variable "hub_address_space" {
  description = "Address space for hub virtual network"
  type        = string
  default     = "10.0.0.0/16"
}

variable "spoke_networks" {
  description = "Map of spoke networks to create"
  type = map(object({
    address_space = string
    environment   = string
    application   = string
  }))
}

variable "log_retention_days" {
  description = "Log retention in days"
  type        = number
  default     = 90
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
