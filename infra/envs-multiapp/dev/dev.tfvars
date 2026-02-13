organization_name = "contoso"
project_name      = "contoso"
environment       = "dev"
location          = "indonesiacentral"

cost_center    = "Engineering-Dev"
owner_email    = "devops@contoso.com"
repository_url = "https://dev.azure.com/contoso/terraform-infrastructure"

aks_node_count      = 1
aks_node_size       = "Standard_D2s_v3"
enable_auto_scaling = false

cosmosdb_backup_storage_redundancy = "Local"

# Multi-team toggles in one central root module
# Example: first onboarding Ecommerce only
enable_ecommerce_aks      = true
enable_ecommerce_cosmosdb = true
enable_crm_aks            = false
enable_crm_cosmosdb       = false
