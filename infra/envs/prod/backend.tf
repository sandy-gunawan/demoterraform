# Terraform Backend Configuration for Production Environment (Application Layer)
#
# PRODUCTION BEST PRACTICES:
# 1. State file is separate from dev/staging (prod.terraform.tfstate)
# 2. Consider using a separate storage account for prod state
# 3. Enable soft delete on storage account (recover accidentally deleted state)
#
# STATE FILE KEYS (Layered Infrastructure):
#   Layer 1 - Platform:
#     platform-prod.tfstate       <- Platform layer (infra/platform/prod/)
#   Layer 2 - Applications:
#     prod.terraform.tfstate      <- THIS file (Production apps)
#
# ⚠️  PREREQUISITE: Deploy platform layer FIRST!
#    cd infra/platform/prod && terraform apply -var-file="prod.tfvars"

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
