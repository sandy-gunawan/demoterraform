# =============================================================================
# PRODUCTION ENVIRONMENT - Application Layer (Full security & reliability)
# =============================================================================
# Philosophy: Maximum security, high availability, compliance-ready
# Monthly cost estimate: $2,000-8,000+
#
# ⚠️  PREREQUISITE: Deploy platform layer FIRST!
#    cd infra/platform/prod && terraform apply -var-file="prod.tfvars"
# =============================================================================

# -----------------------------------------------------------------------------
# Basic Configuration
# -----------------------------------------------------------------------------
organization_name = "contoso"
project_name      = "contoso"
location          = "indonesiacentral" # Jakarta - Indonesia datacenter region

# Azure AD Configuration
tenant_id = "00000000-0000-0000-0000-000000000000" # TODO: Replace with your tenant ID

# Governance
cost_center    = "Engineering-Production"
owner_email    = "devops@contoso.com"
repository_url = "https://dev.azure.com/contoso/terraform-infrastructure"

# -----------------------------------------------------------------------------
# Feature Toggles - What to deploy
# Enable what your application needs
# -----------------------------------------------------------------------------
enable_aks            = true  # Kubernetes cluster
enable_container_apps = false # Alternative to AKS (pick one)
enable_webapp         = false # If you need App Service
enable_cosmosdb       = true  # Database

# -----------------------------------------------------------------------------
# Monitoring - FULL monitoring
# Need complete visibility in production
# -----------------------------------------------------------------------------
enable_application_insights = true # App performance monitoring
enable_diagnostic_settings  = true # All resource logs

# -----------------------------------------------------------------------------
# Scaling & Reliability - FULL HA
# Production needs to handle load and recover from failures
# -----------------------------------------------------------------------------
enable_auto_scaling      = true              # Scale based on demand
enable_geo_redundancy    = true              # Data replicated to another region
enable_continuous_backup = true              # Point-in-time recovery
aks_node_count           = 3                 # Minimum 3 nodes for HA
aks_max_node_count       = 10                # Auto-scale up to 10
aks_node_size            = "Standard_D4s_v3" # Production-grade (4 vCPU, 16GB RAM) - Available in SE Asia
