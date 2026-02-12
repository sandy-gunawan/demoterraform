# Centralized Naming Convention
#
# WHY THIS FILE EXISTS:
# Azure resources have naming rules (length limits, allowed characters).
# This file creates consistent, predictable names across all environments.
#
# NAMING PATTERN:
#   {project}-{environment}-{resource-type}-{region}
#
# EXAMPLES:
#   myapp-dev-rg-eastus        (Resource Group)
#   myapp-dev-aks-eastus       (AKS Cluster)
#   myappdevkveastus           (Key Vault - no hyphens allowed!)
#   myappdevcosmoseastus       (Cosmos DB)

# Input variables
variable "project_name" {
  description = "Project name (keep short, 3-10 chars)"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

# Local values for naming
locals {
  # Short region names (for length-limited resources)
  region_short = {
    "eastus"        = "eus"
    "eastus2"       = "eus2"
    "westus"        = "wus"
    "westus2"       = "wus2"
    "westeurope"    = "weu"
    "northeurope"   = "neu"
    "southeastasia" = "sea"
    "australiaeast" = "aue"
    "centralus"     = "cus"
    "japaneast"     = "jpe"
    "uksouth"       = "uks"
  }

  # Environment short names
  env_short = {
    "development" = "dev"
    "dev"         = "dev"
    "staging"     = "stg"
    "stg"         = "stg"
    "production"  = "prd"
    "prod"        = "prd"
  }

  # Get short versions
  region = lookup(local.region_short, var.location, substr(var.location, 0, 4))
  env    = lookup(local.env_short, var.environment, substr(var.environment, 0, 3))

  # Common name prefix
  prefix = "${var.project_name}-${local.env}"

  # Resource names with hyphens (most resources)
  names = {
    # Resource Groups
    resource_group        = "${local.prefix}-rg-${local.region}"
    resource_group_shared = "${local.prefix}-shared-rg-${local.region}"

    # Networking
    vnet        = "${local.prefix}-vnet-${local.region}"
    subnet_aks  = "${local.prefix}-aks-snet"
    subnet_app  = "${local.prefix}-app-snet"
    subnet_data = "${local.prefix}-data-snet"
    subnet_pe   = "${local.prefix}-pe-snet"
    nsg         = "${local.prefix}-nsg-${local.region}"
    nat_gateway = "${local.prefix}-natgw-${local.region}"

    # Compute
    aks_cluster       = "${local.prefix}-aks-${local.region}"
    container_app_env = "${local.prefix}-cae-${local.region}"
    app_service_plan  = "${local.prefix}-asp-${local.region}"
    webapp            = "${local.prefix}-app-${local.region}"
    function_app      = "${local.prefix}-func-${local.region}"

    # Data
    cosmos_account = "${local.prefix}-cosmos-${local.region}"

    # Monitoring
    log_analytics = "${local.prefix}-law-${local.region}"
    app_insights  = "${local.prefix}-ai-${local.region}"

    # Identity
    managed_identity = "${local.prefix}-id-${local.region}"
  }

  # Resource names WITHOUT hyphens (Key Vault, Storage Account)
  # These have strict naming rules!
  names_no_hyphen = {
    # Key Vault: 3-24 chars, alphanumeric only
    key_vault = substr(
      replace("${var.project_name}${local.env}kv${local.region}", "-", ""),
      0,
      24
    )

    # Storage Account: 3-24 chars, lowercase alphanumeric only
    storage_account = lower(substr(
      replace("${var.project_name}${local.env}st${local.region}", "-", ""),
      0,
      24
    ))

    # Container Registry: 5-50 chars, alphanumeric only
    container_registry = lower(substr(
      replace("${var.project_name}${local.env}acr${local.region}", "-", ""),
      0,
      50
    ))
  }
}

# Outputs - use these in your modules!
output "resource_names" {
  description = "Map of all resource names with hyphens"
  value       = local.names
}

output "resource_names_no_hyphen" {
  description = "Map of resource names without hyphens (Key Vault, Storage)"
  value       = local.names_no_hyphen
}

output "tags" {
  description = "Standard tags for all resources"
  value = {
    project     = var.project_name
    environment = var.environment
    managed_by  = "terraform"
  }
}
