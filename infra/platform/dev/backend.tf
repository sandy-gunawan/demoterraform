# Platform Layer - Dev Backend Configuration
# =============================================================================
# 🎓 SEPARATE STATE FILE for platform layer!
#    Platform infra changes don't affect app state files (blast radius isolation).
#
# State file organization:
#   platform-dev.tfstate          ← THIS (Platform layer: VNets, Security)
#   dev.terraform.tfstate         ← Pattern 1 apps (AKS, CosmosDB, WebApp)
#   dev-app-crm.tfstate           ← Pattern 2 CRM
#   dev-app-ecommerce.tfstate     ← Pattern 2 E-commerce
# =============================================================================

terraform {
  backend "azurerm" {
    resource_group_name  = "contoso-tfstate-rg"
    storage_account_name = "stcontosotfstate001"
    container_name       = "tfstate"
    key                  = "platform-dev.tfstate" # ← Platform layer's own state!
    use_azuread_auth     = true
  }
}
