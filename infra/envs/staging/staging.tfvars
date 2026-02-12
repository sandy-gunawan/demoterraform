# =============================================================================
# STAGING ENVIRONMENT - Test before production
# =============================================================================
# Philosophy: Add monitoring + basic hardening, still cost-conscious
# Monthly cost estimate: $300-800
# =============================================================================

# -----------------------------------------------------------------------------
# Basic Configuration
# -----------------------------------------------------------------------------
organization_name = "mycompany"
project_name      = "myapp"
location          = "southeastasia"  # Singapore - closest full-featured region to Indonesia

# Azure AD Configuration
# Get your tenant ID: az account show --query tenantId -o tsv
tenant_id = "00000000-0000-0000-0000-000000000000"  # TODO: Replace with your tenant ID

# Governance
cost_center    = "Engineering-Staging"
owner_email    = "devops@mycompany.com"
repository_url = "https://dev.azure.com/myorg/terraform-infrastructure"

# -----------------------------------------------------------------------------
# Feature Toggles - What to deploy
# Should match what you'll deploy in prod (for testing)
# -----------------------------------------------------------------------------
enable_aks            = false  # Set true if prod will use AKS
enable_container_apps = false  # Set true if prod will use Container Apps
enable_webapp         = false  # Set true if prod will use Web App
enable_cosmosdb       = false  # Set true if prod will use Cosmos DB
enable_key_vault      = true   # Always have secrets management

# -----------------------------------------------------------------------------
# Security Features - BASIC HARDENING
# Tighter than dev, but not full prod security
# -----------------------------------------------------------------------------
enable_nat_gateway         = false   # Not needed yet
enable_private_endpoints   = false   # Not needed yet
enable_ddos_protection     = false   # Too expensive
key_vault_purge_protection = true    # Protect secrets from accidental deletion
network_acl_default_action = "Deny"  # Deny by default, whitelist allowed

# -----------------------------------------------------------------------------
# Monitoring - ENABLED for testing
# Need to see what's happening before prod
# -----------------------------------------------------------------------------
enable_application_insights = true  # Monitor app performance
enable_diagnostic_settings  = true  # Detailed resource logs
log_retention_days          = 60    # 2 months retention

# -----------------------------------------------------------------------------
# Scaling - Fixed medium size
# -----------------------------------------------------------------------------
enable_auto_scaling      = false  # Fixed size
enable_geo_redundancy    = false  # Single region OK
enable_continuous_backup = false  # Periodic backup OK
aks_node_count           = 2      # Two nodes for HA testing
aks_node_size            = "Standard_B2ms"  # Medium VM
