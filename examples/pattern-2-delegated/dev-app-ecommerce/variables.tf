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
  default     = "CC-1234"
}

variable "owner_email" {
  description = "Owner email for the resources"
  type        = string
  default     = "ecommerce-team@contoso.com"
}

variable "repository_url" {
  description = "Git repository URL"
  type        = string
  default     = "https://dev.azure.com/contoso/terraform-infrastructure"
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
  default     = "" # Empty = allow from Azure services only
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
