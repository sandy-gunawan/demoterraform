# Platform Layer Variables - Staging
variable "organization_name" {
  description = "Organization name"
  type        = string
  default     = "contoso"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "contoso"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "staging"
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
  description = "Owner email"
  type        = string
  default     = "devops@company.com"
}

variable "repository_url" {
  description = "Git repository URL"
  type        = string
  default     = ""
}

variable "enable_nat_gateway" {
  description = "Deploy NAT Gateway"
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
  default     = true
}

variable "network_acl_default_action" {
  description = "Default action for network ACLs"
  type        = string
  default     = "Deny"
}

variable "log_retention_days" {
  description = "Log Analytics retention in days"
  type        = number
  default     = 60
}
