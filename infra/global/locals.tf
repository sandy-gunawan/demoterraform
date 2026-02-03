# Global Naming and Tagging Standards
# All teams must inherit these standards to ensure consistency

locals {
  # Naming Convention: {org}-{project}-{resource}-{env}
  # Example: contoso-myapp-aks-prod
  
  # Standard naming components
  naming = {
    organization = var.organization_name
    project      = var.project_name
    environment  = var.environment
    location     = var.location
  }

  # Resource naming patterns
  resource_names = {
    resource_group       = "${local.naming.organization}-${local.naming.project}-rg-${local.naming.environment}"
    aks_cluster          = "${local.naming.organization}-${local.naming.project}-aks-${local.naming.environment}"
    vnet                 = "${local.naming.organization}-${local.naming.project}-vnet-${local.naming.environment}"
    log_analytics        = "${local.naming.organization}-${local.naming.project}-logs-${local.naming.environment}"
    key_vault            = "${local.naming.organization}-${local.naming.project}-kv-${local.naming.environment}"
    storage_account      = lower(replace("${local.naming.organization}${local.naming.project}st${local.naming.environment}", "-", ""))
    cosmos_db            = "${local.naming.organization}-${local.naming.project}-cosmos-${local.naming.environment}"
    container_registry   = lower(replace("${local.naming.organization}${local.naming.project}acr", "-", ""))
    app_service          = "${local.naming.organization}-${local.naming.project}-app-${local.naming.environment}"
  }

  # Standard tags applied to all resources
  standard_tags = {
    ManagedBy       = "Terraform"
    Organization    = local.naming.organization
    Project         = local.naming.project
    Environment     = local.naming.environment
    DeploymentDate  = timestamp()
    CostCenter      = var.cost_center
    Owner           = var.owner_email
    Repository      = var.repository_url
  }

  # Merge standard tags with environment-specific tags
  common_tags = merge(
    local.standard_tags,
    var.additional_tags
  )

  # Location abbreviations (for storage accounts with length limits)
  location_short = {
    eastus       = "eus"
    westus       = "wus"
    centralus    = "cus"
    westeurope   = "weu"
    northeurope  = "neu"
    southeastasia = "sea"
    eastasia     = "ea"
  }
}

# Common variables used by naming standards
variable "organization_name" {
  description = "Organization name for resource naming"
  type        = string
  default     = "org"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
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

variable "additional_tags" {
  description = "Additional tags specific to environment"
  type        = map(string)
  default     = {}
}
