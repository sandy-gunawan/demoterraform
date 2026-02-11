# =============================================================================
# BASIC CONFIGURATION
# =============================================================================

variable "organization_name" {
  description = "Organization name for resource naming"
  type        = string
  default     = "myorg"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "myproject"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

variable "tenant_id" {
  description = "Azure tenant ID"
  type        = string
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

variable "enable_key_vault" {
  description = "Deploy Key Vault (recommended for all environments)"
  type        = bool
  default     = true
}

# =============================================================================
# SECURITY FEATURES
# Dev: All disabled for simplicity
# =============================================================================

variable "enable_nat_gateway" {
  description = "Deploy NAT Gateway for outbound traffic control"
  type        = bool
  default     = false
}

variable "enable_private_endpoints" {
  description = "Use private endpoints instead of public access"
  type        = bool
  default     = false
}

variable "enable_ddos_protection" {
  description = "Enable DDoS Protection Plan (expensive!)"
  type        = bool
  default     = false
}

variable "key_vault_purge_protection" {
  description = "Enable Key Vault purge protection (blocks deletion for 90 days)"
  type        = bool
  default     = false
}

variable "network_acl_default_action" {
  description = "Default action for network ACLs (Allow = open, Deny = restricted)"
  type        = string
  default     = "Allow"
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

variable "log_retention_days" {
  description = "Log Analytics retention in days"
  type        = number
  default     = 30
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
  default     = "Standard_D8ds_v5"  # Available in indonesiacentral
}

# =============================================================================
# COSMOS DB CONFIGURATION
# Only used when enable_cosmosdb = true
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
  default     = "Local"  # Indonesia Central doesn't support Geo-redundant backup
}
