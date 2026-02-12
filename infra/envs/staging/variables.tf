# =============================================================================
# BASIC CONFIGURATION
# =============================================================================

variable "organization_name" {
  description = "Organization name for resource naming"
  type        = string
  default     = "contoso"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "contoso"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "indonesiacentral"
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
# Staging: Same as dev, test before prod
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
# Staging: Basic hardening, no expensive features
# =============================================================================

variable "enable_nat_gateway" {
  description = "Deploy NAT Gateway for outbound traffic control"
  type        = bool
  default     = false # Staging: No
}

variable "enable_private_endpoints" {
  description = "Use private endpoints instead of public access"
  type        = bool
  default     = false # Staging: No
}

variable "enable_ddos_protection" {
  description = "Enable DDoS Protection Plan (expensive!)"
  type        = bool
  default     = false
}

variable "key_vault_purge_protection" {
  description = "Enable Key Vault purge protection (blocks deletion for 90 days)"
  type        = bool
  default     = true # Staging: Yes - protect secrets
}

variable "network_acl_default_action" {
  description = "Default action for network ACLs (Allow = open, Deny = restricted)"
  type        = string
  default     = "Deny" # Staging: Tighter security
}

# =============================================================================
# MONITORING FEATURES
# Staging: Enable monitoring for testing
# =============================================================================

variable "enable_application_insights" {
  description = "Deploy Application Insights"
  type        = bool
  default     = true # Staging: Yes
}

variable "enable_diagnostic_settings" {
  description = "Enable diagnostic settings on resources"
  type        = bool
  default     = true # Staging: Yes
}

variable "log_retention_days" {
  description = "Log Analytics retention in days"
  type        = number
  default     = 60 # Staging: Medium retention
}

# =============================================================================
# SCALING & RELIABILITY
# Staging: Fixed size, similar to dev
# =============================================================================

variable "enable_auto_scaling" {
  description = "Enable auto-scaling for compute resources"
  type        = bool
  default     = false # Staging: No
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
  default     = 2 # Staging: 2 nodes for testing
}

variable "aks_node_size" {
  description = "AKS node VM size"
  type        = string
  default     = "Standard_D4s_v3" # Staging: Medium size (4 vCPU, 16GB RAM) - Available in SE Asia
}
