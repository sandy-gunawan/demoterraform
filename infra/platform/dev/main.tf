# Platform Layer - Development Environment
# =============================================================================
# 🎓 WHAT IS THE PLATFORM LAYER?
#    This is the "foundation" that ALL app teams build on top of.
#    Platform team controls: VNets, Security, Global Standards, Monitoring
#    App teams consume: VNets (via data sources), tags (via global module)
#
# 🎓 LAYERED INFRASTRUCTURE (Industry Best Practice):
#    ┌─────────────────────────────────────────────────────────────────┐
#    │ Layer 0: Bootstrap (scripts/init-backend.ps1) — run ONCE       │
#    │          Creates: Storage account for Terraform state           │
#    ├─────────────────────────────────────────────────────────────────┤
#    │ Layer 1: Platform (THIS FILE) — managed by Platform team        │
#    │          Creates: VNets, Security, Log Analytics, Global Tags    │
#    │          State: platform-dev.tfstate                             │
#    ├─────────────────────────────────────────────────────────────────┤
#    │ Layer 2: Applications — managed by App teams                     │
#    │          Pattern 1: infra/envs/dev/ (AKS, CosmosDB, WebApp)     │
#    │          Pattern 2: examples/pattern-2-delegated/dev-app-crm/   │
#    │          Pattern 2: examples/pattern-2-delegated/dev-app-ecom/  │
#    │          All read VNets from Layer 1 via data sources            │
#    └─────────────────────────────────────────────────────────────────┘
#
# 🎓 WHY SEPARATE PLATFORM LAYER?
#    1. Blast radius: If an app deployment fails, VNets are safe
#    2. Permissions: Platform team locks down networking, app teams can't touch it
#    3. Independence: App teams deploy independently (Pattern 1 & 2 are symmetric)
#    4. CI/CD: Platform pipeline vs App pipeline (different approval flows)
#
# 🎓 DEPLOY ORDER:
#    Step 1: cd infra/platform/dev && terraform apply -var-file="dev.tfvars"
#    Step 2: cd infra/envs/dev && terraform apply -var-file="dev.tfvars"
#       OR:  cd examples/pattern-2-delegated/dev-app-crm && terraform apply
#    (Step 2s can run in parallel — they only READ from platform layer)
#
# 🎓 IP ADDRESS PLAN (3 VNets, non-overlapping ranges):
#    ┌─────────────────┬─────────────────┬─────────────────────────────────┐
#    │ VNet             │ Address Range   │ WHO uses it?                    │
#    ├─────────────────┼─────────────────┼─────────────────────────────────┤
#    │ Platform Shared  │ 10.1.0.0/16     │ Pattern 1: AKS, Container Apps  │
#    │ CRM Team         │ 10.2.0.0/16     │ Pattern 2: CRM App Service      │
#    │ E-commerce Team  │ 10.3.0.0/16     │ Pattern 2: E-commerce AKS       │
#    └─────────────────┴─────────────────┴─────────────────────────────────┘
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

# =============================================================================
# PROVIDER CONFIGURATION
# =============================================================================
provider "azurerm" {
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id

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

provider "azuread" {
  tenant_id = var.tenant_id
}

# =============================================================================
# RESOURCE GROUP - Platform team's resource group
# =============================================================================
# 🎓 This resource group holds ALL platform-managed resources:
#    VNets, NSGs, Log Analytics, Key Vault, etc.
#    App teams have their OWN resource groups (see Layer 2).
# =============================================================================
resource "azurerm_resource_group" "main" {
  name     = "contoso-platform-rg-${var.environment}"
  location = var.location
  tags     = module.global_standards.common_tags
}

# =============================================================================
# GLOBAL STANDARDS - Naming, tagging (source of truth for ALL teams)
# =============================================================================
# 🎓 WHO USES THIS?
#    - This file (Platform layer) — directly via module.global_standards.common_tags
#    - App teams (Pattern 1 & 2) — they call the SAME module in their configs
#    This ensures ALL resources across ALL teams have consistent tags.
# =============================================================================
module "global_standards" {
  source = "../../global"

  organization_name = var.organization_name
  project_name      = var.project_name
  environment       = var.environment
  location          = var.location
  cost_center       = var.cost_center
  owner_email       = var.owner_email
  repository_url    = var.repository_url
}

# =============================================================================
# NETWORKING - Platform Shared VNet (10.1.0.0/16)
# =============================================================================
# 🎓 Used by Pattern 1 apps (AKS, Container Apps, WebApp)
#    App teams read this VNet via data sources in their configs.
# =============================================================================
module "networking" {
  source = "../../modules/networking"

  resource_group_name = azurerm_resource_group.main.name
  network_name        = "vnet-${var.project_name}-${var.environment}-001"
  location            = var.location
  address_space       = ["10.1.0.0/16"]

  subnets = {
    "aks-subnet" = {
      address_prefixes  = ["10.1.1.0/24"]
      service_endpoints = ["Microsoft.Sql", "Microsoft.Storage", "Microsoft.KeyVault"]
    }
    "app-subnet" = {
      address_prefixes  = ["10.1.2.0/24"]
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
      }
    }
  }

  subnet_nsg_associations = {
    "aks-subnet" = "aks-nsg"
  }

  create_nat_gateway = var.enable_nat_gateway

  tags = module.global_standards.common_tags
}

# =============================================================================
# CRM Team's Dedicated VNet (10.2.0.0/16) - Pattern 2
# =============================================================================
# 🎓 Platform creates this VNet FOR the CRM team.
#    CRM team reads it via: data "azurerm_virtual_network" "crm" { ... }
#    in examples/pattern-2-delegated/dev-app-crm/main.tf
# =============================================================================
module "networking_crm" {
  source = "../../modules/networking"

  resource_group_name = azurerm_resource_group.main.name
  network_name        = "vnet-${var.project_name}-${var.environment}-crm-001"
  location            = var.location
  address_space       = ["10.2.0.0/16"]

  subnets = {
    "crm-app-subnet" = {
      address_prefixes  = ["10.2.1.0/24"]
      service_endpoints = ["Microsoft.Web", "Microsoft.AzureCosmosDB", "Microsoft.KeyVault"]
    }
    "crm-db-subnet" = {
      address_prefixes  = ["10.2.2.0/24"]
      service_endpoints = ["Microsoft.AzureCosmosDB"]
    }
  }

  network_security_groups = {
    "crm-app-nsg" = {
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
  }

  subnet_nsg_associations = {
    "crm-app-subnet" = "crm-app-nsg"
  }

  tags = merge(module.global_standards.common_tags, {
    Team    = "CRM"
    Pattern = "Pattern2"
  })
}

# =============================================================================
# E-commerce Team's Dedicated VNet (10.3.0.0/16) - Pattern 2
# =============================================================================
# 🎓 Platform creates this VNet FOR the E-commerce team.
#    E-commerce team reads it via: data "azurerm_virtual_network" "ecommerce" { ... }
#    in examples/pattern-2-delegated/dev-app-ecommerce/main.tf
# =============================================================================
module "networking_ecommerce" {
  source = "../../modules/networking"

  resource_group_name = azurerm_resource_group.main.name
  network_name        = "vnet-${var.project_name}-${var.environment}-ecommerce-001"
  location            = var.location
  address_space       = ["10.3.0.0/16"]

  subnets = {
    "ecom-aks-subnet" = {
      address_prefixes  = ["10.3.1.0/24"]
      service_endpoints = ["Microsoft.ContainerRegistry", "Microsoft.AzureCosmosDB"]
    }
    "ecom-db-subnet" = {
      address_prefixes  = ["10.3.2.0/24"]
      service_endpoints = ["Microsoft.AzureCosmosDB"]
    }
  }

  network_security_groups = {
    "ecom-aks-nsg" = {
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
  }

  subnet_nsg_associations = {
    "ecom-aks-subnet" = "ecom-aks-nsg"
  }

  tags = merge(module.global_standards.common_tags, {
    Team    = "E-commerce"
    Pattern = "Pattern2"
  })
}

# =============================================================================
# LOG ANALYTICS - Central monitoring hub
# =============================================================================
# 🎓 ALL app teams can send their logs here.
#    App teams reference this workspace ID via data sources.
# =============================================================================
resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.project_name}-logs-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days

  tags = module.global_standards.common_tags
}

# =============================================================================
# KEY VAULT - Platform-level secrets (optional)
# =============================================================================
module "security" {
  count  = var.enable_key_vault ? 1 : 0
  source = "../../modules/security"

  resource_group_name         = azurerm_resource_group.main.name
  key_vault_name              = "${var.project_name}kvdev"
  location                    = var.location
  tenant_id                   = var.tenant_id
  purge_protection_enabled    = var.key_vault_purge_protection
  network_acls_default_action = var.network_acl_default_action

  tags = module.global_standards.common_tags
}
