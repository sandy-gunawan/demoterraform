# =============================================================================
# DEVELOPMENT ENVIRONMENT - Application Layer (Keep it simple!)
# =============================================================================
# Philosophy: Fast iteration, low cost, no complexity
# Monthly cost estimate: $100-300
#
# ⚠️  PREREQUISITE: Deploy platform layer FIRST!
#    cd infra/platform/dev && terraform apply -var-file="dev.tfvars"
# =============================================================================

# -----------------------------------------------------------------------------
# Basic Configuration
# -----------------------------------------------------------------------------
organization_name = "contoso"
project_name      = "contoso"
environment       = "dev"
location          = "indonesiacentral" # Jakarta - Indonesia datacenter region

# Azure AD Configuration
# Get your tenant ID: az account show --query tenantId -o tsv
tenant_id = "00000000-0000-0000-0000-000000000000" # TODO: Replace with your tenant ID

# Governance
cost_center    = "Engineering-Dev"
owner_email    = "devops@contoso.com"
repository_url = "https://dev.azure.com/contoso/terraform-infrastructure"

# -----------------------------------------------------------------------------
# Feature Toggles - What to deploy
# Set to true only what you need for development
# -----------------------------------------------------------------------------
enable_aks            = false # Set true if you need Kubernetes
enable_container_apps = false # Set true for simpler container workloads
enable_webapp         = false # Set true for web app hosting
enable_cosmosdb       = false # Set true if you need database

# -----------------------------------------------------------------------------
# Monitoring - Minimal for dev
# -----------------------------------------------------------------------------
enable_application_insights = false # Optional, adds cost
enable_diagnostic_settings  = false # Keep it simple

# -----------------------------------------------------------------------------
# Scaling - Fixed small size for dev
# -----------------------------------------------------------------------------
enable_auto_scaling      = false             # Fixed size
enable_geo_redundancy    = false             # Single region OK
enable_continuous_backup = false             # Periodic backup OK
aks_node_count           = 1                 # Single node
aks_node_size            = "Standard_D2s_v3" # Minimal but functional (2 vCPU, 8GB RAM) - Available in SE Asia
