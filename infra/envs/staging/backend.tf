# Terraform Backend Configuration for Staging Environment (Application Layer)
#
# This file configures where Terraform stores its "state" for the STAGING environment.
# Uses the same storage account as dev but a DIFFERENT state file.
#
# STATE FILE KEYS (Layered Infrastructure):
#   Layer 1 - Platform:
#     platform-staging.tfstate     <- Platform layer (infra/platform/staging/)
#   Layer 2 - Applications:
#     staging.terraform.tfstate    <- THIS file (Pattern 1 apps)
#
# ⚠️  PREREQUISITE: Deploy platform layer FIRST!
#    cd infra/platform/staging && terraform apply -var-file="staging.tfvars"

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
