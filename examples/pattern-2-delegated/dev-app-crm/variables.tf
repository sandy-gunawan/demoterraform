# ============================================================================
# CORE VARIABLES
# ============================================================================
# 🎓 THESE VARIABLES are overridden in dev.tfvars.
#    The "default" values here are fallbacks if dev.tfvars doesn't set them.
#    HOW TO CHANGE: Edit dev.tfvars (not this file!) for environment-specific values.
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
# TAGS - Inherited from Global Standards
# ============================================================================
# 🎓 NEWBIE NOTE: Tags are now inherited from global_standards module.
#    No more hardcoded default_tags! Just set cost_center and owner_email.
# ============================================================================

variable "cost_center" {
  description = "Cost center for billing (used by global_standards module)"
  type        = string
  default     = "CC-5678"
}

variable "owner_email" {
  description = "Owner email for the resources"
  type        = string
  default     = "crm-team@contoso.com"
}

variable "repository_url" {
  description = "Git repository URL"
  type        = string
  default     = "https://dev.azure.com/contoso/terraform-infrastructure"
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
# 🎓 REQUEST UNITS (RU): Cosmos DB's measure of throughput.
#    400 RU = ~$24/month per container (minimum). Higher RU = faster queries.
#    Dev: 400 RU (minimum, save cost)
#    Prod: 4000+ RU with autoscale (handle real traffic)
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
