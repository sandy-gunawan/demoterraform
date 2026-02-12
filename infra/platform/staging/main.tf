# Platform Layer - Staging Environment
# =============================================================================
# 🎓 STAGING PLATFORM: Tighter security than dev, tests prod-like networking
#
#    ┌────────────────────────────┬───────────┬────────────┐
#    │ Platform Feature            │ Dev        │ Staging      │
#    ├────────────────────────────┼───────────┼────────────┤
#    │ Key Vault purge protection  │ OFF        │ ON           │
#    │ Network ACLs                │ Allow      │ Deny         │
#    │ Log retention               │ 30 days    │ 60 days      │
#    │ Extra subnet (data)         │ NO         │ YES          │
#    │ App NSG source restriction  │ * (any)    │ VNet only    │
#    └────────────────────────────┴───────────┴────────────┘
# =============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.45.0"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
  }
}

provider "azuread" {}

# =============================================================================
# RESOURCE GROUP
# =============================================================================
resource "azurerm_resource_group" "main" {
  name     = "${var.project_name}-platform-rg-staging"
  location = var.location
  tags     = module.global_standards.common_tags
}

# =============================================================================
# GLOBAL STANDARDS
# =============================================================================
module "global_standards" {
  source = "../../global"

  organization_name = var.organization_name
  project_name      = var.project_name
  environment       = "staging"
  location          = var.location
  cost_center       = var.cost_center
  owner_email       = var.owner_email
  repository_url    = var.repository_url
}

# =============================================================================
# NETWORKING - Staging uses 10.2.0.0/16 range
# =============================================================================
# 🎓 STAGING: Extra "data-subnet" + app NSG restricts to VNet only
# =============================================================================
module "networking" {
  source = "../../modules/networking"

  resource_group_name = azurerm_resource_group.main.name
  network_name        = "${var.project_name}-vnet-staging"
  location            = var.location
  address_space       = ["10.2.0.0/16"]

  subnets = {
    "aks-subnet" = {
      address_prefixes  = ["10.2.1.0/24"]
      service_endpoints = ["Microsoft.Sql", "Microsoft.Storage", "Microsoft.KeyVault", "Microsoft.AzureCosmosDB"]
    }
    "app-subnet" = {
      address_prefixes  = ["10.2.2.0/24"]
      service_endpoints = ["Microsoft.Sql", "Microsoft.Storage", "Microsoft.AzureCosmosDB"]
    }
    "data-subnet" = {
      address_prefixes  = ["10.2.3.0/24"]
      service_endpoints = ["Microsoft.Sql", "Microsoft.Storage"]
    }
  }

  network_security_groups = {
    "aks-nsg" = {
      security_rules = {
        "allow-https" = {
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "443"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        }
        "allow-http" = {
          priority                   = 110
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "80"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        }
      }
    }
    "app-nsg" = {
      security_rules = {
        "allow-https" = {
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "443"
          source_address_prefix      = "VirtualNetwork"
          destination_address_prefix = "*"
        }
      }
    }
  }

  subnet_nsg_associations = {
    "aks-subnet" = "aks-nsg"
    "app-subnet" = "app-nsg"
  }

  create_nat_gateway = var.enable_nat_gateway

  tags = module.global_standards.common_tags
}

# =============================================================================
# LOG ANALYTICS - 60 days retention for staging
# =============================================================================
resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.project_name}-logs-staging"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days

  tags = module.global_standards.common_tags
}

# =============================================================================
# KEY VAULT - With purge protection (staging security hardening)
# =============================================================================
module "security" {
  count  = var.enable_key_vault ? 1 : 0
  source = "../../modules/security"

  resource_group_name         = azurerm_resource_group.main.name
  key_vault_name              = "${var.project_name}kvstaging"
  location                    = var.location
  tenant_id                   = var.tenant_id
  purge_protection_enabled    = var.key_vault_purge_protection
  network_acls_default_action = var.network_acl_default_action

  tags = module.global_standards.common_tags
}
