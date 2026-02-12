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
  description = "Azure region (indonesiacentral for Indonesia)"
  type        = string
  default     = "indonesiacentral"
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
  default     = "B1" # Basic tier for dev
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
  default     = "" # Empty = allow from Azure services only
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
