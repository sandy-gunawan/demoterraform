# =============================================================================
# BASIC CONFIGURATION
# =============================================================================
# 🎓 THESE VARIABLES define WHO you are and WHERE to deploy.
#    Override them in dev.tfvars (e.g., location = "indonesiacentral")
#    If not overridden, the "default" value is used.
# =============================================================================

variable "organization_name" {
  description = "Organization name for resource naming"
  type        = string
  default     = "contoso"
}

variable "project_name" {
  description = "Name of the project (used in resource naming)"
  type        = string
  default     = "contoso"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region (indonesiacentral for Indonesia)"
  type        = string
  default     = "indonesiacentral"
}

variable "tenant_id" {
  description = "Azure tenant ID (for Key Vault, RBAC)"
  type        = string
  default     = "00000000-0000-0000-0000-000000000000"
}

variable "cost_center" {
  description = "Cost center for billing"
  type        = string
  default     = "Engineering"
}

variable "owner_email" {
  description = "Owner email for the resources"
  type        = string
  default     = "devops@company.com"
}

variable "repository_url" {
  description = "Git repository URL"
  type        = string
  default     = ""
}

# =============================================================================
# FEATURE TOGGLES - What to deploy
# Dev: Keep simple, disable expensive/complex features
# =============================================================================
# 🎓 HOW FEATURE TOGGLES WORK:
#    Set a variable to true/false → Terraform creates/skips the resource.
#    In main.tf, each module uses: count = var.enable_xxx ? 1 : 0
#    This gives you a "menu" — pick what you need, skip the rest.
#
# 🎓 TIP: Start with everything false in dev. Enable one at a time.
#    Each resource adds cost. Check Azure pricing calculator first!
# =============================================================================

variable "enable_aks" {
  description = "Deploy AKS cluster"
  type        = bool
  default     = false
}

variable "enable_container_apps" {
  description = "Deploy Container Apps environment"
  type        = bool
  default     = false
}

variable "enable_webapp" {
  description = "Deploy App Service"
  type        = bool
  default     = false
}

variable "enable_cosmosdb" {
  description = "Deploy Cosmos DB"
  type        = bool
  default     = false
}

# =============================================================================
# MONITORING FEATURES
# Dev: Minimal monitoring to save cost
# =============================================================================

variable "enable_application_insights" {
  description = "Deploy Application Insights"
  type        = bool
  default     = false
}

variable "enable_diagnostic_settings" {
  description = "Enable diagnostic settings on resources"
  type        = bool
  default     = false
}

# =============================================================================
# SCALING & RELIABILITY
# Dev: Fixed small size, no auto-scaling
# =============================================================================

variable "enable_auto_scaling" {
  description = "Enable auto-scaling for compute resources"
  type        = bool
  default     = false
}

variable "enable_geo_redundancy" {
  description = "Enable geo-redundant storage/databases"
  type        = bool
  default     = false
}

variable "enable_continuous_backup" {
  description = "Enable continuous backup for databases (vs periodic)"
  type        = bool
  default     = false
}

variable "aks_node_count" {
  description = "Number of AKS nodes (ignored if auto-scaling enabled)"
  type        = number
  default     = 1
}

variable "aks_node_size" {
  description = "AKS node VM size"
  type        = string
  default     = "Standard_D8ds_v5" # Available in indonesiacentral
}

# =============================================================================
# COSMOS DB CONFIGURATION
# Only used when enable_cosmosdb = true
# =============================================================================
# 🎓 WHEN TO CHANGE THESE:
#    - cosmosdb_consistency_level: Only change if you understand the tradeoffs
#      (Strong = consistent but slow, Eventual = fast but may read stale data)
#    - cosmosdb_account_name: Must be globally unique across ALL of Azure!
# =============================================================================

variable "cosmosdb_account_name" {
  description = "Cosmos DB account name (must be globally unique, lowercase, no hyphens)"
  type        = string
  default     = ""
}

variable "cosmosdb_consistency_level" {
  description = "Cosmos DB consistency level (Eventual, Session, BoundedStaleness, Strong, ConsistentPrefix)"
  type        = string
  default     = "Session"
}

variable "cosmosdb_database_name" {
  description = "Cosmos DB SQL database name"
  type        = string
  default     = "mydb"
}

variable "cosmosdb_containers" {
  description = "Map of Cosmos DB containers to create"
  type = map(object({
    partition_key_path       = string
    partition_key_version    = optional(number, 2)
    autoscale_max_throughput = optional(number)
    throughput               = optional(number)
  }))
  default = {}
}

variable "cosmosdb_backup_storage_redundancy" {
  description = "Cosmos DB backup storage redundancy (Geo, Local, Zone) - Not all regions support Geo"
  type        = string
  default     = "Local" # Indonesia Central doesn't support Geo-redundant backup
}
