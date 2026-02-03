# Terraform Backend Configuration for Development Environment
#
# This file configures where Terraform stores its "state" - a record of what
# resources it has created. We store this in Azure Storage so:
# 1. Multiple team members can work together
# 2. State is backed up and secure
# 3. State is locked during operations (prevents conflicts)
#
# SETUP INSTRUCTIONS:
# Before using this, you need to create the storage account:
#
#   # Create resource group for state storage
#   az group create --name terraform-state-rg --location eastus
#
#   # Create storage account (name must be globally unique!)
#   az storage account create \
#     --name tfstatemycompany \
#     --resource-group terraform-state-rg \
#     --location eastus \
#     --sku Standard_LRS
#
#   # Create container
#   az storage container create \
#     --name tfstate \
#     --account-name tfstatemycompany
#
# Then update the storage_account_name below with your actual name.

terraform {
  backend "azurerm" {
    # Resource group containing the storage account
    resource_group_name = "terraform-state-rg"

    # Storage account name (must be globally unique, 3-24 lowercase letters/numbers)
    # TODO: Replace with your actual storage account name
    storage_account_name = "tfstatemycompany"

    # Container name (created in storage account)
    container_name = "tfstate"

    # State file name - unique per environment!
    # This ensures dev, staging, and prod don't share state
    key = "dev.terraform.tfstate"

    # Optional: Use Azure AD authentication instead of access keys
    # use_azuread_auth = true
  }
}
