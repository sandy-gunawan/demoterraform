# Platform Layer - Production Environment
# =============================================================================
# 🎓 PRODUCTION PLATFORM: Maximum security, full networking features
#
#    ┌────────────────────────────┬─────────┬───────────┬─────────────┐
#    │ Platform Feature            │ Dev     │ Staging   │ Prod          │
#    ├────────────────────────────┼─────────┼───────────┼─────────────┤
#    │ NAT Gateway                 │ OFF     │ OFF       │ ON            │
#    │ DDoS Protection             │ OFF     │ OFF       │ ON            │
#    │ Private Endpoint subnet     │ NO      │ NO        │ YES           │
#    │ NSG deny-all-inbound rule   │ NO      │ NO        │ YES           │
#    │ Key Vault purge protection  │ OFF     │ ON        │ ON            │
#    │ Network ACLs                │ Allow   │ Deny      │ Deny          │
#    │ Log retention               │ 30 days │ 60 days   │ 90 days       │
#    │ AKS subnet size              │ /24     │ /24       │ /23 (larger)  │
#    └────────────────────────────┴─────────┴───────────┴─────────────┘
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
  name     = "${var.project_name}-platform-rg-prod"
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
  environment       = "prod"
  location          = var.location
  cost_center       = var.cost_center
  owner_email       = var.owner_email
  repository_url    = var.repository_url
}

# =============================================================================
# NETWORKING - Production: NAT Gateway, deny-all NSGs, PE subnet, larger AKS
# =============================================================================
module "networking" {
  source = "../../modules/networking"

  resource_group_name = azurerm_resource_group.main.name
  network_name        = "${var.project_name}-vnet-prod"
  location            = var.location
  address_space       = ["10.3.0.0/16"]

  subnets = {
    "aks-subnet" = {
      address_prefixes  = ["10.3.1.0/23"] # /23 = 510 IPs for production scale
      service_endpoints = ["Microsoft.Sql", "Microsoft.Storage", "Microsoft.KeyVault", "Microsoft.AzureCosmosDB"]
    }
    "app-subnet" = {
      address_prefixes  = ["10.3.3.0/24"]
      service_endpoints = ["Microsoft.Sql", "Microsoft.Storage", "Microsoft.AzureCosmosDB"]
    }
    "data-subnet" = {
      address_prefixes  = ["10.3.4.0/24"]
      service_endpoints = ["Microsoft.Sql", "Microsoft.Storage"]
    }
    "pe-subnet" = {
      address_prefixes  = ["10.3.5.0/24"] # For private endpoints
      service_endpoints = []
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
        "deny-all-inbound" = {
          priority                   = 4096
          direction                  = "Inbound"
          access                     = "Deny"
          protocol                   = "*"
          source_port_range          = "*"
          destination_port_range     = "*"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        }
      }
    }
    "app-nsg" = {
      security_rules = {
        "allow-https-from-vnet" = {
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "443"
          source_address_prefix      = "VirtualNetwork"
          destination_address_prefix = "*"
        }
        "deny-all-inbound" = {
          priority                   = 4096
          direction                  = "Inbound"
          access                     = "Deny"
          protocol                   = "*"
          source_port_range          = "*"
          destination_port_range     = "*"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        }
      }
    }
    "data-nsg" = {
      security_rules = {
        "allow-sql-from-app" = {
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "1433"
          source_address_prefix      = "10.3.3.0/24"
          destination_address_prefix = "*"
        }
        "deny-all-inbound" = {
          priority                   = 4096
          direction                  = "Inbound"
          access                     = "Deny"
          protocol                   = "*"
          source_port_range          = "*"
          destination_port_range     = "*"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        }
      }
    }
  }

  subnet_nsg_associations = {
    "aks-subnet"  = "aks-nsg"
    "app-subnet"  = "app-nsg"
    "data-subnet" = "data-nsg"
  }

  create_nat_gateway = var.enable_nat_gateway

  tags = module.global_standards.common_tags
}

# =============================================================================
# LOG ANALYTICS - 90 days retention
# =============================================================================
resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.project_name}-logs-prod"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days

  tags = module.global_standards.common_tags
}

# =============================================================================
# KEY VAULT - Full security + private endpoint
# =============================================================================
module "security" {
  count  = var.enable_key_vault ? 1 : 0
  source = "../../modules/security"

  resource_group_name         = azurerm_resource_group.main.name
  key_vault_name              = "${var.project_name}kvprod"
  location                    = var.location
  tenant_id                   = var.tenant_id
  purge_protection_enabled    = var.key_vault_purge_protection
  network_acls_default_action = var.network_acl_default_action

  enable_private_endpoint    = var.enable_private_endpoints
  private_endpoint_subnet_id = var.enable_private_endpoints ? module.networking.subnet_ids["pe-subnet"] : null
  vnet_id                    = module.networking.vnet_id

  tags = module.global_standards.common_tags
}

# =============================================================================
# DDOS PROTECTION PLAN - Production only (~$2,944/month)
# =============================================================================
resource "azurerm_network_ddos_protection_plan" "main" {
  count = var.enable_ddos_protection ? 1 : 0

  name                = "${var.project_name}-ddos-prod"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  tags = module.global_standards.common_tags
}
