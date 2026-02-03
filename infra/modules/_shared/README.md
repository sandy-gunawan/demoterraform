# Shared Module - Naming Conventions
#
# This folder contains shared configurations used across all modules.
#
# ## Files
#
# - **naming.tf** - Centralized naming convention for all Azure resources
#
# ## How to Use
#
# In your environment (dev/staging/prod), reference this module:
#
# ```hcl
# module "naming" {
#   source = "../../modules/_shared"
#
#   project_name = var.project_name
#   environment  = var.environment
#   location     = var.location
# }
#
# # Then use the names in your resources:
# resource "azurerm_resource_group" "main" {
#   name     = module.naming.resource_names.resource_group
#   location = var.location
# }
#
# resource "azurerm_key_vault" "main" {
#   name = module.naming.resource_names_no_hyphen.key_vault
#   # ...
# }
# ```
#
# ## Naming Pattern
#
# Standard resources: `{project}-{env}-{type}-{region}`
# - Example: `myapp-dev-aks-eus`
#
# Storage/Key Vault (no hyphens): `{project}{env}{type}{region}`
# - Example: `myappdevkveus`
#
# ## Why This Exists
#
# 1. **Consistency** - All resources follow the same pattern
# 2. **Compliance** - Handles Azure naming rules automatically
# 3. **Predictability** - You always know what a resource is called
# 4. **Length limits** - Automatically truncates names that are too long
