# Development Environment Configuration
# =============================================================================
# ⚠️ IMPORTANT FOR NEWBIES: This file creates infrastructure for BOTH patterns!
#
# What this file does:
# 1. Pattern 1 Resources: Shared AKS, CosmosDB, Log Analytics, etc.
# 2. Pattern 1 VNet: 10.1.0.0/16 (for shared services above)
# 3. Pattern 2 VNets: 10.2.x (CRM) and 10.3.x (E-commerce) <- YES, Platform creates these!
#
# Why Platform creates Pattern 2 VNets?
# - Governance: Platform enforces networking standards (security, naming, IP ranges)
# - Reusability: Same networking module used 3 times (don't reinvent the wheel)
# - Consistency: All VNets follow same patterns
# - Control: Platform team manages all networking, teams focus on apps
#
# Pattern 2 teams DON'T create VNets themselves!
# They READ these VNets using Terraform data sources (see examples/pattern-2-delegated/)
#
# Deploy this FIRST before Pattern 2 teams can deploy their apps!
# =============================================================================
# PHILOSOPHY: Simple, cheap, fast iteration
# - Minimal resources, no expensive security features
# - Everything still works, just simplified
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
# 🎓 WHY PROVIDER? Tells Terraform HOW to talk to Azure.
#    Think of it as "logging in" to Azure for Terraform.
#
# 🎓 WHY FEATURES BLOCK? Safety settings to prevent accidentally destroying
#    important resources. These are the SAME across dev/staging/prod.
# =============================================================================
provider "azurerm" {
  features {
    key_vault {
      # WHY false? Don't permanently delete Key Vault when running "terraform destroy".
      # Key Vault has soft-delete (recoverable for 90 days). We keep it recoverable.
      purge_soft_delete_on_destroy = false
      # WHY true? If someone manually deleted a Key Vault, Terraform can recover it.
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      # WHY true? Prevents "terraform destroy" from deleting a resource group that
      # still has resources inside. Safety net against accidental data loss!
      prevent_deletion_if_contains_resources = true
    }
  }
}

# 🎓 WHY AZUREAD? Some resources (like RBAC, AAD groups for AKS) need
#    to talk to Azure Active Directory. This provider enables that.
provider "azuread" {}

# =============================================================================
# RESOURCE GROUP - Always created (the "folder" for all Platform resources)
# =============================================================================
# 🎓 WHAT IS A RESOURCE GROUP?
#    A logical container for Azure resources (like a folder on your computer).
#    Every Azure resource MUST belong to a resource group.
#
# 🎓 WHO CREATES THIS? Platform team (Pattern 1) creates this ONCE.
# 🎓 WHO USES THIS? All shared resources below (VNets, AKS, CosmosDB, etc.)
# 🎓 NAMING: "contoso-platform-rg-dev" → {company}-platform-rg-{environment}
#    Pattern 2 teams have their OWN resource groups (see examples/pattern-2-delegated/)
# =============================================================================
resource "azurerm_resource_group" "main" {
  name     = "contoso-platform-rg-${var.environment}"
  location = var.location
  tags     = module.global_standards.common_tags
}

# =============================================================================
# GLOBAL STANDARDS - Naming, tagging, etc.
# =============================================================================
# 🎓 WHAT IS THIS MODULE? Centralized naming and tagging rules.
#    SOURCE: infra/global/ (locals.tf, outputs.tf, versions.tf)
#
# 🎓 WHY? Ensures ALL resources across ALL environments have:
#    - Consistent naming (contoso-xxx-dev, contoso-xxx-staging, contoso-xxx-prod)
#    - Standard tags (ManagedBy, Environment, CostCenter, Owner, etc.)
#    - These tags help with: cost tracking, ownership, compliance audits
#
# 🎓 HOW IT'S USED: module.global_standards.common_tags → applied to every resource
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
# NETWORKING - Always created (foundation for everything else)
# =============================================================================
# 🎓 WHAT IS A VNET? A Virtual Network = your private network in Azure.
#    Like building walls around your neighborhood — only your resources
#    can talk to each other inside the VNet.
#
# 🎓 IP ADDRESS PLAN (3 VNets, non-overlapping ranges):
#    ┌─────────────────┬─────────────────┬─────────────────────────────────┐
#    │ VNet             │ Address Range   │ WHO uses it?                    │
#    ├─────────────────┼─────────────────┼─────────────────────────────────┤
#    │ Platform (this)  │ 10.1.0.0/16     │ Shared AKS, CosmosDB, Key Vault │
#    │ CRM Team         │ 10.2.0.0/16     │ CRM App Service, CRM CosmosDB   │
#    │ E-commerce Team  │ 10.3.0.0/16     │ E-com AKS, E-com CosmosDB       │
#    └─────────────────┴─────────────────┴─────────────────────────────────┘
#
# 🎓 WHY NON-OVERLAPPING?
#    If you ever need VNet peering (connecting VNets together), IP ranges
#    MUST NOT overlap. Planning this upfront saves headaches later!
#
# 🎓 MODULE SOURCE: infra/modules/networking/ (reusable VNet + Subnet + NSG module)
#    We use the SAME module 3 times — once per VNet. That's reusability!
# =============================================================================
module "networking" {
  source = "../../modules/networking"

  resource_group_name = azurerm_resource_group.main.name
  network_name        = "vnet-${var.project_name}-${var.environment}-001"
  location            = var.location
  address_space       = ["10.1.0.0/16"] # Platform team's address space

  # 🎓 SUBNETS: Smaller networks INSIDE the VNet (like rooms inside a house).
  # Each subnet isolates a group of resources and can have its own firewall rules (NSGs).
  subnets = {
    "aks-subnet" = {
      address_prefixes = ["10.1.1.0/24"] # 254 usable IPs, enough for AKS nodes
      # WHY service_endpoints? Allows DIRECT connection to Azure services
      # without going through the public internet (faster + more secure)
      service_endpoints = ["Microsoft.Sql", "Microsoft.Storage", "Microsoft.KeyVault"]
    }
    "app-subnet" = {
      address_prefixes  = ["10.1.2.0/24"] # 254 usable IPs for Container Apps
      service_endpoints = ["Microsoft.Sql", "Microsoft.Storage"]
    }
  }

  # 🎓 NSG (Network Security Group): Firewall rules for the subnet.
  # Think of it as a bouncer at the door — decides WHO can enter and leave.
  network_security_groups = {
    "aks-nsg" = {
      security_rules = {
        "allow-https" = {
          priority                   = 100 # Lower number = higher priority (processed first)
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

  # 🎓 FEATURE TOGGLE: var.enable_nat_gateway → Dev: false (save cost), Prod: true
  # NAT Gateway gives all outbound traffic a fixed public IP (useful for whitelisting)
  create_nat_gateway = var.enable_nat_gateway

  tags = module.global_standards.common_tags
}

# =============================================================================
# PATTERN 2 NETWORKING - VNets for Delegated Teams
# =============================================================================
# Platform team creates SEPARATE VNets for Pattern 2 teams.
# This shows framework's governance while providing isolation:
# - Platform controls: IP ranges, security rules, naming standards
# - Teams get: Isolated networks, focus on apps not infrastructure
# - Framework value: Reusable, consistent, governed
#
# Pattern 2 teams use DATA SOURCES to read these VNets (see examples/).
# =============================================================================

# CRM Team's Dedicated VNet (10.2.0.0/16)
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

# E-commerce Team's Dedicated VNet (10.3.0.0/16)
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
# LOG ANALYTICS - Always created (monitoring hub for all resources)
# =============================================================================
# 🎓 WHAT IS LOG ANALYTICS? Azure's central logging service.
#    All resources can send their logs here — like a shared diary.
#
# 🎓 WHY ALWAYS CREATED (no feature toggle)?
#    You ALWAYS need to see what's happening, even in dev.
#    Without logs, troubleshooting is just guessing!
#
# 🎓 WHO SENDS LOGS HERE?
#    - AKS (cluster events, container logs)
#    - Application Insights (app performance, request tracing)
#    - Key Vault (who accessed what secrets, audit trail)
#    - Container Apps (app logs + scaling events)
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
# APPLICATION INSIGHTS - Optional (controlled by feature toggle)
# =============================================================================
# 🎓 FEATURE TOGGLE PATTERN (used throughout this file):
#    count = var.enable_xxx ? 1 : 0
#    → If true:  count=1 → resource IS created (1 instance)
#    → If false: count=0 → resource is NOT created (0 instances)
#    → Access with: azurerm_application_insights.main[0] (note the [0])
#
# 🎓 WHY APP INSIGHTS? Monitors your APP's performance (response times, errors).
#    Different from Log Analytics which monitors INFRASTRUCTURE.
#    Dev: disabled (save $). Staging/Prod: enabled (need visibility).
# =============================================================================
resource "azurerm_application_insights" "main" {
  count = var.enable_application_insights ? 1 : 0

  name                = "${var.project_name}-insights-dev"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"

  tags = module.global_standards.common_tags
}

# =============================================================================
# KEY VAULT - Recommended for all environments (secrets management)
# =============================================================================
# 🎓 WHAT IS KEY VAULT? Secure storage for secrets, keys, and certificates.
#    Like a safe deposit box — only authorized identities can open it.
#
# 🎓 WHY ALWAYS ENABLED (default=true)?
#    Every environment needs a secure place for secrets:
#    - Database connection strings, API keys, certificates
#    - Never store secrets in code or environment variables!
#
# 🎓 PROGRESSIVE SECURITY across environments:
#    Dev:     no purge protection, open network (easy to delete & recreate)
#    Staging: purge protection ON, deny network (test prod-like security)
#    Prod:    purge protection ON, deny network, private endpoint only
#
# 🎓 MODULE SOURCE: infra/modules/security/ (creates Key Vault + optional Private Endpoint)
# =============================================================================
module "security" {
  count  = var.enable_key_vault ? 1 : 0
  source = "../../modules/security"

  resource_group_name = azurerm_resource_group.main.name
  # 🎓 KEY VAULT NAMING: Must be globally unique, 3-24 chars, alphanumeric + hyphens only
  key_vault_name = "${var.project_name}kvdev"
  location       = var.location
  tenant_id      = var.tenant_id

  # Feature toggles
  purge_protection_enabled    = var.key_vault_purge_protection
  network_acls_default_action = var.network_acl_default_action

  tags = module.global_standards.common_tags
}

# =============================================================================
# AKS - Optional (controlled by feature toggle)
# =============================================================================
# 🎓 WHAT IS AKS? Azure Kubernetes Service — managed Kubernetes cluster.
#    Runs containerized applications (Docker) at scale.
#
# 🎓 HOW IT CONNECTS:
#    1. Lives in the "aks-subnet" (10.1.1.0/24) we created above
#    2. Sends logs to Log Analytics workspace (also created above)
#    3. count toggle: enable_aks = false → not created (saves ~$100/month)
#
# 🎓 DEV vs PROD differences (controlled by variables):
#    Dev:  1 node, Standard_D2s_v3, no auto-scaling   → ~$70/month
#    Prod: 3 nodes, Standard_D4s_v3, auto-scale to 10 → ~$600+/month
#
# 🎓 MODULE SOURCE: infra/modules/aks/
# =============================================================================
module "aks" {
  count  = var.enable_aks ? 1 : 0
  source = "../../modules/aks"

  resource_group_name = azurerm_resource_group.main.name
  cluster_name        = "${var.project_name}-aks-dev"
  location            = var.location
  dns_prefix          = "${var.project_name}-dev" # Used for AKS FQDN: {prefix}.hcp.indonesiacentral.azmk8s.io

  # Networking — connects AKS to the "aks-subnet" from module "networking" above
  vnet_subnet_id = module.networking.subnet_ids["aks-subnet"]

  # Scaling — Dev uses fixed small size (no auto-scaling to save cost)
  node_count          = var.aks_node_count      # 1 node for dev (see dev.tfvars)
  vm_size             = var.aks_node_size       # Standard_D2s_v3 (2 vCPU, 8GB)
  enable_auto_scaling = var.enable_auto_scaling # false for dev, true for prod

  # Monitoring — AKS sends container logs + metrics to Log Analytics
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  tags = module.global_standards.common_tags
}

# =============================================================================
# CONTAINER APPS - Optional (controlled by feature toggle)
# =============================================================================
# 🎓 WHAT IS CONTAINER APPS? Serverless container hosting.
#    Simpler than AKS — you don't manage Kubernetes, just deploy containers.
#    Good for microservices, APIs, background jobs.
#
# 🎓 AKS vs CONTAINER APPS (when to use which?):
#    AKS:            Full control, complex workloads, need kubectl access
#    Container Apps:  Simpler deployment, auto-scaling, no K8s knowledge needed
#
# 🎓 MODULE SOURCE: infra/modules/container-app/
# =============================================================================
module "container_apps" {
  count  = var.enable_container_apps ? 1 : 0
  source = "../../modules/container-app"

  resource_group_name = azurerm_resource_group.main.name
  environment_name    = "${var.project_name}-cae-dev"
  location            = var.location

  # Networking — connects to "app-subnet" (10.1.2.0/24) for VNet integration
  infrastructure_subnet_id = module.networking.subnet_ids["app-subnet"]

  # Monitoring — sends container logs + scaling events to Log Analytics
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  tags = module.global_standards.common_tags
}

# =============================================================================
# COSMOS DB - Optional (controlled by feature toggle)
# =============================================================================
# 🎓 WHAT IS COSMOS DB? Globally distributed NoSQL database.
#    Great for apps that need low latency and flexible data structures.
#
# 🎓 DEV vs PROD differences (progressive security):
#    Dev:  public access, periodic backup, single region      → ~$24/month
#    Prod: private endpoint, continuous backup, multi-region   → ~$200+/month
#
# 🎓 NAMING: No hyphens allowed in Cosmos DB account names!
# 🎓 MODULE SOURCE: infra/modules/cosmosdb/
# =============================================================================
module "cosmosdb" {
  count  = var.enable_cosmosdb ? 1 : 0
  source = "../../modules/cosmosdb"

  resource_group_name = azurerm_resource_group.main.name
  account_name        = "${var.project_name}cosmosdev" # No hyphens allowed!
  location            = var.location

  # Feature toggles — Dev uses minimal settings (save cost, easy access)
  enable_automatic_failover       = false                                  # No failover in dev (single region)
  enable_multiple_write_locations = false                                  # Single write region (cheaper)
  public_network_access_enabled   = true                                   # Public access for easy debugging
  backup_type                     = "Periodic"                             # Cheaper than Continuous, OK for dev
  backup_storage_redundancy       = var.cosmosdb_backup_storage_redundancy # "Geo" or "Local" by region

  tags = module.global_standards.common_tags
}

# =============================================================================
# WEB APP - Optional (controlled by feature toggle)
# =============================================================================
# 🎓 WHAT IS APP SERVICE? Azure's managed web hosting platform.
#    Supports .NET, Java, Node.js, Python, PHP, Ruby, Go.
#
# 🎓 SKU TIERS (cost progression):
#    F1 (Free)     → Dev/testing, $0/month, limited features
#    B1 (Basic)    → Dev, ~$13/month, custom domains
#    S1 (Standard) → Staging, ~$73/month, auto-scale, deployment slots
#    P1v3 (Premium)→ Prod, ~$138/month, better perf, VNet integration
#
# 🎓 MODULE SOURCE: infra/modules/webapp/
# =============================================================================
module "webapp" {
  count  = var.enable_webapp ? 1 : 0
  source = "../../modules/webapp"

  resource_group_name = azurerm_resource_group.main.name
  app_name            = "${var.project_name}-app-dev"
  location            = var.location

  # SKU — Dev uses free tier (Prod uses P1v3 premium)
  sku_name = "F1" # Free tier for dev ($0/month)

  tags = module.global_standards.common_tags
}
