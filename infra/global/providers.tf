# Azure Provider Configuration
# Supports both OIDC (Workload Identity Federation) and Managed Identity
# No secrets required - modern authentication only

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
    
    resource_group {
      prevent_deletion_if_contains_resources = true
    }

    virtual_machine {
      delete_os_disk_on_deletion     = true
      graceful_shutdown              = false
      skip_shutdown_and_force_delete = false
    }
  }

  # When running in Azure DevOps with OIDC, these are automatically configured
  # use_oidc = true
  # client_id = var.client_id
  # subscription_id = var.subscription_id
  # tenant_id = var.tenant_id
}

provider "azuread" {
  # Automatically uses the same credentials as azurerm
  # tenant_id = var.tenant_id
}
