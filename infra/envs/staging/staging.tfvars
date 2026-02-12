# =============================================================================
# STAGING ENVIRONMENT - Application Layer (Test before production)
# =============================================================================
# Philosophy: Add monitoring + basic hardening, still cost-conscious
# Monthly cost estimate: $300-800
#
# ⚠️  PREREQUISITE: Deploy platform layer FIRST!
#    cd infra/platform/staging && terraform apply -var-file="staging.tfvars"
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
cost_center    = "Engineering-Staging"
owner_email    = "devops@contoso.com"
repository_url = "https://dev.azure.com/contoso/terraform-infrastructure"

# -----------------------------------------------------------------------------
# Feature Toggles - What to deploy
# Should match what you'll deploy in prod (for testing)
# -----------------------------------------------------------------------------
enable_aks            = false # Set true if prod will use AKS
enable_container_apps = false # Set true if prod will use Container Apps
enable_webapp         = false # Set true if prod will use Web App
enable_cosmosdb       = false # Set true if prod will use Cosmos DB

# -----------------------------------------------------------------------------
# Monitoring - ENABLED for testing
# -----------------------------------------------------------------------------
enable_application_insights = true # Monitor app performance
enable_diagnostic_settings  = true # Detailed resource logs

# -----------------------------------------------------------------------------
# Scaling - Fixed medium size
# -----------------------------------------------------------------------------
enable_auto_scaling      = false           # Fixed size
enable_geo_redundancy    = false           # Single region OK
enable_continuous_backup = false           # Periodic backup OK
aks_node_count           = 2               # Two nodes for HA testing
aks_node_size            = "Standard_B2ms" # Medium VM
