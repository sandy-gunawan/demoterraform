# ============================================================================
# CRM APPLICATION - DEV ENVIRONMENT
# ============================================================================
# This file contains configuration values for the CRM application
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
workload     = "crm"
location     = "southeastasia" # Singapore - closest to Indonesia

# ----------------------------------------------------------------------------
# Tags (for cost tracking and organization)
# ----------------------------------------------------------------------------

default_tags = {
  Environment = "dev"
  ManagedBy   = "Terraform"
  Team        = "CRM Team"
  TechLead    = "bob.smith@company.com"
  CostCenter  = "CC-5678"
  Application = "Customer Relationship Management"
}

# ----------------------------------------------------------------------------
# App Service Configuration
# ----------------------------------------------------------------------------

# B1 = Basic tier, good for dev (1 core, 1.75 GB RAM)
# S1 = Standard tier for staging (1 core, 1.75 GB RAM, more features)
# P1V2 = Premium tier for prod (1 core, 3.5 GB RAM, autoscale)
app_service_sku = "B1"

# ----------------------------------------------------------------------------
# Cosmos DB Configuration
# ----------------------------------------------------------------------------

# Consistency level (Session = good balance for dev)
cosmos_consistency_level = "Session"

# Allowed IPs (comma-separated, leave empty to allow Azure services only)
cosmos_allowed_ips = ""

# Request Units (RU/s) per container
# Dev: Use 400 RU/s (minimum) to save costs
cosmos_customers_ru    = 400 # Customer records
cosmos_interactions_ru = 400 # Communication history
