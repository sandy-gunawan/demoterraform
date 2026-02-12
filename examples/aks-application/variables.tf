variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "app_name" {
  description = "Name of the application"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
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

variable "admin_group_object_ids" {
  description = "Azure AD group object IDs for admins"
  type        = list(string)
}

variable "log_retention_days" {
  description = "Log retention in days"
  type        = number
  default     = 90
}

# AKS Variables
variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28.3"
}

variable "aks_system_node_count" {
  description = "Initial system node count"
  type        = number
  default     = 3
}

variable "aks_system_node_size" {
  description = "System node VM size"
  type        = string
  default     = "Standard_D4s_v3"
}

variable "aks_system_min_nodes" {
  description = "Minimum system nodes"
  type        = number
  default     = 3
}

variable "aks_system_max_nodes" {
  description = "Maximum system nodes"
  type        = number
  default     = 10
}

variable "aks_user_node_count" {
  description = "Initial user node count"
  type        = number
  default     = 3
}

variable "aks_user_node_size" {
  description = "User node VM size"
  type        = string
  default     = "Standard_D8s_v3"
}

variable "aks_user_min_nodes" {
  description = "Minimum user nodes"
  type        = number
  default     = 2
}

variable "aks_user_max_nodes" {
  description = "Maximum user nodes"
  type        = number
  default     = 8
}

variable "enable_azure_policy" {
  description = "Enable Azure Policy for AKS"
  type        = bool
  default     = true
}

# Cosmos DB Variables
variable "cosmos_consistency_level" {
  description = "Cosmos DB consistency level"
  type        = string
  default     = "Session"
}

variable "cosmos_failover_locations" {
  description = "Cosmos DB failover locations"
  type = list(object({
    location          = string
    failover_priority = number
  }))
  default = [
    {
      location          = "westus"
      failover_priority = 1
    }
  ]
}

variable "cosmos_public_access" {
  description = "Enable public access to Cosmos DB"
  type        = bool
  default     = false
}

variable "cosmos_backup_type" {
  description = "Cosmos DB backup type"
  type        = string
  default     = "Continuous"
}

variable "cosmos_multi_region_writes" {
  description = "Enable multi-region writes"
  type        = bool
  default     = true
}

variable "cosmos_database_max_throughput" {
  description = "Maximum autoscale throughput for database"
  type        = number
  default     = 10000
}

# Key Vault Variables
variable "key_vault_public_access" {
  description = "Enable public access to Key Vault"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
