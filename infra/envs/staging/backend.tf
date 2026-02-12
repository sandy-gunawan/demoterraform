# Terraform Backend Configuration for Staging Environment
#
# This file configures where Terraform stores its "state" for the STAGING environment.
# Uses the same storage account as dev but a DIFFERENT state file.
#
# BACKEND NAMING (MUST match across all environments):
#   Resource Group:    contoso-tfstate-rg
#   Storage Account:   stcontosotfstate001
#   Container:         tfstate
#
# STATE FILE KEYS:
#   dev.terraform.tfstate       <- Dev environment
#   staging.terraform.tfstate   <- THIS file (Staging)
#   prod.terraform.tfstate      <- Production
#   dev-app-crm.tfstate         <- CRM team (Pattern 2)
#   dev-app-ecommerce.tfstate   <- E-commerce team (Pattern 2)

terraform {
  backend "azurerm" {
    resource_group_name  = "contoso-tfstate-rg"
    storage_account_name = "stcontosotfstate001"
    container_name       = "tfstate"

    # DIFFERENT state file for staging!
    key = "staging.terraform.tfstate"

    # Azure AD authentication (more secure than storage keys)
    use_azuread_auth = true
  }
}
