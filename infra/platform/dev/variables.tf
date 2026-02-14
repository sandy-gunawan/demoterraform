# =============================================================================
# PLATFORM LAYER VARIABLES - Dev Environment
# =============================================================================
# 🎓 These variables control the platform infrastructure (VNets, Security).
#    App-level variables (AKS nodes, Cosmos RU, etc.) are in infra/envs/dev/variables.tf
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

variable "subscription_id" {
  description = "Azure subscription ID (recommended to avoid wrong default subscription context)"
  type        = string
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
# PLATFORM FEATURE TOGGLES
# =============================================================================

variable "enable_nat_gateway" {
  description = "Deploy NAT Gateway for outbound traffic control"
  type        = bool
  default     = false
}

variable "enable_key_vault" {
  description = "Deploy platform-level Key Vault"
  type        = bool
  default     = true
}

variable "key_vault_purge_protection" {
  description = "Enable Key Vault purge protection"
  type        = bool
  default     = false
}

variable "network_acl_default_action" {
  description = "Default action for network ACLs (Allow = open, Deny = restricted)"
  type        = string
  default     = "Allow"
}

variable "log_retention_days" {
  description = "Log Analytics retention in days"
  type        = number
  default     = 30
}
