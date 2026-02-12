terraform {
  backend "azurerm" {
    resource_group_name  = "contoso-tfstate-rg"
    storage_account_name = "stcontosotfstate001"
    container_name       = "tfstate"
    key                  = "platform-staging.tfstate"
    use_azuread_auth     = true
  }
}
