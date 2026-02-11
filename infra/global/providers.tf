# Azure Provider Configuration Reference
# =============================================================================
# NOTE: Provider configurations must be defined in root modules (environments),
# NOT in child modules. This file serves as documentation only.
#
# Each environment (dev/staging/prod) defines its own provider block in main.tf.
# The recommended configuration supports both OIDC (Workload Identity Federation)
# and Managed Identity — no secrets required.
#
# Example provider block for root modules:
#
#   provider "azurerm" {
#     features {
#       key_vault {
#         purge_soft_delete_on_destroy    = false
#         recover_soft_deleted_key_vaults = true
#       }
#       resource_group {
#         prevent_deletion_if_contains_resources = true
#       }
#     }
#   }
#
#   provider "azuread" {}
