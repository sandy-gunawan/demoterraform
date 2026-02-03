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
# OPTIONAL: Separate Storage Account for Production
# For extra security, you can use a different storage account for production:
#
#   az storage account create \
#     --name tfstateprodmycompany \
#     --resource-group terraform-state-rg \
#     --location eastus \
#     --sku Standard_GRS \    # Geo-redundant for production!
#     --allow-blob-public-access false
#
#   # Enable soft delete (recover deleted state)
#   az storage blob service-properties delete-policy update \
#     --account-name tfstateprodmycompany \
#     --enable true \
#     --days-retained 30

terraform {
  backend "azurerm" {
    # Same storage account (or use separate for production)
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstatemycompany"  # TODO: Replace with your actual name
    container_name       = "tfstate"

    # DIFFERENT state file for production!
    key = "prod.terraform.tfstate"

    # Recommended for production: Use Azure AD authentication
    # (instead of storage account access keys)
    # use_azuread_auth = true
  }
}
