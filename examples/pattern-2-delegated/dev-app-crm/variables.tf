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
  default     = "crm"
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
    Team        = "CRM Team"
    CostCenter  = "CC-5678"
  }
}

# ============================================================================
# APP SERVICE CONFIGURATION
# ============================================================================

variable "app_service_sku" {
  description = "App Service SKU (B1, S1, P1V2, etc.)"
  type        = string
  default     = "B1"  # Basic tier for dev
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

variable "cosmos_customers_ru" {
  description = "Request Units for customers container"
  type        = number
  default     = 400
}

variable "cosmos_interactions_ru" {
  description = "Request Units for interactions container"
  type        = number
  default     = 400
}

# ============================================================================
# NETWORKING CONFIGURATION
# ============================================================================

variable "vnet_address_space" {
  description = "Address space for CRM's VNet (10.2.0.0/16 for CRM app)"
  type        = list(string)
  default     = ["10.2.0.0/16"]
}

variable "subnets" {
  description = "Subnets configuration for CRM VNet"
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
    "app-subnet" = {
      address_prefixes = ["10.2.1.0/24"]
      service_endpoints = [
        "Microsoft.Web",
        "Microsoft.AzureCosmosDB",
        "Microsoft.KeyVault"
      ]
    }
    "db-subnet" = {
      address_prefixes  = ["10.2.2.0/24"]
      service_endpoints = ["Microsoft.AzureCosmosDB"]
    }
  }
}

variable "network_security_groups" {
  description = "NSG configurations for CRM subnets"
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
    "app-nsg" = {
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
    "app-subnet" = "app-nsg"
  }
}
