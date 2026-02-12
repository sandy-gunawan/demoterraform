# Document 04: Pattern 1 vs Pattern 2 Explained

> **✨ KEY ARCHITECTURE:** Platform team creates **all VNets** (including Pattern 2 app VNets)!  
> Pattern 2 teams **read** VNets via data sources → Showcases framework reusability!

---

## The Two Patterns

This framework supports **two patterns** for organizing how teams deploy infrastructure. Understanding when to use each pattern is critical for a successful client demo.

**Core Architecture Principle:** Platform team governs networking, Pattern 2 teams focus on applications:
- ✅ **Platform creates all VNets** - Standardized networking (10.1.x, 10.2.x, 10.3.x)
- ✅ **Pattern 2 reads via data sources** - Reuses networking module (no duplication!)
- ✅ **Separate state files** - Team independence for applications
- ✅ **Network isolation** - Each app has dedicated VNet
- ✅ **Shows framework value** - Governance + reusability + team autonomy

---

## Pattern 1: Centralized (Single Environment File)

### What Is It?

One `main.tf` file controls ALL resources for an environment. A central DevOps/Platform team manages everything.

### Where It Lives

```
infra/envs/dev/
├── backend.tf       ← State storage config
├── main.tf          ← ONE file controls everything
├── variables.tf     ← All variables in one place
├── dev.tfvars       ← All values in one place
└── outputs.tf       ← All outputs in one place
```

### How It Works

```hcl
# infra/envs/dev/main.tf - THE SINGLE CONTROLLER

# Feature toggles control what gets deployed
module "aks" {
  count  = var.enable_aks ? 1 : 0         # Toggle: AKS
  source = "../../modules/aks"
  # ...
}

module "cosmosdb" {
  count  = var.enable_cosmosdb ? 1 : 0    # Toggle: CosmosDB
  source = "../../modules/cosmosdb"
  # ...
}

module "container_apps" {
  count  = var.enable_container_apps ? 1 : 0  # Toggle: Container Apps
  source = "../../modules/container-app"
  # ...
}
```

### Who Does What

```
┌─────────────────────────────────────────────────────────┐
│                    Platform Team                         │
│                                                          │
│  Owns: infra/envs/dev/main.tf                           │
│  Controls: ALL resources via feature toggles            │
│                                                          │
│  App Team A says: "I need AKS"                          │
│     → Platform team: sets enable_aks = true             │
│                                                          │
│  App Team B says: "I need CosmosDB + ContainerApps"     │
│     → Platform team: sets enable_cosmosdb = true        │
│                       sets enable_container_apps = true  │
│                                                          │
│  Everything goes through ONE person/team                │
└─────────────────────────────────────────────────────────┘
```

### The Request Flow

```
App Team                Platform Team              Azure
   │                         │                       │
   │ "I need AKS"           │                       │
   │────────────────────────▶│                       │
   │                         │                       │
   │                         │ Edit dev.tfvars:      │
   │                         │ enable_aks = true     │
   │                         │                       │
   │                         │ git push → PR         │
   │                         │ CI pipeline: plan     │
   │                         │ CD pipeline: apply ──▶│ Creates AKS
   │                         │                       │
   │ "Here's your cluster"  │                       │
   │◀────────────────────────│                       │
```

---

## Pattern 2: Delegated (Per-Team Folders)

### What Is It?

Each application team has their **own folder** with their **own `main.tf`** and their **own state file**. Teams work independently.

### Where It Lives

```
examples/pattern-2-delegated/
├── README.md
├── dev-app-crm/                  ← CRM team owns this
│   ├── main.tf                   ← CRM's own resources
│   ├── variables.tf
│   ├── dev.tfvars
│   ├── outputs.tf
│   └── README.md
└── dev-app-ecommerce/            ← E-commerce team owns this
    ├── main.tf                   ← E-commerce's own resources
    ├── variables.tf
    ├── dev.tfvars
    ├── outputs.tf
    └── README.md
```

### How It Works

```hcl
# examples/pattern-2-delegated/dev-app-crm/main.tf

# 1. Uses separate state file
backend "azurerm" {
  key = "dev-app-crm.tfstate"          # ← CRM team's own state!
}

# 2. References shared infrastructure (doesn't create it)
data "azurerm_virtual_network" "landing_zone" {
  name                = "vnet-contoso-dev-001"       # Platform team created this
  resource_group_name = "rg-contoso-dev-network-001"
}

# 3. Creates own resources
resource "azurerm_resource_group" "crm" {
  name = "rg-contoso-dev-crm-001"                    # CRM team's own RG
}

resource "azurerm_cosmosdb_account" "crm" {
  name = "cosmos-contoso-dev-crm-001"                # CRM team's own CosmosDB
}

resource "azurerm_linux_web_app" "crm" {
  name = "app-contoso-dev-crm-001"                   # CRM team's own Web App
}

resource "azurerm_key_vault" "crm" {
  name = "kv-contoso-dev-crm"                        # CRM team's own Key Vault
}
```

### Who Does What

```
┌──────────────────────────────────────────────────────────────┐
│                                                               │
│  Platform Team                                                │
│  ┌─────────────────────────────────────┐                     │
│  │ Owns: Shared infrastructure         │                     │
│  │ • VNet, Subnets, NSGs              │                     │
│  │ • Log Analytics                     │                     │
│  │ • DNS Zones                         │                     │
│  │ State: dev.terraform.tfstate        │                     │
│  └─────────────────────┬───────────────┘                     │
│                        │                                      │
│         ┌──────────────┼──────────────┐                      │
│         │  data source │ data source  │                      │
│         ▼              ▼              ▼                       │
│  CRM Team         E-commerce Team   Marketing Team           │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐         │
│  │ Own folder   │ │ Own folder   │ │ Own folder   │         │
│  │ Own state    │ │ Own state    │ │ Own state    │         │
│  │ Own resources│ │ Own resources│ │ Own resources│         │
│  │              │ │              │ │              │         │
│  │ App Service  │ │ AKS Cluster  │ │ ContainerApp │         │
│  │ CosmosDB     │ │ CosmosDB     │ │ PostgreSQL   │         │
│  │ Key Vault    │ │ Key Vault    │ │ Key Vault    │         │
│  └──────────────┘ └──────────────┘ └──────────────┘         │
│                                                               │
│  Each team can deploy independently without affecting others  │
└──────────────────────────────────────────────────────────────┘
```

### The Request Flow

```
CRM Team                          Platform Team              Azure
   │                                    │                       │
   │  (No need to ask! They manage      │                       │
   │   their own folder)                │                       │
   │                                    │                       │
   │  Edit dev-app-crm/dev.tfvars      │                       │
   │  git push → PR                    │                       │
   │  PR reviewers: CRM team lead      │                       │
   │  CI pipeline: plan                │                       │
   │  CD pipeline: apply ─────────────────────────────────────▶│ Creates
   │                                    │                       │ CRM resources
   │  Done! No waiting for platform!   │                       │

E-commerce Team                   (Simultaneously!)           Azure
   │                                    │                       │
   │  Edit dev-app-ecommerce/dev.tfvars│                       │
   │  git push → PR                    │                       │
   │  CI pipeline: plan                │                       │
   │  CD pipeline: apply ─────────────────────────────────────▶│ Creates
   │                                    │                       │ E-commerce resources
```

---

## Deep Dive: How Pattern 2 Actually Works

This is the most confusing part for beginners, so let's break it down step-by-step.

### The Shared Infrastructure Question

**Question**: "In Pattern 2, how do app teams connect to shared infrastructure? Who creates it? Do they need Pattern 1 first?"

**Answer**: Yes! The Platform team creates the shared infrastructure FIRST. This is **separate** from Pattern 1's main.tf.

### Step-by-Step: Platform Team's Job

#### Step 1: Platform Team Creates Shared Infrastructure

The Platform team deploys **only** the networking foundation. They can do this in two ways:

---

### Option A: Reuse Pattern 1 Folder (EASIEST - Recommended)

**Concept**: Use the existing `infra/envs/dev/` folder, but turn OFF all the app service toggles. This way, only the base networking gets created.

**Step-by-step:**

```bash
cd infra/envs/dev
```

**Edit `dev.tfvars` - Turn EVERYTHING off except networking:**

```hcl
# File: infra/envs/dev/dev.tfvars

organization_name = "contoso"
project_name      = "platform"
location          = "southeastasia"
tenant_id         = "YOUR-TENANT-ID"

# ============================================================
# FOR PATTERN 2: DISABLE ALL APP SERVICES!
# ============================================================
enable_aks            = false  # ❌ App teams create their own AKS
enable_cosmosdb       = false  # ❌ App teams create their own CosmosDB
enable_container_apps = false  # ❌ App teams create their own Container Apps
enable_webapp         = false  # ❌ App teams create their own Web Apps
enable_postgresql     = false  # ❌ App teams create their own PostgreSQL

# Only shared infrastructure
enable_key_vault      = true   # ✅ Optional: shared Key Vault (if you want)

# Monitoring (shared by all teams)
enable_application_insights = false
enable_diagnostic_settings  = false
log_retention_days          = 30
```

**What happens when you run `terraform apply`?**

The `infra/envs/dev/main.tf` file has conditional blocks like this:

```hcl
# From infra/envs/dev/main.tf:

# This ALWAYS runs (no toggle):
resource "azurerm_resource_group" "main" { ... }
module "networking" { ... }
resource "azurerm_log_analytics_workspace" "main" { ... }

# This ONLY runs if enable_aks = true:
module "aks" {
  count  = var.enable_aks ? 1 : 0  # ← count = 0, so SKIPPED!
  source = "../../modules/aks"
  ...
}

# This ONLY runs if enable_cosmosdb = true:
module "cosmosdb" {
  count  = var.enable_cosmosdb ? 1 : 0  # ← count = 0, so SKIPPED!
  source = "../../modules/cosmosdb"
  ...
}
```

**Deploy:**

```bash
terraform init
terraform plan -var-file="dev.tfvars"

# Output shows:
# Plan: 8 to add, 0 to change, 0 to destroy
#   + resource_group (networking)
#   + vnet
#   + subnet (aks-subnet)
#   + subnet (app-subnet)
#   + nsg (aks-nsg)
#   + log_analytics_workspace
#   + key_vault (if enabled)
# 
# Notice: NO AKS, NO CosmosDB, NO Container Apps!

terraform apply -var-file="dev.tfvars"
```

**Result**: State file `dev.terraform.tfstate` contains **ONLY**:
- ✅ Resource Group: `rg-contoso-platform-network-001`
- ✅ VNet: `platform-vnet-dev` (10.1.0.0/16)
- ✅ Subnet: `aks-subnet` (10.1.1.0/24)
- ✅ Subnet: `app-subnet` (10.1.2.0/24)
- ✅ NSG: `aks-nsg`
- ✅ Log Analytics: `platform-logs-dev`
- ✅ Key Vault: `platformkvdev` (if enabled)
- ❌ **NO AKS** (count = 0, skipped!)
- ❌ **NO CosmosDB** (count = 0, skipped!)
- ❌ **NO Container Apps** (count = 0, skipped!)

**Key Point**: Even though the AKS module code exists in `main.tf`, it doesn't run because `count = 0`. It's like having a light switch - the wiring is there, but the switch is OFF.

---

### Option B: Create Separate Landing Zone Folder (CLEANER)

**Concept**: Create a brand new folder that ONLY handles shared networking. No app services at all.

**Create new folder structure:**

```
infra/
├── envs/              ← Pattern 1 folder (you can skip this entirely for pure Pattern 2)
├── landing-zone/      ← NEW! Platform team's dedicated folder
│   ├── main.tf
│   ├── variables.tf
│   ├── dev.tfvars
│   ├── outputs.tf
│   └── backend.tf
└── modules/           ← Existing modules (reused)
```

**Create `infra/landing-zone/main.tf`:**

```hcl
# File: infra/landing-zone/main.tf
# Platform Team's DEDICATED landing zone (no app services!)

terraform {
  required_version = ">= 1.5.0"
  
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstatecontosoid"
    container_name       = "tfstate"
    key                  = "dev-shared-landing-zone.tfstate"  # Different key!
  }
}

provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "network" {
  name     = "rg-${var.company_name}-${var.environment}-network-001"
  location = var.location
  
  tags = {
    ManagedBy   = "Terraform"
    Purpose     = "Shared Networking"
    Environment = var.environment
  }
}

# Use the landing-zone module (which includes VNet, Subnets, NSGs, Logs)
module "landing_zone" {
  source = "../modules/landing-zone"
  
  resource_group_name = azurerm_resource_group.network.name
  vnet_name           = "vnet-${var.company_name}-${var.environment}-001"
  location            = var.location
  address_space       = ["10.1.0.0/16"]
  
  subnets = {
    "snet-${var.company_name}-${var.environment}-aks-001" = {
      address_prefixes  = ["10.1.1.0/24"]
      service_endpoints = ["Microsoft.Sql", "Microsoft.Storage", "Microsoft.KeyVault"]
    }
    "snet-${var.company_name}-${var.environment}-app-001" = {
      address_prefixes  = ["10.1.2.0/24"]
      service_endpoints = ["Microsoft.Sql", "Microsoft.Storage"]
    }
  }
  
  # NSGs, Log Analytics, etc.
  network_security_groups = { ... }
  
  tags = { ... }
}
```

**Create `infra/landing-zone/dev.tfvars`:**

```hcl
company_name = "contoso"
environment  = "dev"
location     = "southeastasia"
```

**Deploy:**

```bash
cd infra/landing-zone
terraform init
terraform plan -var-file="dev.tfvars"
terraform apply -var-file="dev.tfvars"
```

**Result**: State file `dev-shared-landing-zone.tfstate` contains the same networking resources, but this folder is completely separate from Pattern 1.

---

### Comparison: Option A vs Option B

| Aspect | Option A: Reuse Pattern 1 | Option B: Separate Folder |
|--------|---------------------------|---------------------------|
| **Effort** | ✅ Easy - just edit tfvars | ❌ More work - create new folder |
| **Files to create** | 0 (reuse existing) | 4-5 new files |
| **State file** | `dev.terraform.tfstate` | `dev-shared-landing-zone.tfstate` |
| **Confusing?** | A bit (toggles can be confusing) | No (clear purpose) |
| **Can create Pattern 1 apps?** | ✅ Yes (enable toggles) | ❌ No (networking only) |
| **Best for** | Demo, teams using both patterns | Large orgs wanting clear separation |

---

### Visual: What Gets Created (Option A)

```
When you set all toggles to FALSE in Pattern 1:

infra/envs/dev/main.tf contains:
┌─────────────────────────────────────────────────┐
│ resource "azurerm_resource_group" {...}   ✅ RUNS  │
│ module "networking" {...}                 ✅ RUNS  │
│ resource "azurerm_log_analytics" {...}    ✅ RUNS  │
│ module "security" { count = 1 ? 1 : 0 }   ✅ RUNS  │
│                                                  │
│ module "aks" { count = false ? 1 : 0 }    ❌ SKIPPED │
│ module "cosmosdb" { count = false ? 1:0}  ❌ SKIPPED │
│ module "container_apps" { count = ...}    ❌ SKIPPED │
└─────────────────────────────────────────────────┘

Result in Azure:
✅ VNet + Subnets + NSGs + Log Analytics
❌ NO AKS, NO CosmosDB, NO Container Apps
```

---

### Common Confusion Clarified

**Q: "If I use Pattern 1 folder with AKS enabled, won't AKS be created?"**

**A**: YES, if `enable_aks = true`. But if you set `enable_aks = false`, the AKS module is **skipped entirely** (count = 0). It's like the code doesn't exist.

**Q: "Can I use Pattern 1 AND Pattern 2 at the same time?"**

**A**: **YES!** This is the most common real-world scenario. Here's what you CAN do:

```
✅ ALLOWED - Pattern 1 and Pattern 2 Together:
----------------------------------------------------
Pattern 1 (infra/envs/dev/):
  enable_aks = true        → Creates 1 shared AKS cluster
  enable_cosmosdb = true   → Creates 1 shared CosmosDB
  Creates: VNet, Subnets, Logs (SHARED by everyone)

Pattern 2 (examples/pattern-2-delegated/dev-app-crm/):
  Uses: data block to read Pattern 1's VNet
  Creates: Own App Service, Own CosmosDB (separate from Pattern 1!)

Pattern 2 (examples/pattern-2-delegated/dev-app-ecommerce/):
  Uses: data block to read Pattern 1's VNet
  Creates: Own AKS cluster (separate from Pattern 1!), Own CosmosDB

Result: 
  - 1 VNet shared by everyone ✅
  - 2 AKS clusters (1 shared from Pattern 1, 1 for e-commerce) ✅
  - 3 CosmosDB instances (1 shared, 1 for CRM, 1 for e-commerce) ✅
```

**The key rule:** For networking (VNet) - everyone shares. For apps (AKS, CosmosDB) - Pattern 1 creates shared instances, Pattern 2 creates independent instances. Both coexist!

**Q: "What if I want ONLY Pattern 2 (no Pattern 1 apps)?"**

**A**: Still use Pattern 1's `infra/envs/dev/` folder, but set ALL app toggles to false:

```hcl
# Platform team creates ONLY networking (no apps)
enable_aks = false
enable_cosmosdb = false
enable_container_apps = false

# Then Pattern 2 teams create their own apps
```

### Step 2: App Teams Reference the Shared Infrastructure

Now the CRM team wants to deploy their app. They **DO NOT** create the VNet. They **READ** it using `data` blocks.

**File**: `examples/pattern-2-delegated/dev-app-crm/main.tf`

```hcl
# ============================================================================
# DATA SOURCES - Read existing infrastructure created by Platform team
# ============================================================================

data "azurerm_virtual_network" "landing_zone" {
  name                = "vnet-contoso-dev-001"              # ← Must match what Platform created
  resource_group_name = "rg-contoso-dev-network-001"        # ← Must match exactly!
}

data "azurerm_subnet" "app_service" {
  name                 = "snet-contoso-dev-app-001"         # ← Must match subnet name
  virtual_network_name = data.azurerm_virtual_network.landing_zone.name
  resource_group_name  = data.azurerm_virtual_network.landing_zone.resource_group_name
}

# ============================================================================
# CRM'S OWN RESOURCES - These are created by CRM team
# ============================================================================

resource "azurerm_resource_group" "crm" {
  name     = "rg-contoso-dev-crm-001"    # ← CRM's own resource group
  location = var.location
}

resource "azurerm_linux_web_app" "crm" {
  name                = "app-contoso-dev-crm-001"
  resource_group_name = azurerm_resource_group.crm.name
  
  # Connect to Platform team's subnet using data source
  virtual_network_subnet_id = data.azurerm_subnet.app_service.id  # ← Here's the connection!
}
```

### Step 3: Understanding the State File Separation

```
Azure Storage Account: tfstatecontosoid
└── Container: tfstate
    ├── dev.terraform.tfstate           ← Platform team's state (shared infra)
    │   Contains:
    │   - VNet: vnet-contoso-dev-001
    │   - Subnets: snet-contoso-dev-aks-001, snet-contoso-dev-app-001
    │   - NSGs: nsg-contoso-dev-aks-001
    │   - Log Analytics: log-contoso-dev-001
    │
    ├── dev-app-crm.tfstate             ← CRM team's state
    │   Contains:
    │   - Resource Group: rg-contoso-dev-crm-001
    │   - App Service: app-contoso-dev-crm-001
    │   - CosmosDB: cosmos-contoso-dev-crm-001
    │   - Key Vault: kv-contoso-dev-crm
    │   - (NO VNet, NO Subnets - those are in Platform's state!)
    │
    └── dev-app-ecommerce.tfstate       ← E-commerce team's state
        Contains:
        - Resource Group: rg-contoso-dev-ecommerce-001
        - AKS: aks-contoso-dev-ecommerce-001
        - CosmosDB: cosmos-contoso-dev-ecommerce-001
        - Key Vault: kv-contoso-dev-ecommerce
        - (NO VNet, NO Subnets - those are in Platform's state!)
```

### The Critical Rule: Names Must Match Exactly!

**This is why it's so important:**

```hcl
# Platform team creates (in infra/envs/dev/main.tf):
resource "azurerm_virtual_network" "main" {
  name                = "vnet-contoso-dev-001"    # ← This name
  resource_group_name = "rg-contoso-dev-network-001"
}

# CRM team reads (in examples/pattern-2-delegated/dev-app-crm/main.tf):
data "azurerm_virtual_network" "landing_zone" {
  name                = "vnet-contoso-dev-001"    # ← MUST match exactly!
  resource_group_name = "rg-contoso-dev-network-001"  # ← MUST match exactly!
}
```

**If the names don't match:**
```
Error: Virtual network "vnet-contoso-dev-002" not found
```

### Why Must Names Be the Same?

Because `data` blocks **query Azure** to find existing resources. They're like a search:

```
Platform team:   Creates a resource named "vnet-contoso-dev-001" in Azure
                 ↓
                 Azure stores it
                 ↓
CRM team:        Searches Azure: "Give me the VNet named vnet-contoso-dev-001"
                 ↓
                 Azure finds it and returns the details
                 ↓
CRM team:        Uses the subnet ID to connect their App Service
```

### Common Mistakes & Solutions

| Mistake | Problem | Solution |
|---------|---------|----------|
| **CRM team tries to create VNet** | Error: VNet already exists | Use `data` block, not `resource` |
| **Names don't match** | Error: Resource not found | Coordinate naming with Platform team |
| **Platform team deletes VNet** | All apps break! | Never delete shared infra while apps use it |
| **Forgetting to deploy shared infra first** | Error: VNet not found | Platform team must deploy first |
| **Wrong resource group name** | Error: Not found | Check Platform team's naming exactly |

### Can You Use BOTH Patterns at the Same Time?

**YES! This is the MOST common real-world scenario!**

Here's how it works:

```
Pattern 1 (infra/envs/dev):              Pattern 2 (examples/pattern-2-delegated):
┌─────────────────────────────┐          ┌──────────────────────────────┐
│ Platform Team Deploys:      │          │ CRM Team Deploys:            │
│                             │          │                              │
│ ✅ VNet (SHARED!)           │──────────┤ data "VNet" → reads this!   │
│ ✅ Subnets (SHARED!)        │          │                              │
│ ✅ Logs (SHARED!)           │          │ ✅ Own App Service           │
│ ✅ AKS (Team A & B share)   │          │ ✅ Own CosmosDB              │
│ ✅ CosmosDB (Team A uses)   │          │ ✅ Own Key Vault             │
└─────────────────────────────┘          └──────────────────────────────┘
                                         ┌──────────────────────────────┐
                                         │ E-commerce Team Deploys:     │
                                         │                              │
                                         │ data "VNet" → reads this!   │
                                         │                              │
                                         │ ✅ Own AKS (separate!)       │
                                         │ ✅ Own CosmosDB              │
                                         │ ✅ Own Key Vault             │
                                         └──────────────────────────────┘

Result: 2 AKS clusters (one shared, one for e-commerce)
        3 CosmosDB instances (one shared, one for CRM, one for e-commerce)
        ALL using the SAME VNet!
```

**For the demo, you use BOTH patterns simultaneously:**

1. **Pattern 1**: Platform enables `enable_aks=true`, `enable_cosmosdb=true`
2. **Pattern 2**: CRM and E-commerce teams reference Pattern 1's VNet using `data` blocks
3. **Everything coexists**: Pattern 1's shared AKS + Pattern 2's independent apps

**Why this works:**
- The VNet is infrastructure (networking layer) - everyone shares it
- The applications (AKS, CosmosDB) are workload layer - teams choose Pattern 1 (shared) or Pattern 2 (own)

### Can Pattern 2 Work WITHOUT Pattern 1?

**YES!** Pattern 2 does NOT require Pattern 1. Here's how:

**Scenario: Pure Pattern 2 (No Pattern 1 apps)**

```
infra/
├── shared-foundation/              ← Platform team's MINIMAL folder
│   ├── main.tf                     ← Creates ONLY VNet, Subnets, Logs
│   ├── variables.tf
│   ├── dev.tfvars
│   └── backend.tf                  ← State: dev-shared-foundation.tfstate
│
└── (NO infra/envs/dev/ needed!)    ← Pattern 1 folder doesn't exist

examples/pattern-2-delegated/
├── dev-app-crm/                    ← CRM team's folder
├── dev-app-ecommerce/              ← E-commerce team's folder
└── dev-app-marketing/              ← Marketing team's folder
```

**The ONLY requirement:**
1. Platform team creates the shared networking ONCE
2. App teams reference it using `data` blocks
3. Each team has their own state file

**Pattern 1 vs Pattern 2 Analogy:**

| Pattern | Analogy |
|---------|---------|
| **Pattern 1** | **Hotel**: One manager (Platform team) controls all rooms. Teams request rooms. One state file for entire hotel. |
| **Pattern 2** | **Apartment Complex**: One landlord (Platform team) owns the building (VNet/roads/electricity). Each tenant (app team) manages their own apartment. Separate lease (state file) per apartment. |

### Visual: How Data Sources Connect to Shared Infrastructure

```
┌──────────────────────────────────────────────────────────────┐
│  Platform Team's State: dev.terraform.tfstate                 │
│  ┌──────────────────────────────────────────────────────────┐│
│  │ resource "azurerm_virtual_network" "main" {              ││
│  │   name = "vnet-contoso-dev-001"                          ││
│  │   ...                                                     ││
│  │ }                                                         ││
│  │                                                           ││
│  │ resource "azurerm_subnet" "app_subnet" {                 ││
│  │   name = "snet-contoso-dev-app-001"                      ││
│  │   ...                                                     ││
│  │ }                                                         ││
│  └──────────────────┬────────────────────────────────────────┘│
│                     │                                          │
│                     │ terraform apply                          │
│                     ▼                                          │
│              ┌─────────────┐                                  │
│              │    Azure    │                                  │
│              │  Creates:   │                                  │
│              │  VNet       │                                  │
│              │  Subnets    │                                  │
│              └──────┬──────┘                                  │
│                     │                                          │
└─────────────────────┼──────────────────────────────────────────┘
                      │ (Resources exist in Azure)
                      │
┌─────────────────────┼──────────────────────────────────────────┐
│  CRM Team's State: dev-app-crm.tfstate                         │
│  ┌────────────────┴─────────────────────────────────────────┐ │
│  │ data "azurerm_virtual_network" "landing_zone" {          │ │
│  │   name = "vnet-contoso-dev-001"  ← Searches Azure       │ │
│  │ }                                                         │ │
│  │                                                           │ │
│  │ data "azurerm_subnet" "app_service" {                    │ │
│  │   name = "snet-contoso-dev-app-001"  ← Searches Azure   │ │
│  │ }                                                         │ │
│  │                                                           │ │
│  │ resource "azurerm_linux_web_app" "crm" {                 │ │
│  │   virtual_network_subnet_id =                            │ │
│  │     data.azurerm_subnet.app_service.id ← Uses found ID! │ │
│  │ }                                                         │ │
│  └───────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

### Deployment Timeline for Pattern 2

```
Day 1: Platform Team Setup
   ↓
   Platform team deploys shared infrastructure:
   - infra/envs/dev/main.tf (with all app toggles = false)
   - OR infra/shared-foundation/main.tf
   - Result: VNet + Subnets + Logs exist in Azure
   - State file: dev.terraform.tfstate

Day 2-10: App Teams Deploy Independently
   ↓
   CRM team:
   - Creates examples/pattern-2-delegated/dev-app-crm/
   - Uses data blocks to reference Platform's VNet
   - Deploys their resources
   - State file: dev-app-crm.tfstate
   
   E-commerce team (same time!):
   - Creates examples/pattern-2-delegated/dev-app-ecommerce/
   - Uses data blocks to reference Platform's VNet
   - Deploys their resources
   - State file: dev-app-ecommerce.tfstate
   
   Marketing team (same time!):
   - Creates their own folder
   - Uses data blocks to reference Platform's VNet
   - Deploys their resources
   - State file: dev-app-marketing.tfstate
```

**Key Point:** All teams work in parallel AFTER Platform team finishes shared infra!

---

## The Complete Flow: How Files Connect Between Patterns

### Flow Diagram: Pattern 1 + Pattern 2 Working Together

```
┌────────────────────────────────────────────────────────────────────┐
│ STEP 1: Platform Team Deploys Pattern 1                            │
└────────────────────────────────────────────────────────────────────┘

File: infra/envs/dev/backend.tf
    ↓
    Defines state storage: dev.terraform.tfstate

File: infra/envs/dev/dev.tfvars
    ↓
    Values: enable_aks=true, enable_cosmosdb=true

File: infra/envs/dev/variables.tf ← Validates values

File: infra/envs/dev/main.tf (THE ORCHESTRATOR)
    ↓
    ├─→ Creates: azurerm_resource_group.main
    │       Name: "contoso-platform-rg-dev"
    │
    ├─→ Calls: module "networking" (../../modules/networking)
    │       Creates:
    │       - VNet: "platform-vnet-dev"
    │       - Subnet: "aks-subnet" (10.1.1.0/24)
    │       - Subnet: "app-subnet" (10.1.2.0/24)
    │       - NSG: "aks-nsg"
    │
    ├─→ Calls: module "aks" [count=1 because enable_aks=true]
    │       Creates: AKS cluster using aks-subnet
    │
    ├─→ Calls: module "cosmosdb" [count=1 because enable_cosmosdb=true]
    │       Creates: CosmosDB account
    │
    └─→ Saves to state: dev.terraform.tfstate
            Contains:
            - Resource Group: contoso-platform-rg-dev
            - VNet ID: /subscriptions/.../vnet/platform-vnet-dev
            - Subnet IDs: .../aks-subnet, .../app-subnet
            - AKS ID: .../aks/platform-aks-dev
            - CosmosDB ID: .../cosmos/platformcosmosdev

┌────────────────────────────────────────────────────────────────────┐
│ STEP 2: CRM Team Deploys Pattern 2 (AFTER Step 1 completes)        │
└────────────────────────────────────────────────────────────────────┘

File: examples/pattern-2-delegated/dev-app-crm/backend.tf
    ↓
    Defines SEPARATE state storage: dev-app-crm.tfstate

File: examples/pattern-2-delegated/dev-app-crm/dev.tfvars
    ↓
    Values: location=southeastasia, app_service_sku=B1

File: examples/pattern-2-delegated/dev-app-crm/main.tf
    ↓
    ├─→ data "azurerm_virtual_network" "landing_zone"
    │       ↓
    │       Queries Azure: "Find VNet named platform-vnet-dev"
    │       ↓
    │       Azure returns: VNet ID from Pattern 1's deployment
    │       ↓
    │       Stores in memory (NOT in state): vnet details
    │
    ├─→ data "azurerm_subnet" "app_service"
    │       ↓
    │       Queries Azure: "Find subnet named app-subnet"
    │       ↓
    │       Azure returns: Subnet ID from Pattern 1's deployment
    │       ↓
    │       Stores in memory: subnet details
    │
    ├─→ Creates: azurerm_resource_group.crm
    │       Name: "rg-contoso-dev-crm-001" (CRM's own!)
    │
    ├─→ Creates: azurerm_linux_web_app.crm
    │       Uses: data.azurerm_subnet.app_service.id ← Points to Pattern 1's subnet!
    │
    ├─→ Creates: azurerm_cosmosdb_account.crm
    │       Name: "cosmos-contoso-dev-crm-001" (CRM's own! Different from Pattern 1!)
    │
    └─→ Saves to state: dev-app-crm.tfstate (SEPARATE file!)
            Contains:
            - Resource Group: rg-contoso-dev-crm-001
            - App Service: app-contoso-dev-crm-001
            - CosmosDB: cosmos-contoso-dev-crm-001
            - Does NOT contain VNet (that's in Platform's state!)
```

### Prerequisites for Running Both Patterns Together

| Prerequisite | Required? | Why |
|-------------|-----------|-----|
| **Platform team deploys first** | ✅ YES | Pattern 2 needs the VNet to exist before referencing it |
| **Names must match exactly** | ✅ YES | `data` blocks search by exact name |
| **Subnets must exist** | ✅ YES | Pattern 2 apps need subnets to connect to |
| **Separate state files** | ✅ YES | Each Pattern 2 app needs its own state file |
| **Different resource names** | ✅ YES | Pattern 2 can't use same names as Pattern 1 resources |
| **Same Azure subscription** | ⚠️ Usually | Can be different, but same is easier |
| **Same region** | ⚠️ Usually | VNet can only exist in one region |

### Subnet Strategy: Do You Need New Subnets?

**Answer: It depends on isolation requirements**

#### Option 1: Share Subnets (Simpler)
```hcl
# Pattern 1 creates:
subnets = {
  "aks-subnet" = { address_prefixes = ["10.1.1.0/24"] }
  "app-subnet" = { address_prefixes = ["10.1.2.0/24"] }  ← Everyone uses this!
}

# Pattern 1 AKS uses: aks-subnet
# Pattern 2 CRM App Service uses: app-subnet ← Same subnet as Pattern 1 apps
# Pattern 2 E-commerce AKS uses: aks-subnet ← Same subnet as Pattern 1 AKS
```

**Pros:**
- ✅ Simpler setup
- ✅ Fewer IP address ranges
- ✅ All apps can communicate easily

**Cons:**
- ❌ Less resource isolation
- ❌ Harder to apply NSG rules per team

#### Option 2: Dedicated Subnets per Team (More Isolated)
```hcl
# Platform team creates MORE subnets in Pattern 1:
subnets = {
  "aks-subnet"            = { address_prefixes = ["10.1.1.0/24"] }  # Pattern 1 AKS
  "app-subnet"            = { address_prefixes = ["10.1.2.0/24"] }  # Pattern 1 apps
  "crm-app-subnet"        = { address_prefixes = ["10.1.3.0/24"] }  # CRM team only
  "ecommerce-aks-subnet"  = { address_prefixes = ["10.1.4.0/24"] }  # E-commerce team only
  "marketing-app-subnet"  = { address_prefixes = ["10.1.5.0/24"] }  # Marketing team only
}

# Then Pattern 2 CRM uses:
data "azurerm_subnet" "app_service" {
  name = "crm-app-subnet"  ← Dedicated subnet for CRM
}
```

**Pros:**
- ✅ Better isolation between teams
- ✅ Easier to apply team-specific NSG rules
- ✅ Easier to track network costs per team

**Cons:**
- ❌ More complex setup
- ❌ Need to plan IP address ranges carefully
- ❌ Inter-team communication requires peering/routes

**Recommendation for Demo:**
- Use **Option 1** (shared subnets) - simpler to explain
- Mention **Option 2** exists for production environments

### What Happens If Platform Team Changes Something?

This is CRITICAL to understand for production use!

#### Scenario 1: Platform Team Changes Subnet Name

```hcl
# Before (Platform team's main.tf):
subnets = {
  "app-subnet" = { address_prefixes = ["10.1.2.0/24"] }
}

# Platform team renames:
subnets = {
  "application-subnet" = { address_prefixes = ["10.1.2.0/24"] }  ← RENAMED!
}

# Platform runs terraform apply
# Result: Old subnet deleted, new subnet created
```

**Impact on Pattern 2 CRM team:**
```
❌ ERROR: CRM deployment fails!

Error: Error reading subnet "app-subnet": Not found

CRM's data block still looks for "app-subnet" but it doesn't exist anymore!
```

**Solution:**
```hcl
# CRM team must UPDATE their data block:
data "azurerm_subnet" "app_service" {
  name = "application-subnet"  ← Update to match new name
}

# Then redeploy
```

**Lesson:** Platform team changes can BREAK Pattern 2 apps! Need coordination!

#### Scenario 2: Platform Team Changes Subnet CIDR

```hcl
# Before:
"app-subnet" = { address_prefixes = ["10.1.2.0/24"] }  # 256 IPs

# After:
"app-subnet" = { address_prefixes = ["10.1.2.0/23"] }  # 512 IPs (larger)
```

**Impact on Pattern 2:**
```
⚠️ WARNING: May cause downtime!

Terraform will:
1. Destroy old subnet (disconnects all apps!)
2. Create new subnet (apps reconnect)

Result: Brief outage for CRM App Service
```

**Solution:** 
- Coordinate with app teams before making network changes
- Or create a NEW subnet instead of modifying existing

#### Scenario 3: Platform Team Deletes the VNet

```hcl
# Platform team runs:
terraform destroy

# This deletes EVERYTHING in Pattern 1's state:
# - VNet
# - Subnets
# - AKS
# - CosmosDB
```

**Impact on Pattern 2:**
```
💥 CATASTROPHIC: All Pattern 2 apps break immediately!

CRM App Service: No network connectivity (subnet gone!)
E-commerce AKS: Nodes can't communicate (VNet gone!)

Result: Complete application failure
```

**Lesson:** NEVER destroy shared infrastructure while apps depend on it!

#### Scenario 4: Platform Team Adds a New NSG Rule

```hcl
# Platform team adds:
network_security_groups = {
  "app-nsg" = {
    security_rules = {
      "block-port-8080" = {  # NEW RULE
        priority                   = 200
        direction                  = "Inbound"
        access                     = "Deny"
        destination_port_range     = "8080"
      }
    }
  }
}
```

**Impact on Pattern 2:**
```
✅ SAFE: Pattern 2 apps automatically inherit new NSG rules

If CRM app uses port 8080: Traffic blocked (may break app)
If CRM app uses port 3000: No impact
```

**Lesson:** NSG changes affect ALL apps on that subnet!

### Limitations & Gotchas When Using Both Patterns

| Limitation | Description | Workaround |
|------------|-------------|------------|
| **Name coupling** | Pattern 2 data blocks hardcode Pattern 1 resource names | Document naming convention clearly |
| **Change coordination** | Platform changes can break Pattern 2 apps | Use variables for shared resource names |
| **No automatic updates** | Pattern 2 apps don't auto-update when Platform changes | Pattern 2 teams must monitor Platform changes |
| **Blast radius** | Pattern 1 VNet deletion breaks ALL Pattern 2 apps | Use Terraform locks on shared resources |
| **IP exhaustion** | Limited IP space in existing subnets | Plan subnet sizes carefully upfront |
| **State file coupling** | Can't move resources between Pattern 1 and Pattern 2 states easily | Design boundaries carefully before implementing |

### Best Practices for Using Both Patterns Together

#### 1. **Use Variables for Shared Resource Names**

Instead of hardcoding in Pattern 2:
```hcl
# BAD - Hardcoded:
data "azurerm_virtual_network" "landing_zone" {
  name = "vnet-contoso-dev-001"  ← Hardcoded!
}

# GOOD - Variable:
data "azurerm_virtual_network" "landing_zone" {
  name = var.shared_vnet_name  ← From variable!
}

# In dev.tfvars:
shared_vnet_name = "vnet-contoso-dev-001"
```

**Benefit:** If Platform team renames VNet, Pattern 2 teams only update ONE variable.

#### 2. **Document Shared Resources**

Create a shared reference file:
```yaml
# docs/SHARED-RESOURCES.md
# Shared Infrastructure (Platform Team Owned)

Dev Environment:
  VNet Name: vnet-contoso-dev-001
  Resource Group: rg-contoso-dev-network-001
  Subnets:
    - aks-subnet: 10.1.1.0/24 (for Kubernetes workloads)
    - app-subnet: 10.1.2.0/24 (for App Services, Container Apps)
  
  DO NOT DELETE THESE RESOURCES!
  Contact: platform-team@company.com before making changes
```

#### 3. **Use Terraform Locks on Shared Resources**

```hcl
# In Platform team's main.tf:
resource "azurerm_management_lock" "vnet_lock" {
  name       = "vnet-do-not-delete"
  scope      = azurerm_virtual_network.main.id
  lock_level = "CanNotDelete"
  notes      = "VNet is shared by multiple app teams. Contact platform team before deletion."
}
```

**Benefit:** Prevents accidental VNet deletion!

#### 4. **Coordinate Changes via Pull Requests**

**Process:**
1. Platform team creates PR to change subnet name
2. PR description lists all affected Pattern 2 apps
3. Pattern 2 teams review and prepare updates
4. Platform team merges after coordination
5. Pattern 2 teams update their data blocks

#### 5. **Monitor Shared Resources**

Set up Azure Monitor alerts:
```
Alert: "Shared VNet Modified"
Trigger: Any change to vnet-contoso-dev-001
Action: Email all app team leads
```

---

## VNet Impact: The Critical Shared Component

### Understanding the VNet Dependency

When using Pattern 1 and Pattern 2 together, the **VNet is the glue** that connects everything. This creates a **strong dependency** that you must manage carefully.

```
┌────────────────────────────────────────────────────────────────┐
│                     Single Shared VNet                          │
│                  (Created by Pattern 1)                         │
│                                                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐        │
│  │ Pattern 1    │  │ Pattern 2    │  │ Pattern 2    │        │
│  │ AKS (shared) │  │ CRM App      │  │ E-com AKS    │        │
│  │              │  │ Service      │  │ (dedicated)  │        │
│  └───────┬──────┘  └───────┬──────┘  └───────┬──────┘        │
│          │                 │                 │                │
│          └─────────────────┼─────────────────┘                │
│                            │                                   │
│                    All use same subnets                        │
│                    All share same NSG rules                    │
│                    All in same IP address space                │
└────────────────────────────────────────────────────────────────┘
```

### VNet Impact Matrix

| Change | Pattern 1 Impact | Pattern 2 Impact | Risk Level | Recovery Time |
|--------|------------------|------------------|------------|---------------|
| **Add new subnet** | ✅ No impact | ✅ No impact (unless they need it) | 🟢 Low | N/A |
| **Delete unused subnet** | ✅ No impact | ✅ No impact (if not using it) | 🟢 Low | N/A |
| **Rename subnet** | ⚠️ Terraform will recreate | ❌ All apps using it break | 🔴 Critical | 1-4 hours |
| **Change subnet CIDR** | ⚠️ Brief outage | ⚠️ Brief outage | 🟡 Medium | 5-30 minutes |
| **Add NSG rule** | ✅ Applies automatically | ✅ Applies automatically | 🟢 Low | Instant |
| **Delete VNet** | 💥 Entire environment destroyed | 💥 All apps fail | 🔴 Critical | 4-8 hours+ |
| **Add VNet peering** | ✅ More connectivity | ✅ More connectivity | 🟢 Low | Instant |
| **Change DNS servers** | ⚠️ All pods/apps affected | ⚠️ All apps affected | 🟡 Medium | Instant |

### Critical VNet Scenarios Explained

#### Scenario 1: Platform Team Renames a Subnet

**Initial State:**
```hcl
# Pattern 1 creates:
subnets = {
  "aks-subnet" = { address_prefixes = ["10.1.1.0/24"] }
}

# Pattern 2 CRM references:
data "azurerm_subnet" "app_service" {
  name = "aks-subnet"  ← Works fine
}
```

**Platform team changes:**
```hcl
# Pattern 1 changes to:
subnets = {
  "kubernetes-subnet" = { address_prefixes = ["10.1.1.0/24"] }  # RENAMED!
}

# terraform apply
```

**What happens:**
1. Terraform destroys old subnet "aks-subnet"
2. Creates new subnet "kubernetes-subnet"
3. **Pattern 1 AKS cluster gets new subnet** (brief downtime)
4. **Pattern 2 CRM app immediately breaks:**
   ```
   Error: data.azurerm_subnet.app_service: subnet "aks-subnet" not found
   ```

**Impact severity:**
- 🔴 **Critical**: All Pattern 2 apps using this subnet fail immediately
- 💥 **Downtime**: Until Pattern 2 teams update their code
- 📞 **Coordination required**: Must notify ALL Pattern 2 teams BEFORE making change

**Prevention:**
```hcl
# Use Terraform moved blocks (requires Terraform 1.1+):
moved {
  from = azurerm_subnet.subnets["aks-subnet"]
  to   = azurerm_subnet.subnets["kubernetes-subnet"]
}
```

#### Scenario 2: IP Address Space Exhaustion

**Problem:**
```
Pattern 1 uses:
- aks-subnet: 10.1.1.0/24 (254 IPs)
- app-subnet: 10.1.2.0/24 (254 IPs)

Pattern 2 CRM team: Uses app-subnet (needs 10 IPs)
Pattern 2 E-commerce: Uses app-subnet (needs 10 IPs)
Pattern 2 Marketing: Uses app-subnet (needs 10 IPs)
... 20 more Pattern 2 teams ...

Result: app-subnet runs out of IPs! ❌
```

**Solution: Plan subnet sizes upfront**
```hcl
# Better subnet allocation:
subnets = {
  "aks-subnet"           = { address_prefixes = ["10.1.0.0/22"] }   # 1024 IPs (large)
  "pattern1-app-subnet"  = { address_prefixes = ["10.1.4.0/24"] }   # 256 IPs (Pattern 1 apps)
  "pattern2-app-subnet"  = { address_prefixes = ["10.1.5.0/23"] }   # 512 IPs (Pattern 2 apps)
  "pattern2-db-subnet"   = { address_prefixes = ["10.1.7.0/24"] }   # 256 IPs (Pattern 2 databases)
}
```

**Rule of thumb:**
- AKS: `/22` or larger (1000+ IPs per cluster)
- App Services: `/24` (256 IPs) per 50 apps
- Databases: `/24` (256 IPs) per 100 databases

#### Scenario 3: NSG Rule Affects Everyone

**Scenario:**
```hcl
# Platform team adds security rule:
network_security_groups = {
  "app-nsg" = {
    security_rules = {
      "block-rdp" = {  # NEW RULE - Block RDP for security
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Deny"
        protocol                   = "Tcp"
        destination_port_range     = "3389"
      }
    }
  }
}
```

**Impact:**
- ✅ Pattern 1 apps: No impact (shouldn't use RDP anyway)
- ✅ Pattern 2 CRM: No impact (RDP not needed)
- ❌ Pattern 2 Troubleshooting team: Can't RDP to debug (but that's the point!)

**Lesson:** NSG rules affect EVERYONE on that subnet. Communicate before adding restrictive rules!

#### Scenario 4: Multiple AKS Clusters, One VNet

**Configuration:**
```
VNet: 10.1.0.0/16

Pattern 1 AKS (shared):
  - aks-subnet: 10.1.1.0/24
  - Nodes: 3-10 nodes
  - Used by: Team Alpha, Team Beta

Pattern 2 E-commerce AKS (dedicated):
  - ecommerce-aks-subnet: 10.1.2.0/24
  - Nodes: 2-5 nodes
  - Used by: E-commerce team only

Pattern 2 Marketing AKS (dedicated):
  - marketing-aks-subnet: 10.1.3.0/24
  - Nodes: 1-3 nodes
  - Used by: Marketing team only
```

**VNet capacity check:**
```
Total VNet: 10.1.0.0/16 = 65,536 IPs

Used:
  - aks-subnet: 256 IPs
  - ecommerce-aks-subnet: 256 IPs
  - marketing-aks-subnet: 256 IPs
  - app-subnet: 256 IPs
  Total: 1,024 IPs

Available: 64,512 IPs (plenty of room!) ✅
```

**Risk:** If each Pattern 2 team creates their own AKS cluster, you could have 20+ AKS clusters in ONE VNet. This works but:
- 💰 Cost: 20 AKS clusters = $1,500+/month management fees alone
- 🔧 Complexity: Hard to manage
- 📊 Monitoring: Need to monitor 20 separate clusters

**Recommendation:** Use Pattern 1's shared AKS when possible. Only create dedicated AKS (Pattern 2) when:
- Compliance requires isolation
- Different Kubernetes versions needed
- Different security requirements

### VNet Design Best Practices for Mixed Patterns

#### 1. **Plan Your IP Address Space**

```hcl
# GOOD - Organized by purpose:
address_space = ["10.1.0.0/16"]  # 65,536 IPs total

subnets = {
  # Pattern 1 resources (shared):
  "shared-aks-subnet"     = { address_prefixes = ["10.1.0.0/22"] }   # 1024 IPs
  "shared-app-subnet"     = { address_prefixes = ["10.1.4.0/24"] }   # 256 IPs
  
  # Pattern 2 resources (delegated):
  "pattern2-aks-pool"     = { address_prefixes = ["10.1.8.0/21"] }   # 2048 IPs (multiple AKS)
  "pattern2-app-pool"     = { address_prefixes = ["10.1.16.0/20"] }  # 4096 IPs (many apps)
  "pattern2-db-pool"      = { address_prefixes = ["10.1.32.0/20"] }  # 4096 IPs (databases)
  
  # Management:
  "bastion-subnet"        = { address_prefixes = ["10.1.255.0/27"] } # 32 IPs
}
```

#### 2. **Document VNet Ownership**

Create `docs/VNET-ALLOCATION.md`:
```markdown
# VNet IP Allocation - Dev Environment

VNet: vnet-contoso-dev-001 (10.1.0.0/16)

## Pattern 1 Subnets (Platform Team Managed)
| Subnet | CIDR | IPs | Purpose | Used By |
|--------|------|-----|---------|---------|
| shared-aks-subnet | 10.1.0.0/22 | 1024 | Pattern 1 AKS | Team Alpha, Beta |
| shared-app-subnet | 10.1.4.0/24 | 256 | Pattern 1 App Services | Team Alpha |

## Pattern 2 Subnets (App Team Managed)
| Subnet | CIDR | IPs | Purpose | Contact |
|--------|------|-----|---------|---------|
| crm-app-subnet | 10.1.16.0/26 | 64 | CRM App Service | crm-team@company.com |
| ecommerce-aks-subnet | 10.1.20.0/24 | 256 | E-commerce AKS | ecommerce-team@company.com |

## Rules
1. Contact platform-team@ before creating new subnets
2. Use smallest subnet size needed (don't waste IPs)
3. Document any subnet delegation requirements
```

#### 3. **Use Resource Locks on VNet**

```hcl
# In Pattern 1's main.tf:
resource "azurerm_management_lock" "vnet_lock" {
  name       = "do-not-delete-vnet"
  scope      = azurerm_virtual_network.main.id
  lock_level = "CanNotDelete"
  notes      = "VNet is shared by 15 applications. Deletion requires CTO approval."
}
```

**Benefit:** Prevents accidental VNet deletion even if someone runs `terraform destroy`!

#### 4. **Monitor VNet Changes**

Set up Azure Monitor alert:
```json
{
  "alertName": "VNet Configuration Changed",
  "description": "Alert when vnet-contoso-dev-001 is modified",
  "condition": {
    "resourceType": "Microsoft.Network/virtualNetworks",
    "resourceName": "vnet-contoso-dev-001",
    "operation": "Microsoft.Network/virtualNetworks/write"
  },
  "actions": [
    {
      "actionType": "email",
      "recipients": [
        "platform-team@company.com",
        "app-team-leads@company.com"
      ]
    }
  ]
}
```

#### 5. **Version Control for Shared Resources**

```yaml
# .github/CODEOWNERS (or Azure DevOps equivalent)
# Require platform team approval for VNet changes

infra/envs/dev/main.tf        @platform-team
infra/modules/networking/      @platform-team

# Pattern 2 teams can self-approve
examples/pattern-2-delegated/dev-app-crm/      @crm-team
examples/pattern-2-delegated/dev-app-ecommerce/ @ecommerce-team
```

### Summary: VNet is the Foundation

```
┌─────────────────────────────────────────────────────────────┐
│                      Key Principles                          │
│                                                              │
│  1. VNet is created ONCE by Platform team                   │
│  2. ALL Pattern 1 and Pattern 2 apps share the same VNet    │
│  3. VNet changes affect EVERYONE simultaneously              │
│  4. Coordinate VNet changes across ALL teams                 │
│  5. Use Terraform locks to prevent accidental deletion       │
│  6. Plan IP space for 2-3 years of growth                   │
│  7. Document subnet allocation clearly                       │
│  8. Monitor VNet changes with alerts                         │
│                                                              │
│  Remember: VNet is infrastructure - shared forever!          │
│            Applications can be Pattern 1 or Pattern 2        │
└─────────────────────────────────────────────────────────────┘
```

---

## Comparison Table

| Aspect | Pattern 1: Centralized | Pattern 2: Delegated |
|--------|----------------------|---------------------|
| **Who controls resources?** | Platform team only | Each app team |
| **Number of state files** | 1 per environment | 1 per app per environment |
| **Team independence** | Low - must request changes | High - self-service |
| **Risk of conflicts** | Higher - one state file shared | Lower - separate state files |
| **Speed of deployment** | Slower - bottleneck at platform team | Faster - teams work in parallel |
| **Consistency** | Very high - one place to control | Medium - teams follow conventions |
| **Complexity** | Lower - easier to understand | Higher - more folders to manage |
| **Best for** | Small org (< 5 teams) | Large org (5+ teams) |
| **Blast radius** | Entire environment | Only one application |
| **Networking** | Created directly in main.tf | Referenced via `data` blocks |
| **Module usage** | Via `module` blocks with `source` | Via `module` blocks + `data` blocks |
| **State file example** | `dev.terraform.tfstate` | `dev-app-crm.tfstate` |
| **Folder structure** | `infra/envs/dev/` | `pattern-2/dev-app-crm/` |

---

## When to Use Which Pattern

### Use Pattern 1 (Centralized) When:

- ✅ You have a small team (< 5 teams)
- ✅ One team manages all infrastructure
- ✅ You want maximum consistency
- ✅ You're just starting with Terraform
- ✅ Simple applications that share everything

### Use Pattern 2 (Delegated) When:

- ✅ You have many teams (5+ teams)
- ✅ Teams need to work independently
- ✅ Each team has different schedules
- ✅ You want to limit the blast radius
- ✅ Teams have their own budgets/cost centers
- ✅ Compliance requires separation of duties

### You Can Use Both!

Most organizations **start with Pattern 1** and **gradually move to Pattern 2** as they grow:

```
Phase 1 (Month 1-3): Pattern 1
  → Platform team sets up everything
  → All teams use one main.tf
  → Simple, easy to learn

Phase 2 (Month 3-6): Hybrid
  → Platform team keeps shared infra in Pattern 1
  → Mature teams get their own folders (Pattern 2)
  → New teams still use Pattern 1

Phase 3 (Month 6+): Pattern 2
  → All teams have their own folders
  → Platform team only manages shared infra
  → Full self-service
```

---

## Advantages and Disadvantages

### Pattern 1: Centralized

**Advantages:**
| # | Advantage | Why It Matters |
|---|-----------|---------------|
| 1 | Single source of truth | All infra in one place, easy to audit |
| 2 | Strong consistency | One team ensures standards are followed |
| 3 | Simpler to understand | Beginners can learn easily |
| 4 | Easier to debug | All resources in one state file |
| 5 | Clear ownership | One team, one responsibility |

**Disadvantages:**
| # | Disadvantage | Impact |
|---|-------------|--------|
| 1 | Bottleneck | Platform team becomes a chokepoint |
| 2 | Large state file | Slow plan/apply as resources grow |
| 3 | Blast radius | One mistake can affect all services |
| 4 | Team friction | App teams wait for platform team |
| 5 | Scaling issues | Doesn't work well with 10+ teams |

### Pattern 2: Delegated

**Advantages:**
| # | Advantage | Why It Matters |
|---|-----------|---------------|
| 1 | Team independence | Teams don't wait for each other |
| 2 | Small blast radius | CRM mistake doesn't affect e-commerce |
| 3 | Fast state operations | Small state files = fast plan/apply |
| 4 | Clear cost tracking | Each team's cost is visible |
| 5 | Parallel development | All teams can deploy simultaneously |

**Disadvantages:**
| # | Disadvantage | Impact |
|---|-------------|--------|
| 1 | More complex | More folders, more state files to manage |
| 2 | Consistency risk | Teams might drift from standards |
| 3 | Requires maturity | Teams need Terraform knowledge |
| 4 | Data source coupling | `data` blocks must match shared infra names exactly |
| 5 | More pipelines | Each team may need their own pipeline |

---

## Visual: Pattern 1 vs Pattern 2 Architecture

### Pattern 1 Architecture

```
┌─────────────────────────────────────────────────────┐
│                ONE STATE FILE                        │
│                                                      │
│  ┌───────────────────────────────────────────────┐  │
│  │          infra/envs/dev/main.tf               │  │
│  │                                                │  │
│  │  ┌─────────┐ ┌─────────┐ ┌─────────┐        │  │
│  │  │  AKS    │ │ CosmosDB│ │Container│        │  │
│  │  │ Module  │ │ Module  │ │App Mod. │        │  │
│  │  └────┬────┘ └────┬────┘ └────┬────┘        │  │
│  │       │           │           │               │  │
│  │       └───────────┼───────────┘               │  │
│  │                   ▼                            │  │
│  │          ┌────────────────┐                   │  │
│  │          │   Networking   │                   │  │
│  │          │    Module      │                   │  │
│  │          └────────────────┘                   │  │
│  └───────────────────────────────────────────────┘  │
│                                                      │
│  State: dev.terraform.tfstate                        │
└─────────────────────────────────────────────────────┘
```

### Pattern 2 Architecture

```
┌──────────────────────┐
│  SHARED (Platform)   │
│  State: dev.tfstate  │
│  ┌────────────────┐  │
│  │  VNet/Subnets  │  │
│  │  Log Analytics │  │
│  │  DNS Zones     │  │
│  └───────┬────────┘  │
└──────────┼───────────┘
           │ (data source reference)
    ┌──────┼──────┐
    ▼      ▼      ▼
┌────────┐┌────────┐┌────────┐
│CRM Team││EComm.  ││Market. │
│        ││Team    ││Team    │
│State:  ││State:  ││State:  │
│crm.tf  ││ecom.tf ││mkt.tf  │
│state   ││state   ││state   │
│        ││        ││        │
│AppSvc  ││AKS     ││Contain.│
│Cosmos  ││Cosmos  ││Postgre │
│KeyVlt  ││KeyVlt  ││KeyVlt  │
└────────┘└────────┘└────────┘
  3 SEPARATE STATE FILES
```

---

## Key Takeaway for Demo

> **"Pattern 1 is like an apartment building (one landlord controls everything). Pattern 2 is like a housing estate (each house owner manages their own property, but they share roads and electricity)."**

For the client demo, show:
1. **Pattern 1 first** - Show how simple it is to enable AKS with one toggle
2. **Pattern 2 second** - Show how two teams can work simultaneously
3. **Explain the growth path** - Start with Pattern 1, migrate to Pattern 2

---

*Previous: [03 - How Files Connect](03-HOW-FILES-CONNECT.md)* | *Next: [05 - Demo Scenario Step by Step →](05-DEMO-SCENARIO-STEP-BY-STEP.md)*
