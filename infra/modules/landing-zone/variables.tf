#------------------------------------------------------------------------------
# Required Variables
#------------------------------------------------------------------------------

variable "resource_group_name" {
  description = "Name of the resource group for the Landing Zone"
  type        = string
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
}

variable "vnet_name" {
  description = "Name of the virtual network"
  type        = string
}

variable "address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
}

variable "subnets" {
  description = "Map of subnets to create"
  type = map(object({
    address_prefixes  = list(string)
    service_endpoints = optional(list(string), [])
    delegation = optional(object({
      name         = string
      service_name = string
      actions      = optional(list(string), [])
    }))
  }))
}

variable "log_analytics_name" {
  description = "Name of the Log Analytics workspace"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
}

#------------------------------------------------------------------------------
# Optional Variables
#------------------------------------------------------------------------------

variable "dns_servers" {
  description = "Custom DNS servers for the virtual network"
  type        = list(string)
  default     = []
}

variable "network_security_groups" {
  description = "Map of Network Security Groups with rules"
  type = map(object({
    security_rules = optional(map(object({
      priority                   = number
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = optional(string, "*")
      destination_port_range     = optional(string, "*")
      source_address_prefix      = optional(string, "*")
      destination_address_prefix = optional(string, "*")
    })), {})
  }))
  default = {}
}

variable "subnet_nsg_associations" {
  description = "Map of subnet names to NSG names for association"
  type        = map(string)
  default     = {}
}

variable "log_analytics_sku" {
  description = "SKU for Log Analytics workspace"
  type        = string
  default     = "PerGB2018"
}

variable "log_analytics_retention_days" {
  description = "Retention period in days for Log Analytics"
  type        = number
  default     = 30
  validation {
    condition     = var.log_analytics_retention_days >= 30 && var.log_analytics_retention_days <= 730
    error_message = "Retention days must be between 30 and 730."
  }
}

variable "create_application_insights" {
  description = "Whether to create Application Insights"
  type        = bool
  default     = false
}

variable "application_insights_name" {
  description = "Name of the Application Insights resource"
  type        = string
  default     = ""
}

variable "create_nat_gateway" {
  description = "Whether to create NAT Gateway for outbound internet access"
  type        = bool
  default     = false
}

variable "nat_gateway_subnet_associations" {
  description = "Map of subnet names to associate with NAT Gateway"
  type        = map(string)
  default     = {}
}
