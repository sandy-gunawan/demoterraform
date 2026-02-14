# =============================================================================
# PLATFORM LAYER - Development Environment Values
# =============================================================================
# Philosophy: Simple networking, no expensive security features
# =============================================================================

organization_name = "contoso"
project_name      = "contoso"
environment       = "dev"
location          = "indonesiacentral"

# Azure AD Configuration
subscription_id = "5a7c13bd-9a15-4380-ba67-4d972838bc0b" # Azure subscription ID (az account show --query id -o tsv)
tenant_id = "020201e2-0ae9-446c-8981-55a2bdecc00d" # Azure AD tenant ID (az account show --query tenantId -o tsv)

# Governance
cost_center    = "Engineering-Dev"
owner_email    = "devops@contoso.com"
repository_url = "https://dev.azure.com/contoso/terraform-infrastructure"

# Platform features - Dev: minimal
enable_nat_gateway         = false
enable_key_vault           = true
key_vault_purge_protection = false
network_acl_default_action = "Allow"
log_retention_days         = 30
