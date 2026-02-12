# Document 03: How Files Connect - The Big Picture

## Overview

This document explains how every directory and file in the framework connects to each other. This is the most important document for understanding how the framework works.

---

## The Layer Cake Architecture

The framework is organized in **layers**. Each layer builds on the one below it:

```
┌─────────────────────────────────────────────────────────────┐
│  LAYER 3: Applications / Workloads                          │
│  (Pattern 1: infra/envs/dev/main.tf)                        │
│  (Pattern 2: examples/pattern-2-delegated/dev-app-*/main.tf)│
│                                                              │
│  Creates: AKS, CosmosDB, ContainerApps, PostgreSQL, etc.    │
├─────────────────────────────────────────────────────────────┤
│  LAYER 2: Networking / Landing Zone                          │
│  (infra/modules/networking/ or infra/modules/landing-zone/)  │
│                                                              │
│  Creates: VNet, Subnets, NSGs, NAT Gateway                  │
├─────────────────────────────────────────────────────────────┤
│  LAYER 1: Reusable Modules                                   │
│  (infra/modules/aks/, cosmosdb/, postgresql/, etc.)          │
│                                                              │
│  Provides: Ready-to-use building blocks                      │
├─────────────────────────────────────────────────────────────┤
│  LAYER 0: Global Standards                                   │
│  (infra/global/)                                             │
│                                                              │
│  Provides: Naming, Tagging, Versions, Provider config        │
└─────────────────────────────────────────────────────────────┘
```

---

## Layer 0: Global Standards (`infra/global/`)

### What It Does

The `global/` directory is the **foundation** of the entire framework. It defines rules that **every team and every environment** must follow.

### Files and Their Purpose

```
infra/global/
├── locals.tf      ← Naming convention + standard tags
├── versions.tf    ← Required Terraform & provider versions
├── providers.tf   ← Azure provider configuration (reference only)
└── outputs.tf     ← Exports standards so other files can use them
```

### How `locals.tf` Works

```hcl
# File: infra/global/locals.tf

locals {
  naming = {
    organization = var.organization_name    # e.g., "mycompany"
    project      = var.project_name         # e.g., "myapp"
    environment  = var.environment           # e.g., "dev"
    location     = var.location              # e.g., "southeastasia"
  }

  # These patterns are used to name ALL resources:
  resource_names = {
    resource_group  = "${local.naming.organization}-${local.naming.project}-rg-${local.naming.environment}"
    aks_cluster     = "${local.naming.organization}-${local.naming.project}-aks-${local.naming.environment}"
    vnet            = "${local.naming.organization}-${local.naming.project}-vnet-${local.naming.environment}"
    # ... more patterns
  }

  # These tags are applied to ALL resources:
  standard_tags = {
    ManagedBy    = "Terraform"
    Organization = local.naming.organization
    Project      = local.naming.project
    Environment  = local.naming.environment
    CostCenter   = var.cost_center
    Owner        = var.owner_email
  }
}
```

### How Environments Use Global Standards

Every environment imports the global module:

```hcl
# File: infra/envs/dev/main.tf

# This imports ALL the naming and tagging rules
module "global_standards" {
  source = "../../global"             # ← Points to infra/global/
  
  organization_name = var.organization_name
  project_name      = var.project_name
  environment       = "dev"
  location          = var.location
  cost_center       = var.cost_center
  owner_email       = var.owner_email
}

# Now I can use the standards:
resource "azurerm_resource_group" "main" {
  name     = "${var.project_name}-rg-dev"
  location = var.location
  tags     = module.global_standards.common_tags    # ← Standard tags!
}
```

### The Connection Diagram

```
                    infra/global/locals.tf
                    ┌──────────────────────┐
                    │ Naming Convention    │
                    │ Standard Tags       │
                    │ Resource Patterns   │
                    └─────────┬────────────┘
                              │
                    infra/global/outputs.tf
                    ┌─────────┴────────────┐
                    │ Exports:            │
                    │ • common_tags       │
                    │ • resource_names    │
                    │ • naming            │
                    └─────────┬────────────┘
                              │
              ┌───────────────┼───────────────┐
              ▼               ▼               ▼
    infra/envs/dev/     infra/envs/staging/ infra/envs/prod/
    ┌──────────────┐    ┌──────────────┐   ┌──────────────┐
    │ module       │    │ module       │   │ module       │
    │ "global_std" │    │ "global_std" │   │ "global_std" │
    │ { source=    │    │ { source=    │   │ { source=    │
    │   "../../    │    │   "../../    │   │   "../../    │
    │   global" }  │    │   global" }  │   │   global" }  │
    └──────────────┘    └──────────────┘   └──────────────┘
```

---

## Layer 1: Reusable Modules (`infra/modules/`)

### What They Do

Modules are **pre-built packages** for specific Azure services. Each module:
- Creates ONE type of resource (AKS, CosmosDB, etc.)
- Accepts inputs via `variables.tf`
- Returns results via `outputs.tf`
- Can be reused by any environment or pattern

### Available Modules

```
infra/modules/
├── _shared/          ← Naming conventions helper
├── aks/              ← Azure Kubernetes Service
├── container-app/    ← Azure Container Apps
├── cosmosdb/         ← Azure Cosmos DB (MongoDB-compatible)
├── landing-zone/     ← Complete foundation (VNet + Logs + NSGs)
├── networking/       ← Just the networking part
├── postgresql/       ← PostgreSQL Flexible Server
├── security/         ← Key Vault
├── sql-database/     ← Azure SQL Database
├── storage/          ← Azure Storage Account
└── webapp/           ← Azure App Service
```

### Module Internal Structure

Every module follows the same pattern:

```
infra/modules/aks/
├── main.tf           ← Creates the AKS cluster
├── variables.tf      ← Inputs: cluster_name, node_count, vm_size, etc.
├── outputs.tf        ← Returns: cluster_id, cluster_name, kube_config
├── README.md         ← How to use this module
└── HOW-IT-WORKS.md   ← Detailed explanation
```

### How a Module is Called

```hcl
# From infra/envs/dev/main.tf:

module "aks" {
  count  = var.enable_aks ? 1 : 0           # Feature toggle
  source = "../../modules/aks"               # Where the module lives

  # These match variables.tf in the module:
  resource_group_name = azurerm_resource_group.main.name
  cluster_name        = "${var.project_name}-aks-dev"
  location            = var.location
  dns_prefix          = "${var.project_name}-dev"
  vnet_subnet_id      = module.networking.subnet_ids["aks-subnet"]    # ← From networking module!
  node_count          = var.aks_node_count
  vm_size             = var.aks_node_size
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  tags = module.global_standards.common_tags   # ← From global module!
}
```

### Module Dependency Chain

Resources often depend on each other. The framework creates them in the right order:

```
Step 1: Resource Group (must exist first - everything goes inside it)
    ↓
Step 2: Networking / VNet / Subnets (AKS needs a subnet)
    ↓
Step 3: Log Analytics (AKS needs monitoring)
    ↓
Step 4: AKS Module (requires resource group + subnet + log analytics)
    ↓ 
Step 5: CosmosDB Module (requires resource group)
    ↓
Step 6: Outputs (show results after everything is created)
```

Terraform automatically figures out this order based on references in the code.

---

## Layer 2: Networking

### Two Networking Options

The framework provides TWO ways to set up networking:

**Option A**: `modules/networking/` - Simple VNet + Subnets (used in Pattern 1)
**Option B**: `modules/landing-zone/` - Full foundation with VNet + Logs + NSGs (used for more complex setups)

### How Networking Connects to AKS

```
modules/networking/main.tf
┌─────────────────────────────────┐
│ Creates:                        │
│ • Virtual Network (10.1.0.0/16) │
│ • Subnet: aks-subnet            │──────┐
│ • Subnet: app-subnet            │──┐   │
│ • NSG: aks-nsg                  │  │   │
└─────────────────────────────────┘  │   │
                                      │   │
                                      │   │
                   ┌──────────────────┘   │
                   ▼                      ▼
        modules/container-app/      modules/aks/
        ┌─────────────────────┐   ┌─────────────────────┐
        │ Uses: app-subnet    │   │ Uses: aks-subnet    │
        │ for Container Apps  │   │ for AKS nodes       │
        └─────────────────────┘   └─────────────────────┘
```

In code, this connection looks like:

```hcl
# 1. Create networking first
module "networking" {
  source = "../../modules/networking"
  subnets = {
    "aks-subnet" = { address_prefixes = ["10.1.1.0/24"] }
    "app-subnet" = { address_prefixes = ["10.1.2.0/24"] }
  }
}

# 2. Then AKS uses the subnet from networking
module "aks" {
  source         = "../../modules/aks"
  vnet_subnet_id = module.networking.subnet_ids["aks-subnet"]
  #                 ↑ This references the output from networking module
}

# 3. Container Apps also use a subnet from networking
module "container_apps" {
  source                   = "../../modules/container-app"
  infrastructure_subnet_id = module.networking.subnet_ids["app-subnet"]
  #                          ↑ Different subnet, same VNet
}
```

---

## Layer 3: Environments (`infra/envs/`)

### How an Environment File Orchestrates Everything

The `main.tf` in each environment is the **conductor**. It calls all the other pieces:

```hcl
# File: infra/envs/dev/main.tf - THE ORCHESTRATOR

# Import standards (Layer 0)
module "global_standards" {
  source = "../../global"
  # ...
}

# Create foundation
resource "azurerm_resource_group" "main" { ... }

# Create networking (Layer 2)
module "networking" {
  source = "../../modules/networking"
  # ...
}

# Create monitoring
resource "azurerm_log_analytics_workspace" "main" { ... }

# Create services (Layer 3) - controlled by feature toggles
module "aks" {
  count  = var.enable_aks ? 1 : 0
  source = "../../modules/aks"
  # Uses: networking outputs + global_standards
}

module "cosmosdb" {
  count  = var.enable_cosmosdb ? 1 : 0
  source = "../../modules/cosmosdb"
  # Uses: resource group + global_standards
}

module "container_apps" {
  count  = var.enable_container_apps ? 1 : 0
  source = "../../modules/container-app"
  # Uses: networking outputs + log analytics + global_standards
}
```

### Complete Connection Map for `infra/envs/dev/`

```
infra/envs/dev/
┌─────────────────────────────────────────────────────────────┐
│                                                              │
│  backend.tf ─── Configures state storage in Azure           │
│                                                              │
│  dev.tfvars ─── Provides values ──▶ variables.tf            │
│                                       │                      │
│                    ┌──────────────────┘                      │
│                    ▼                                         │
│              main.tf (THE ORCHESTRATOR)                      │
│                    │                                         │
│        ┌──────────┼──────────┬──────────┐                   │
│        ▼          ▼          ▼          ▼                    │
│   ../../global  ../../modules/  ../../modules/  ../../modules/│
│   (standards)   networking     aks           cosmosdb       │
│        │          │               │            │             │
│        ▼          ▼               ▼            ▼             │
│   common_tags   subnet_ids    cluster_id   endpoint         │
│        │          │               │            │             │
│        └──────────┴───────────────┴────────────┘             │
│                          │                                   │
│                          ▼                                   │
│                     outputs.tf ── Shows results              │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## How Pattern 2 (Delegated) Connects Differently

In Pattern 2, app teams have their own `main.tf` that:
1. **References** shared infrastructure using `data` blocks (reads, doesn't create)
2. **Creates** their own resources directly
3. **Uses** shared modules via `source` path

```
Platform Team Creates (shared):
┌──────────────────────────────────────────────┐
│ VNet: vnet-contoso-dev-001                   │
│ Subnets: aks-subnet, app-subnet              │
│ Resource Group: rg-contoso-dev-network-001   │
└──────────────────────┬───────────────────────┘
                       │
         ┌─────────────┼─────────────┐
         │ (data source references)  │
         ▼                           ▼
  CRM Team (own state)        E-commerce Team (own state)
  ┌────────────────────┐    ┌────────────────────┐
  │ data "azurerm_vnet"│    │ data "azurerm_vnet"│
  │   reads shared VNet│    │   reads shared VNet│
  │                    │    │                    │
  │ Creates:           │    │ Creates:           │
  │ • App Service      │    │ • AKS Cluster      │
  │ • CosmosDB         │    │ • CosmosDB         │
  │ • Key Vault        │    │ • Key Vault        │
  │ • Managed Identity │    │ • Managed Identity │
  └────────────────────┘    └────────────────────┘
```

### The `data` Block Connection

```hcl
# File: examples/pattern-2-delegated/dev-app-crm/main.tf

# "I don't create the VNet, I just READ it from Azure"
data "azurerm_virtual_network" "landing_zone" {
  name                = "vnet-contoso-dev-001"              # Must match what platform team created
  resource_group_name = "rg-contoso-dev-network-001"        # Must match the resource group
}

# "Get the subnet details"
data "azurerm_subnet" "app_service" {
  name                 = "snet-contoso-dev-app-001"         # Must match the subnet name
  virtual_network_name = data.azurerm_virtual_network.landing_zone.name
  resource_group_name  = data.azurerm_virtual_network.landing_zone.resource_group_name
}

# Now I can use it in my resources:
resource "azurerm_linux_web_app" "crm" {
  # Uses the subnet that the platform team created
  virtual_network_subnet_id = data.azurerm_subnet.app_service.id
}
```

---

## Complete File Interaction Summary

### Pattern 1 (Centralized) - All connections:

```
dev.tfvars
    │ provides values to
    ▼
variables.tf
    │ declares variables used by
    ▼
main.tf ──────────────────────────────────────────────────────
    │         │              │              │              │
    │    calls module    calls module   calls module   calls module
    ▼         ▼              ▼              ▼              ▼
  ../../    ../../modules/  ../../modules/ ../../modules/ ../../modules/
  global    networking      aks            cosmosdb       container-app
    │         │              │              │              │
    │   returns subnet_ids   │              │              │
    │         │───────────▶──┘              │              │
    │         │──────────────────────────▶──┘              │
    │                                                      │
    │   returns common_tags                                │
    │─────────▶ applied to ALL resources                   │
    │                                                      │
    └──────────────────────────────────────────────────────┘
                    │
                    ▼
              outputs.tf (displays results)
                    │
                    ▼
              backend.tf (saves state to Azure Storage)
```

### Pattern 2 (Delegated) - All connections:

```
Platform Team (runs once):
    infra/envs/dev/main.tf → Creates VNet, Subnets, Log Analytics
    State file: dev.terraform.tfstate

App Team (runs independently):
    examples/pattern-2-delegated/dev-app-crm/main.tf
        │
        ├── data "azurerm_virtual_network" → Reads VNet (created by platform team)
        ├── data "azurerm_subnet"          → Reads Subnet (created by platform team)
        ├── module "naming" (../../infra/modules/_shared) → Uses shared naming
        ├── resource "azurerm_resource_group"  → Creates own RG
        ├── resource "azurerm_cosmosdb_account"→ Creates own CosmosDB
        ├── resource "azurerm_key_vault"       → Creates own Key Vault
        └── resource "azurerm_linux_web_app"   → Creates own Web App
    State file: dev-app-crm.tfstate (SEPARATE from platform team!)
```

---

## The Golden Rule of Connections

> **Every `module` block is a CALL to a module. Every `data` block is a READ from existing infrastructure. Every `resource` block is a CREATE in Azure.**

| Block Type | Direction | Example |
|-----------|-----------|---------|
| `module` | → Call another folder's Terraform code | `module "aks" { source = "../../modules/aks" }` |
| `data` | ← Read from existing Azure resource | `data "azurerm_virtual_network" "vnet" { ... }` |
| `resource` | → Create/Update resource in Azure | `resource "azurerm_resource_group" "main" { ... }` |
| `output` | ← Return value to the caller | `output "vnet_id" { value = module.networking.vnet_id }` |
| `variable` | ← Accept input from user or caller | `variable "enable_aks" { type = bool }` |
| `locals` | Internal computed values | `locals { name = "${var.org}-${var.project}" }` |

---

*Previous: [02 - Terraform Basics](02-TERRAFORM-BASICS.md)* | *Next: [04 - Pattern 1 vs Pattern 2 →](04-PATTERN1-VS-PATTERN2.md)*
