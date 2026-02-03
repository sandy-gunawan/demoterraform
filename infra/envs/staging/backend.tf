# Terraform Backend Configuration for Staging Environment
#
# This file configures where Terraform stores its "state" for the STAGING environment.
# Uses the same storage account as dev but a DIFFERENT state file.
#
# WHY SEPARATE STATE FILES?
# - Dev state: dev.terraform.tfstate
# - Staging state: staging.terraform.tfstate
# - Prod state: prod.terraform.tfstate
#
# This means:
# - Changes to dev don't affect staging or prod
# - You can see what's deployed in each environment
# - Team members can work on different environments simultaneously

terraform {
  backend "azurerm" {
    # Same storage account as dev
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstatemycompany"  # TODO: Replace with your actual name
    container_name       = "tfstate"

    # DIFFERENT state file for staging!
    key = "staging.terraform.tfstate"
  }
}
