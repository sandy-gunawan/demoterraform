# Terraform Backend Configuration for Production Environment
#
# This file configures where Terraform stores its "state" for the PRODUCTION environment.
#
# PRODUCTION BEST PRACTICES:
# 1. State file is separate from dev/staging (prod.terraform.tfstate)
# 2. Consider using a separate storage account for prod state
# 3. Enable soft delete on storage account (recover accidentally deleted state)
# 4. Restrict access to the storage account (limit who can modify prod)
# 5. Enable storage account firewall (only allow Azure DevOps/CI-CD)
#
# BACKEND NAMING (MUST match across all environments):
#   Resource Group:    contoso-tfstate-rg
#   Storage Account:   stcontosotfstate001
#   Container:         tfstate
#
# STATE FILE KEYS:
#   dev.terraform.tfstate       <- Dev environment
#   staging.terraform.tfstate   <- Staging environment
#   prod.terraform.tfstate      <- THIS file (Production)
#   dev-app-crm.tfstate         <- CRM team (Pattern 2)
#   dev-app-ecommerce.tfstate   <- E-commerce team (Pattern 2)

terraform {
  backend "azurerm" {
    resource_group_name  = "contoso-tfstate-rg"
    storage_account_name = "stcontosotfstate001"
    container_name       = "tfstate"

    # DIFFERENT state file for production!
    key = "prod.terraform.tfstate"

    # Azure AD authentication (more secure than storage keys)
    use_azuread_auth = true
  }
}
