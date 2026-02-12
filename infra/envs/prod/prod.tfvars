# =============================================================================
# PRODUCTION ENVIRONMENT - Full security & reliability
# =============================================================================
# Philosophy: Maximum security, high availability, compliance-ready
# Monthly cost estimate: $2,000-8,000+
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
cost_center    = "Engineering-Production"
owner_email    = "devops@mycompany.com"
repository_url = "https://dev.azure.com/myorg/terraform-infrastructure"

# -----------------------------------------------------------------------------
# Feature Toggles - What to deploy
# Enable what your application needs
# -----------------------------------------------------------------------------
enable_aks            = true   # Kubernetes cluster
enable_container_apps = false  # Alternative to AKS (pick one)
enable_webapp         = false  # If you need App Service
enable_cosmosdb       = true   # Database
enable_key_vault      = true   # Secrets management (always)

# -----------------------------------------------------------------------------
# Security Features - ALL ENABLED
# Production requires maximum security
# -----------------------------------------------------------------------------
enable_nat_gateway         = true   # Control outbound traffic
enable_private_endpoints   = true   # No public access to data
enable_ddos_protection     = true   # Protect against DDoS attacks
key_vault_purge_protection = true   # Prevent accidental secret deletion
network_acl_default_action = "Deny" # Deny all, whitelist allowed

# -----------------------------------------------------------------------------
# Monitoring - FULL monitoring
# Need complete visibility in production
# -----------------------------------------------------------------------------
enable_application_insights = true  # App performance monitoring
enable_diagnostic_settings  = true  # All resource logs
log_retention_days          = 90    # 3 months (increase for compliance)

# -----------------------------------------------------------------------------
# Scaling & Reliability - FULL HA
# Production needs to handle load and recover from failures
# -----------------------------------------------------------------------------
enable_auto_scaling      = true   # Scale based on demand
enable_geo_redundancy    = true   # Data replicated to another region
enable_continuous_backup = true   # Point-in-time recovery
aks_node_count           = 3      # Minimum 3 nodes for HA
aks_max_node_count       = 10     # Auto-scale up to 10
aks_node_size            = "Standard_D4s_v3"  # Production-grade (4 vCPU, 16GB RAM) - Available in SE Asia
