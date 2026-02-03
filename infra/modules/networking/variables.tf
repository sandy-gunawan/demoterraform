variable "resource_group_name" {
  description = "Name of the resource group for networking resources"
  type        = string
}

variable "network_name" {
  description = "Name of the virtual network"
  type        = string
}

variable "location" {
  description = "Azure region for network resources"
  type        = string
}

variable "address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnets" {
  description = "Map of subnets to create"
  type = map(object({
    address_prefixes  = list(string)
    service_endpoints = optional(list(string), [])
    delegation = optional(object({
      name         = string
      service_name = string
      actions      = list(string)
    }))
  }))
}

variable "network_security_groups" {
  description = "Map of NSGs to create with their security rules"
  type = map(object({
    security_rules = map(object({
      priority                   = number
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = string
      destination_port_range     = string
      source_address_prefix      = string
      destination_address_prefix = string
    }))
  }))
  default = {}
}

variable "subnet_nsg_associations" {
  description = "Map of subnet names to NSG names for association"
  type        = map(string)
  default     = {}
}

variable "create_nat_gateway" {
  description = "Create a NAT gateway for outbound connectivity"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
