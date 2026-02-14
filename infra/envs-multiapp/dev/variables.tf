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
  default     = "dev"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "indonesiacentral"
}

variable "subscription_id" {
  description = "Azure subscription ID (recommended to avoid wrong default subscription context)"
  type        = string
  default     = ""
}

variable "tenant_id" {
  description = "Azure tenant ID"
  type        = string
  default     = ""
}

variable "cost_center" {
  description = "Cost center"
  type        = string
  default     = "Engineering-Dev"
}

variable "owner_email" {
  description = "Owner email"
  type        = string
  default     = "devops@contoso.com"
}

variable "repository_url" {
  description = "Repository URL"
  type        = string
  default     = "https://dev.azure.com/contoso/terraform-infrastructure"
}

variable "aks_node_count" {
  description = "AKS node count"
  type        = number
  default     = 1
}

variable "aks_node_size" {
  description = "AKS node size"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "enable_auto_scaling" {
  description = "Enable AKS autoscaling"
  type        = bool
  default     = false
}

variable "cosmosdb_backup_storage_redundancy" {
  description = "Cosmos DB backup storage redundancy"
  type        = string
  default     = "Local"
}

# Team-level toggles (Pattern 1 centralized, but multi-app)
variable "enable_ecommerce_aks" {
  description = "Deploy AKS for Ecommerce team"
  type        = bool
  default     = false
}

variable "enable_ecommerce_cosmosdb" {
  description = "Deploy Cosmos DB for Ecommerce team"
  type        = bool
  default     = false
}

variable "enable_crm_aks" {
  description = "Deploy AKS for CRM team"
  type        = bool
  default     = false
}

variable "enable_crm_cosmosdb" {
  description = "Deploy Cosmos DB for CRM team"
  type        = bool
  default     = false
}
