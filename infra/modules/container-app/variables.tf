variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "environment_name" {
  description = "Name of the Container Apps environment"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for monitoring"
  type        = string
}

variable "infrastructure_subnet_id" {
  description = "Subnet ID for Container Apps environment (optional)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
  default     = {}
}

variable "secrets" {
  description = "Secrets to store in the container app"
  type        = map(string)
  sensitive   = true
  default     = {}
}

variable "ingress_external_enabled" {
  description = "Enable external ingress"
  type        = bool
  default     = true
}

variable "ingress_target_port" {
  description = "Target port for ingress"
  type        = number
  default     = 80
}

variable "ingress_transport" {
  description = "Transport protocol (auto, http, http2)"
  type        = string
  default     = "auto"
}

variable "log_retention_days" {
  description = "Log retention in days"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
