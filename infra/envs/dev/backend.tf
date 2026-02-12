# Terraform Backend Configuration for Development Environment
#
# This file configures where Terraform stores its "state" - a record of what
# resources it has created. We store this in Azure Storage so:
# 1. Multiple team members can work together
# 2. State is backed up and secure
# 3. State is locked during operations (prevents conflicts)
#
# =============================================================================
# ⚠️ IMPORTANT: This is the SAME storage account used by ALL teams!
# Platform team creates this storage account ONCE (see scripts/init-backend.ps1)
# Then Pattern 1 and Pattern 2 teams ALL point to it, with different state keys.
#
# State files in this storage:
#   dev.terraform.tfstate     ← Pattern 1 (this file)
#   dev-app-crm.tfstate       ← Pattern 2 CRM team
#   dev-app-ecommerce.tfstate ← Pattern 2 E-commerce team
# =============================================================================
#
# SETUP INSTRUCTIONS (Platform team runs this ONCE):
#
#   # Create resource group for state storage
#   az group create --name contoso-tfstate-rg --location indonesiacentral
#
#   # Create storage account (name must be globally unique!)
#   az storage account create \
#     --name stcontosotfstate001 \
#     --resource-group contoso-tfstate-rg \
#     --location indonesiacentral \
#     --sku Standard_GRS
#
#   # Create container
#   az storage container create \
#     --name tfstate \
#     --account-name stcontosotfstate001
#
# Or use the script: scripts/init-backend.ps1

terraform {
  backend "azurerm" {
    # 🎓 NEWBIE NOTE: ALL teams use the SAME storage account!
    # Only the "key" is different per team (like different files in the same folder)
    resource_group_name  = "contoso-tfstate-rg"
    storage_account_name = "stcontosotfstate001"
    container_name       = "tfstate"

    # State file name - unique per environment!
    key = "dev.terraform.tfstate"

    # Use Azure AD authentication (more secure than access keys)
    use_azuread_auth = true
  }
}
