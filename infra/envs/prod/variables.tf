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
# Production: Full deployment
# =============================================================================

variable "enable_aks" {
  description = "Deploy AKS cluster"
  type        = bool
  default     = true  # Prod: Enable what you need
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
  default     = true  # Prod: If you need database
}

variable "enable_key_vault" {
  description = "Deploy Key Vault (recommended for all environments)"
  type        = bool
  default     = true
}

# =============================================================================
# SECURITY FEATURES
# Production: ALL ENABLED for maximum security
# =============================================================================

variable "enable_nat_gateway" {
  description = "Deploy NAT Gateway for outbound traffic control"
  type        = bool
  default     = true  # Prod: Yes
}

variable "enable_private_endpoints" {
  description = "Use private endpoints instead of public access"
  type        = bool
  default     = true  # Prod: Yes - no public access
}

variable "enable_ddos_protection" {
  description = "Enable DDoS Protection Plan (expensive but important)"
  type        = bool
  default     = true  # Prod: Yes
}

variable "key_vault_purge_protection" {
  description = "Enable Key Vault purge protection (blocks deletion for 90 days)"
  type        = bool
  default     = true  # Prod: Yes
}

variable "network_acl_default_action" {
  description = "Default action for network ACLs (Allow = open, Deny = restricted)"
  type        = string
  default     = "Deny"  # Prod: Deny all by default
}

# =============================================================================
# MONITORING FEATURES
# Production: FULL monitoring and diagnostics
# =============================================================================

variable "enable_application_insights" {
  description = "Deploy Application Insights"
  type        = bool
  default     = true  # Prod: Yes
}

variable "enable_diagnostic_settings" {
  description = "Enable diagnostic settings on resources"
  type        = bool
  default     = true  # Prod: Yes
}

variable "log_retention_days" {
  description = "Log Analytics retention in days"
  type        = number
  default     = 90  # Prod: 3 months (or more for compliance)
}

# =============================================================================
# SCALING & RELIABILITY
# Production: Auto-scaling, geo-redundancy, continuous backup
# =============================================================================

variable "enable_auto_scaling" {
  description = "Enable auto-scaling for compute resources"
  type        = bool
  default     = true  # Prod: Yes
}

variable "enable_geo_redundancy" {
  description = "Enable geo-redundant storage/databases"
  type        = bool
  default     = true  # Prod: Yes
}

variable "enable_continuous_backup" {
  description = "Enable continuous backup for databases (vs periodic)"
  type        = bool
  default     = true  # Prod: Yes
}

variable "aks_node_count" {
  description = "Minimum AKS nodes (used as min when auto-scaling)"
  type        = number
  default     = 3  # Prod: 3 nodes minimum
}

variable "aks_max_node_count" {
  description = "Maximum AKS nodes for auto-scaling"
  type        = number
  default     = 10  # Prod: Scale up to 10
}

variable "aks_node_size" {
  description = "AKS node VM size"
  type        = string
  default     = "Standard_D4s_v3"  # Prod: Production-grade VM
}
