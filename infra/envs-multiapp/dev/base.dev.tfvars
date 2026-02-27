organization_name = "contoso"
project_name      = "contoso"
environment       = "dev"
location          = "indonesiacentral"

# Azure authentication context (recommended)
subscription_id = "xxxxxxxxxxxxxxxxxxxxxxx" # Replace with your Azure subscription ID
tenant_id       = "xxxxxxxxxxxxxxxxxxxxxx" # Replace with your Azure tenant ID

cost_center    = "Engineering-Dev"
owner_email    = "devops@contoso.com"
repository_url = "https://dev.azure.com/contoso/terraform-infrastructure"

aks_node_count      = 1
aks_node_size       = "Standard_D2s_v3"
enable_auto_scaling = false

cosmosdb_backup_storage_redundancy = "Local"

# Base defaults: all app toggles OFF
enable_ecommerce_aks      = false
enable_ecommerce_cosmosdb = false
enable_crm_aks            = false
enable_crm_cosmosdb       = false
