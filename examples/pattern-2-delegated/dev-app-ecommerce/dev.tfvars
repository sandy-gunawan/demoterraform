# ============================================================================
# E-COMMERCE APPLICATION - DEV ENVIRONMENT
# ============================================================================
# This file contains configuration values for the e-commerce application
# in the dev environment.
#
# HOW TO USE:
# terraform plan -var-file="dev.tfvars"
# terraform apply -var-file="dev.tfvars"
# ============================================================================

# ----------------------------------------------------------------------------
# Core Configuration
# ----------------------------------------------------------------------------

company_name = "contoso"
environment  = "dev"
workload     = "ecommerce"
location     = "eastus"

# ----------------------------------------------------------------------------
# Tags (for cost tracking and organization)
# ----------------------------------------------------------------------------

default_tags = {
  Environment = "dev"
  ManagedBy   = "Terraform"
  Team        = "E-commerce Team"
  TechLead    = "jane.doe@company.com"
  CostCenter  = "CC-1234"
  Application = "Product Catalog & Shopping Cart API"
}

# ----------------------------------------------------------------------------
# AKS Configuration
# ----------------------------------------------------------------------------

# Use shared AKS cluster (recommended for dev to save costs)
use_shared_aks = true

# If using dedicated AKS, configure these:
kubernetes_version = "1.28"
aks_node_count     = 2
aks_vm_size        = "Standard_D2s_v3"  # 2 vCPU, 8GB RAM

# ----------------------------------------------------------------------------
# Cosmos DB Configuration
# ----------------------------------------------------------------------------

# Consistency level (Session = good balance for dev)
cosmos_consistency_level = "Session"

# Allowed IPs (comma-separated, leave empty to allow Azure services only)
# Example: "1.2.3.4,5.6.7.8"
cosmos_allowed_ips = ""

# Request Units (RU/s) per container
# Dev: Use 400 RU/s (minimum) to save costs
# Staging: 1000 RU/s
# Prod: 4000+ RU/s (autoscale)

cosmos_products_ru  = 400  # Product catalog
cosmos_orders_ru    = 400  # Order history
cosmos_inventory_ru = 400  # Stock levels
