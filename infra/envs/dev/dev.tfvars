# =============================================================================
# DEVELOPMENT ENVIRONMENT - Keep it simple!
# =============================================================================
# Philosophy: Fast iteration, low cost, no complexity
# Monthly cost estimate: $100-300
# =============================================================================

# -----------------------------------------------------------------------------
# Basic Configuration
# -----------------------------------------------------------------------------
organization_name = "mycompany"
project_name      = "myapp"
location          = "eastus"

# Azure AD Configuration
# Get your tenant ID: az account show --query tenantId -o tsv
tenant_id = "00000000-0000-0000-0000-000000000000"  # TODO: Replace with your tenant ID

# Governance
cost_center    = "Engineering-Dev"
owner_email    = "devops@mycompany.com"
repository_url = "https://dev.azure.com/myorg/terraform-infrastructure"

# -----------------------------------------------------------------------------
# Feature Toggles - What to deploy
# Set to true only what you need for development
# -----------------------------------------------------------------------------
enable_aks            = false  # Set true if you need Kubernetes
enable_container_apps = false  # Set true for simpler container workloads
enable_webapp         = false  # Set true for web app hosting
enable_cosmosdb       = false  # Set true if you need database
enable_key_vault      = true   # Always have secrets management

# -----------------------------------------------------------------------------
# Security Features - ALL DISABLED for dev simplicity
# -----------------------------------------------------------------------------
enable_nat_gateway         = false  # Not needed for dev
enable_private_endpoints   = false  # Public access OK for dev
enable_ddos_protection     = false  # Too expensive for dev
key_vault_purge_protection = false  # Allows easy cleanup in dev
network_acl_default_action = "Allow"  # Open access for dev

# -----------------------------------------------------------------------------
# Monitoring - Minimal for dev
# -----------------------------------------------------------------------------
enable_application_insights = false  # Optional, adds cost
enable_diagnostic_settings  = false  # Keep it simple
log_retention_days          = 30     # Minimum retention

# -----------------------------------------------------------------------------
# Scaling - Fixed small size for dev
# -----------------------------------------------------------------------------
enable_auto_scaling     = false  # Fixed size
enable_geo_redundancy   = false  # Single region OK
enable_continuous_backup = false  # Periodic backup OK
aks_node_count          = 1       # Single node
aks_node_size           = "Standard_B2s"  # Small/cheap VM
