# ============================================================================
# CORE VARIABLES
# ============================================================================

variable "company_name" {
  description = "Company or organization name"
  type        = string
  default     = "contoso"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "workload" {
  description = "Workload or application name"
  type        = string
  default     = "ecommerce"
}

variable "location" {
  description = "Azure region (southeastasia recommended for Indonesia)"
  type        = string
  default     = "southeastasia"
}

# ============================================================================
# TAGS
# ============================================================================

variable "default_tags" {
  description = "Default tags for all resources"
  type        = map(string)
  default = {
    Environment = "dev"
    ManagedBy   = "Terraform"
    Team        = "E-commerce Team"
    CostCenter  = "CC-1234"
  }
}

# ============================================================================
# AKS CONFIGURATION
# ============================================================================

variable "use_shared_aks" {
  description = "Use shared AKS cluster (true) or deploy dedicated (false)"
  type        = bool
  default     = true
}

variable "kubernetes_version" {
  description = "Kubernetes version for AKS"
  type        = string
  default     = "1.28"
}

variable "aks_node_count" {
  description = "Initial node count for AKS"
  type        = number
  default     = 2
}

variable "aks_vm_size" {
  description = "VM size for AKS nodes"
  type        = string
  default     = "Standard_D2s_v3"
}

# ============================================================================
# COSMOS DB CONFIGURATION
# ============================================================================

variable "cosmos_consistency_level" {
  description = "Cosmos DB consistency level"
  type        = string
  default     = "Session"
}

variable "cosmos_allowed_ips" {
  description = "IP addresses allowed to access Cosmos DB (comma-separated)"
  type        = string
  default     = ""  # Empty = allow from Azure services only
}

variable "cosmos_products_ru" {
  description = "Request Units for products container"
  type        = number
  default     = 400
}

variable "cosmos_orders_ru" {
  description = "Request Units for orders container"
  type        = number
  default     = 400
}

variable "cosmos_inventory_ru" {
  description = "Request Units for inventory container"
  type        = number
  default     = 400
}

# ============================================================================
# NETWORKING CONFIGURATION
# ============================================================================

variable "vnet_address_space" {
  description = "Address space for E-commerce's VNet (10.3.0.0/16 for E-commerce app)"
  type        = list(string)
  default     = ["10.3.0.0/16"]
}

variable "subnets" {
  description = "Subnets configuration for E-commerce VNet"
  type = map(object({
    address_prefixes  = list(string)
    service_endpoints = optional(list(string), [])
    delegation = optional(object({
      name         = string
      service_name = string
      actions      = list(string)
    }))
  }))
  default = {
    "aks-subnet" = {
      address_prefixes = ["10.3.1.0/24"]
      service_endpoints = [
        "Microsoft.ContainerRegistry",
        "Microsoft.AzureCosmosDB"
      ]
    }
    "db-subnet" = {
      address_prefixes  = ["10.3.2.0/24"]
      service_endpoints = ["Microsoft.AzureCosmosDB"]
    }
  }
}

variable "network_security_groups" {
  description = "NSG configurations for E-commerce subnets"
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
  default = {
    "aks-nsg" = {
      security_rules = {
        "allow-https" = {
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "443"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        }
        "allow-http" = {
          priority                   = 110
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "80"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        }
      }
    }
  }
}

variable "subnet_nsg_associations" {
  description = "Map subnet names to NSG names"
  type        = map(string)
  default = {
    "aks-subnet" = "aks-nsg"
  }
}
