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
subscription_id = "5xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" # Azure subscription ID (az account show --query id -o tsv)
tenant_id = "0xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" # Azure AD tenant ID (az account show --query tenantId -o tsv)

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
