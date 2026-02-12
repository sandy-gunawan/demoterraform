# Application Layer - Development Environment (Pattern 1)
# =============================================================================
# 🎓 WHAT IS THE APPLICATION LAYER?
#    This is where Pattern 1 app teams deploy their applications.
#    Platform layer (infra/platform/dev/) creates VNets, Security, Monitoring.
#    This layer creates: AKS, CosmosDB, Container Apps, WebApp.
#
# 🎓 LAYERED INFRASTRUCTURE:
#    Layer 1: infra/platform/dev/   → VNets, Security, Log Analytics (DEPLOY FIRST!)
#    Layer 2: infra/envs/dev/       → THIS FILE: Applications only
#
# 🎓 DEPLOY ORDER:
#    Step 1: cd infra/platform/dev && terraform apply -var-file="dev.tfvars"
#    Step 2: cd infra/envs/dev && terraform apply -var-file="dev.tfvars"
#
# 🎓 WHY SEPARATE? If AKS deploy fails, VNets are safe (different state file).
#    Platform team manages networking, app teams manage their apps.
# =============================================================================
# PHILOSOPHY: Simple, cheap, fast iteration
# - Minimal resources, no expensive security features
# - Everything still works, just simplified
# =============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.45.0"
    }
  }
}

# =============================================================================
# PROVIDER CONFIGURATION
# =============================================================================
# 🎓 WHY PROVIDER? Tells Terraform HOW to talk to Azure.
#    Think of it as "logging in" to Azure for Terraform.
#
# 🎓 WHY FEATURES BLOCK? Safety settings to prevent accidentally destroying
#    important resources. These are the SAME across dev/staging/prod.
# =============================================================================
provider "azurerm" {
  features {
    key_vault {
      # WHY false? Don't permanently delete Key Vault when running "terraform destroy".
      # Key Vault has soft-delete (recoverable for 90 days). We keep it recoverable.
      purge_soft_delete_on_destroy = false
      # WHY true? If someone manually deleted a Key Vault, Terraform can recover it.
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      # WHY true? Prevents "terraform destroy" from deleting a resource group that
      # still has resources inside. Safety net against accidental data loss!
      prevent_deletion_if_contains_resources = true
    }
  }
}

# 🎓 WHY AZUREAD? Some resources (like RBAC, AAD groups for AKS) need
#    to talk to Azure Active Directory. This provider enables that.
provider "azuread" {}

# =============================================================================
# RESOURCE GROUP - Application layer's own resource group
# =============================================================================
# 🎓 WHAT IS A RESOURCE GROUP?
#    A logical container for Azure resources (like a folder on your computer).
#    Every Azure resource MUST belong to a resource group.
#
# 🎓 WHO CREATES THIS? App team (Pattern 1) creates this for their apps.
#    Platform team has: "contoso-platform-rg-dev" (in infra/platform/dev/)
#    App team has:      "contoso-apps-rg-dev" (THIS)
# =============================================================================
resource "azurerm_resource_group" "main" {
  name     = "contoso-apps-rg-${var.environment}"
  location = var.location
  tags     = module.global_standards.common_tags
}

# =============================================================================
# GLOBAL STANDARDS - Naming, tagging, etc.
# =============================================================================
# 🎓 WHAT IS THIS MODULE? Centralized naming and tagging rules.
#    SOURCE: infra/global/ (locals.tf, outputs.tf, versions.tf)
#
# 🎓 WHY? Ensures ALL resources across ALL environments have:
#    - Consistent naming (contoso-xxx-dev, contoso-xxx-staging, contoso-xxx-prod)
#    - Standard tags (ManagedBy, Environment, CostCenter, Owner, etc.)
#    - These tags help with: cost tracking, ownership, compliance audits
#
# 🎓 HOW IT'S USED: module.global_standards.common_tags → applied to every resource
# =============================================================================
module "global_standards" {
  source = "../../global"

  organization_name = var.organization_name
  project_name      = var.project_name
  environment       = var.environment
  location          = var.location
  cost_center       = var.cost_center
  owner_email       = var.owner_email
  repository_url    = var.repository_url
}

# =============================================================================
# DATA SOURCES - Read Platform layer's infrastructure
# =============================================================================
# 🎓 NEWBIE NOTE: We DON'T create VNets or Log Analytics here anymore!
#    The Platform team created them in infra/platform/dev/main.tf.
#    We READ them using data sources (read-only, no modification).
#
# ⚠️  PREREQUISITE: Platform layer MUST be deployed FIRST!
#    Run: cd infra/platform/dev && terraform apply -var-file="dev.tfvars"
# =============================================================================

# Read Platform's shared VNet (10.1.0.0/16)
data "azurerm_virtual_network" "platform" {
  name                = "vnet-${var.project_name}-${var.environment}-001"
  resource_group_name = "contoso-platform-rg-${var.environment}"
}

# Read Platform's AKS subnet (for AKS module below)
data "azurerm_subnet" "aks" {
  name                 = "aks-subnet"
  virtual_network_name = data.azurerm_virtual_network.platform.name
  resource_group_name  = data.azurerm_virtual_network.platform.resource_group_name
}

# Read Platform's app subnet (for Container Apps module below)
data "azurerm_subnet" "app" {
  name                 = "app-subnet"
  virtual_network_name = data.azurerm_virtual_network.platform.name
  resource_group_name  = data.azurerm_virtual_network.platform.resource_group_name
}

# Read Platform's Log Analytics workspace (for monitoring)
data "azurerm_log_analytics_workspace" "platform" {
  name                = "${var.project_name}-logs-${var.environment}"
  resource_group_name = "contoso-platform-rg-${var.environment}"
}

# =============================================================================
# APPLICATION INSIGHTS - Optional (controlled by feature toggle)
# =============================================================================
# 🎓 FEATURE TOGGLE PATTERN (used throughout this file):
#    count = var.enable_xxx ? 1 : 0
#    → If true:  count=1 → resource IS created (1 instance)
#    → If false: count=0 → resource is NOT created (0 instances)
#    → Access with: azurerm_application_insights.main[0] (note the [0])
#
# 🎓 WHY APP INSIGHTS? Monitors your APP's performance (response times, errors).
#    Different from Log Analytics which monitors INFRASTRUCTURE.
#    Dev: disabled (save $). Staging/Prod: enabled (need visibility).
# =============================================================================
resource "azurerm_application_insights" "main" {
  count = var.enable_application_insights ? 1 : 0

  name                = "${var.project_name}-insights-dev"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  workspace_id        = data.azurerm_log_analytics_workspace.platform.id
  application_type    = "web"

  tags = module.global_standards.common_tags
}

# =============================================================================
# AKS - Optional (controlled by feature toggle)
# =============================================================================
# 🎓 WHAT IS AKS? Azure Kubernetes Service — managed Kubernetes cluster.
#    Runs containerized applications (Docker) at scale.
#
# 🎓 HOW IT CONNECTS:
#    1. Lives in the "aks-subnet" (10.1.1.0/24) created by Platform layer
#    2. Sends logs to Log Analytics workspace (also from Platform layer)
#    3. count toggle: enable_aks = false → not created (saves ~$100/month)
#
# 🎓 DEV vs PROD differences (controlled by variables):
#    Dev:  1 node, Standard_D2s_v3, no auto-scaling   → ~$70/month
#    Prod: 3 nodes, Standard_D4s_v3, auto-scale to 10 → ~$600+/month
#
# 🎓 MODULE SOURCE: infra/modules/aks/
# =============================================================================
module "aks" {
  count  = var.enable_aks ? 1 : 0
  source = "../../modules/aks"

  resource_group_name = azurerm_resource_group.main.name
  cluster_name        = "${var.project_name}-aks-dev"
  location            = var.location
  dns_prefix          = "${var.project_name}-dev" # Used for AKS FQDN: {prefix}.hcp.indonesiacentral.azmk8s.io

  # Networking — reads from Platform layer's subnet (via data source)
  vnet_subnet_id = data.azurerm_subnet.aks.id

  # Scaling — Dev uses fixed small size (no auto-scaling to save cost)
  node_count          = var.aks_node_count      # 1 node for dev (see dev.tfvars)
  vm_size             = var.aks_node_size       # Standard_D2s_v3 (2 vCPU, 8GB)
  enable_auto_scaling = var.enable_auto_scaling # false for dev, true for prod

  # Monitoring — reads from Platform layer's Log Analytics (via data source)
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.platform.id

  tags = module.global_standards.common_tags
}

# =============================================================================
# CONTAINER APPS - Optional (controlled by feature toggle)
# =============================================================================
# 🎓 WHAT IS CONTAINER APPS? Serverless container hosting.
#    Simpler than AKS — you don't manage Kubernetes, just deploy containers.
#    Good for microservices, APIs, background jobs.
#
# 🎓 AKS vs CONTAINER APPS (when to use which?):
#    AKS:            Full control, complex workloads, need kubectl access
#    Container Apps:  Simpler deployment, auto-scaling, no K8s knowledge needed
#
# 🎓 MODULE SOURCE: infra/modules/container-app/
# =============================================================================
module "container_apps" {
  count  = var.enable_container_apps ? 1 : 0
  source = "../../modules/container-app"

  resource_group_name = azurerm_resource_group.main.name
  environment_name    = "${var.project_name}-cae-dev"
  location            = var.location

  # Networking — reads from Platform layer's app-subnet (via data source)
  infrastructure_subnet_id = data.azurerm_subnet.app.id

  # Monitoring — reads from Platform layer's Log Analytics (via data source)
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.platform.id

  tags = module.global_standards.common_tags
}

# =============================================================================
# COSMOS DB - Optional (controlled by feature toggle)
# =============================================================================
# 🎓 WHAT IS COSMOS DB? Globally distributed NoSQL database.
#    Great for apps that need low latency and flexible data structures.
#
# 🎓 DEV vs PROD differences (progressive security):
#    Dev:  public access, periodic backup, single region      → ~$24/month
#    Prod: private endpoint, continuous backup, multi-region   → ~$200+/month
#
# 🎓 NAMING: No hyphens allowed in Cosmos DB account names!
# 🎓 MODULE SOURCE: infra/modules/cosmosdb/
# =============================================================================
module "cosmosdb" {
  count  = var.enable_cosmosdb ? 1 : 0
  source = "../../modules/cosmosdb"

  resource_group_name = azurerm_resource_group.main.name
  account_name        = "${var.project_name}cosmosdev" # No hyphens allowed!
  location            = var.location

  # Feature toggles — Dev uses minimal settings (save cost, easy access)
  enable_automatic_failover       = false                                  # No failover in dev (single region)
  enable_multiple_write_locations = false                                  # Single write region (cheaper)
  public_network_access_enabled   = true                                   # Public access for easy debugging
  backup_type                     = "Periodic"                             # Cheaper than Continuous, OK for dev
  backup_storage_redundancy       = var.cosmosdb_backup_storage_redundancy # "Geo" or "Local" by region

  tags = module.global_standards.common_tags
}

# =============================================================================
# WEB APP - Optional (controlled by feature toggle)
# =============================================================================
# 🎓 WHAT IS APP SERVICE? Azure's managed web hosting platform.
#    Supports .NET, Java, Node.js, Python, PHP, Ruby, Go.
#
# 🎓 SKU TIERS (cost progression):
#    F1 (Free)     → Dev/testing, $0/month, limited features
#    B1 (Basic)    → Dev, ~$13/month, custom domains
#    S1 (Standard) → Staging, ~$73/month, auto-scale, deployment slots
#    P1v3 (Premium)→ Prod, ~$138/month, better perf, VNet integration
#
# 🎓 MODULE SOURCE: infra/modules/webapp/
# =============================================================================
module "webapp" {
  count  = var.enable_webapp ? 1 : 0
  source = "../../modules/webapp"

  resource_group_name = azurerm_resource_group.main.name
  app_name            = "${var.project_name}-app-dev"
  location            = var.location

  # SKU — Dev uses free tier (Prod uses P1v3 premium)
  sku_name = "F1" # Free tier for dev ($0/month)

  tags = module.global_standards.common_tags
}
