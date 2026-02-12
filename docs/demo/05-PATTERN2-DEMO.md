# Document 05: Pattern 2 Demo — Delegated Per-Team Deployment

> **Test Case**: Application teams deploy independently with their own state files while reading Platform-created networking.
> This is a **standalone test case** — can be run independently for CI/CD pipeline demos.
> **Pre-requisite**: Platform layer must be deployed first (creates VNets that Pattern 2 reads).

---

## What Is Pattern 2?

**Pattern 2 = Each team manages their own infrastructure.** Application teams have their own folders, own state files, and deploy independently. They READ shared networking from Platform team via data sources.

### Analogy: Housing Estate

Think of Pattern 2 like a **housing estate**:
- The **developer** (Platform team) builds roads, electricity, water pipes
- **Homeowners** (app teams) build their own houses on their own plots
- Each homeowner has their **own house keys** (own state file)
- They share roads and utilities (shared VNet), but manage their own property

### Where It Lives

```
examples/pattern-2-delegated/
├── dev-app-crm/              ← CRM team's folder (their "house")
│   ├── main.tf               ← CRM team's resources
│   ├── variables.tf           ← CRM-specific variables
│   ├── dev.tfvars             ← CRM dev values
│   └── outputs.tf             ← CRM outputs
│
└── dev-app-ecommerce/         ← E-commerce team's folder
    ├── main.tf                ← E-commerce resources
    ├── variables.tf            ← E-commerce variables
    ├── dev.tfvars              ← E-commerce dev values
    └── outputs.tf              ← E-commerce outputs
```

### Key Characteristics

| Feature | How It Works |
|---------|-------------|
| **Who deploys?** | Each application team independently |
| **State file** | 1 per team per environment (`dev-app-crm.tfstate`) |
| **Networking** | Read from Platform via `data` sources (not created!) |
| **Control mechanism** | Each team manages their own `main.tf` |
| **Best for** | Large orgs (5+ teams), teams needing independence |

---

## Architecture

```
┌────────────────────────────────────────────┐
│      Platform Layer (infra/platform/)      │
│     Creates ALL VNets with governance      │
│                                            │
│  VNet 10.1.0.0/16 → Shared services       │
│  VNet 10.2.0.0/16 → CRM app              │
│  VNet 10.3.0.0/16 → E-commerce app       │
│                                            │
│  State: platform-dev.tfstate               │
└──────────────┬─────────────┬───────────────┘
               │             │
     ┌─────────▼──────┐  ┌──▼──────────────┐
     │  CRM Team      │  │  E-commerce     │
     │  (Dewi)        │  │  (Eka)          │
     │                │  │                  │
     │  READS:        │  │  READS:          │
     │  VNet 10.2.x   │  │  VNet 10.3.x    │
     │                │  │                  │
     │  CREATES:      │  │  CREATES:        │
     │  App Service   │  │  AKS Cluster     │
     │  CosmosDB      │  │  CosmosDB        │
     │  Key Vault     │  │  Key Vault       │
     │                │  │                  │
     │  State:        │  │  State:           │
     │  dev-app-crm   │  │  dev-app-ecom    │
     └────────────────┘  └──────────────────┘
```

### How `data` Sources Work (for Newbies)

In Pattern 2, teams don't create networking — they **read** what Platform layer created:

```hcl
# CRM team's main.tf — READS Platform layer's VNet (doesn't create it!)
data "azurerm_virtual_network" "crm" {
  name                = "vnet-contoso-dev-crm-001"        # Platform layer created this
  resource_group_name = "contoso-platform-rg-dev"         # Platform layer's resource group
}

# Inherit tags from global standards (same as platform)
module "global_standards" {
  source = "../../../infra/global"
  # ...
}

# Now use it:
resource "azurerm_linux_web_app" "crm" {
  virtual_network_subnet_id = data.azurerm_subnet.crm_app.id  # Reference, not create!
  tags = module.global_standards.common_tags                    # Consistent tags!
}
```

> **Think of it like renting**: Platform team built the road (VNet). CRM team uses the road to get to their house — they didn't build the road themselves!

---

## Step-by-Step Demo

### Pre-requisite: Platform Layer Must Run First!

Pattern 2 teams READ networking that Platform layer creates. Deploy platform first:
```powershell
# Platform layer creates all VNets (including Pattern 2 VNets)
cd infra/platform/dev
terraform init
terraform apply -var-file="dev.tfvars"
# This creates VNet 10.1.x (shared), 10.2.x (CRM) and 10.3.x (E-commerce)
```

> **Why?** Platform team governs ALL networking. Pattern 2 teams focus only on applications. This is the framework's governance model!

---

### TEST CASE A: CRM Team (Dewi) — App Service + CosmosDB

#### Step A.1: Navigate to CRM Folder

```powershell
cd examples/pattern-2-delegated/dev-app-crm
```

#### Step A.2: Initialize with Separate State

```powershell
terraform init
# State file: dev-app-crm.tfstate (SEPARATE from Pattern 1!)
```

#### Step A.3: Review and Deploy

```powershell
terraform plan -var-file="dev.tfvars"

# Expected output:
# Data sources will READ (not create):
#   data.azurerm_virtual_network.crm     → VNet 10.2.0.0/16
#   data.azurerm_subnet.crm_app          → Subnet 10.2.1.0/24
#
# Will CREATE:
#   + azurerm_resource_group (rg-contoso-dev-crm-001)
#   + azurerm_service_plan
#   + azurerm_linux_web_app (app-contoso-dev-crm-001)
#   + azurerm_cosmosdb_account (cosmos-contoso-dev-crm-001)
#   + azurerm_cosmosdb_sql_database
#   + azurerm_cosmosdb_sql_container (customers)
#   + azurerm_cosmosdb_sql_container (interactions)
#   + azurerm_key_vault (kv-contoso-dev-crm)
#   + azurerm_user_assigned_identity

terraform apply -var-file="dev.tfvars"
```

#### CRM Resources Created

```
State: dev-app-crm.tfstate (SEPARATE!)

READS from Platform (via data sources):
├── VNet: 10.2.0.0/16 (Platform-created)
│   └── crm-app-subnet: 10.2.1.0/24

CREATES (CRM team manages these):
├── rg-contoso-dev-crm-001
│   ├── App Service Plan + Web App
│   │   └── Connected to Platform's VNet via subnet
│   ├── CosmosDB (crm-db)
│   │   ├── Container: customers (/companyId)
│   │   └── Container: interactions (/customerId)
│   ├── Key Vault (secrets)
│   └── Managed Identity (secure auth)
```

---

### TEST CASE B: E-commerce Team (Eka) — AKS + CosmosDB

> **Key Point**: E-commerce can deploy AT THE SAME TIME as CRM — no conflicts! Different state files, different VNets.

#### Step B.1: Navigate to E-commerce Folder

```powershell
# Can run in a DIFFERENT terminal, simultaneously with CRM!
cd examples/pattern-2-delegated/dev-app-ecommerce
```

#### Step B.2: Initialize with Separate State

```powershell
terraform init
# State file: dev-app-ecommerce.tfstate (SEPARATE!)
```

#### Step B.3: Review and Deploy

```powershell
terraform plan -var-file="dev.tfvars"

# Expected output:
# Data sources will READ:
#   data.azurerm_virtual_network.ecommerce → VNet 10.3.0.0/16
#   data.azurerm_subnet.ecom_aks           → Subnet 10.3.1.0/24
#
# Will CREATE:
#   + azurerm_resource_group (rg-contoso-dev-ecommerce-001)
#   + azurerm_kubernetes_cluster (aks-contoso-dev-ecommerce-001)
#   + azurerm_cosmosdb_account (cosmos-contoso-dev-ecommerce-001)
#   + azurerm_cosmosdb_sql_database
#   + azurerm_cosmosdb_sql_container x3 (products, orders, inventory)
#   + azurerm_key_vault
#   + azurerm_user_assigned_identity

terraform apply -var-file="dev.tfvars"
```

#### E-commerce Resources Created

```
State: dev-app-ecommerce.tfstate (SEPARATE!)

READS from Platform (via data sources):
├── VNet: 10.3.0.0/16 (Platform-created)
│   └── ecom-aks-subnet: 10.3.1.0/24

CREATES (E-commerce team manages these):
├── rg-contoso-dev-ecommerce-001
│   ├── AKS Cluster (2-5 nodes, autoscale)
│   │   └── Connected to Platform's VNet via subnet
│   ├── CosmosDB (ecommerce-db)
│   │   ├── Container: products (/categoryId)
│   │   ├── Container: orders (/customerId)
│   │   └── Container: inventory (/warehouseId)
│   ├── Key Vault (secrets)
│   └── Managed Identity (secure auth)
```

---

## Complete Picture After Platform + Pattern 1 + Pattern 2

```
Azure Subscription
│
├── contoso-tfstate-rg (State Storage — shared by all)
│   └── stcontosotfstate001
│       └── tfstate/
│           ├── platform-dev.tfstate         ← Platform Layer (VNets, Security, Monitoring)
│           ├── dev.terraform.tfstate        ← App Layer Pattern 1 (AKS, CosmosDB, etc.)
│           ├── dev-app-crm.tfstate          ← CRM team - Pattern 2 (apps only)
│           └── dev-app-ecommerce.tfstate    ← E-commerce team - Pattern 2 (apps only)
│
├── contoso-platform-rg-dev (Platform Layer — VNets, Security)
│   ├── VNet 10.1.0.0/16 (shared services)
│   ├── VNet 10.2.0.0/16 (CRM networking)
│   ├── VNet 10.3.0.0/16 (E-commerce networking)
│   ├── Log Analytics, Key Vault
│
├── contoso-apps-rg-dev (App Layer Pattern 1 — Platform team manages)
│   ├── AKS, CosmosDB (Team Alpha)
│   ├── Container Apps (Team Beta)
│   └── PostgreSQL (Team Beta)
│
├── rg-contoso-dev-crm-001 (Pattern 2 — CRM team manages)
│   ├── Reads VNet 10.2.x from Platform
│   ├── App Service, CosmosDB, Key Vault
│   └── Managed Identity
│
└── rg-contoso-dev-ecommerce-001 (Pattern 2 — E-commerce team manages)
    ├── Reads VNet 10.3.x from Platform
    ├── AKS, CosmosDB, Key Vault
    └── Managed Identity
```

---

## CI/CD Test Commands

Use these commands in Azure DevOps pipeline to validate Pattern 2:

```yaml
# CRM Test Case
steps:
  - name: Pattern 2 CRM - Validate
    run: |
      cd examples/pattern-2-delegated/dev-app-crm
      terraform init -backend=false
      terraform validate

  - name: Pattern 2 CRM - Plan
    run: |
      cd examples/pattern-2-delegated/dev-app-crm
      terraform init
      terraform plan -var-file="dev.tfvars" -out=tfplan

  - name: Pattern 2 CRM - Apply (CD only)
    run: |
      cd examples/pattern-2-delegated/dev-app-crm
      terraform apply tfplan

# E-commerce Test Case (can run in parallel!)
  - name: Pattern 2 E-commerce - Validate
    run: |
      cd examples/pattern-2-delegated/dev-app-ecommerce
      terraform init -backend=false
      terraform validate

  - name: Pattern 2 E-commerce - Plan
    run: |
      cd examples/pattern-2-delegated/dev-app-ecommerce
      terraform init
      terraform plan -var-file="dev.tfvars" -out=tfplan
```

### Automated Validation Script

```powershell
# scripts/validate-pattern2.ps1
$apps = @("dev-app-crm", "dev-app-ecommerce")
foreach ($app in $apps) {
    Write-Host "Validating: $app" -ForegroundColor Cyan
    Push-Location "examples/pattern-2-delegated/$app"
    terraform init -backend=false
    terraform validate
    if ($LASTEXITCODE -ne 0) { exit 1 }
    terraform fmt -check
    if ($LASTEXITCODE -ne 0) { exit 1 }
    Pop-Location
    Write-Host "$app: All checks passed!" -ForegroundColor Green
}
```

---

## Pattern 2 Advantages & Disadvantages

### Advantages
1. **Team independence** — Deploy without waiting for Platform team
2. **Small blast radius** — CRM mistake doesn't affect E-commerce
3. **Fast state operations** — Small state files = fast plan/apply
4. **Clear cost tracking** — Each team's resources are in their own RG
5. **Parallel development** — Teams deploy simultaneously

### Disadvantages
1. **More complex** — Multiple folders, state files, pipelines
2. **Consistency risk** — Teams might drift from standards
3. **Requires maturity** — Teams need basic Terraform knowledge
4. **Data source coupling** — If Platform renames VNet, teams break
5. **More pipelines** — Each team needs their own CI/CD pipeline

---

## Pattern 1 vs Pattern 2 Comparison

| Aspect | Pattern 1: Centralized | Pattern 2: Delegated |
|--------|----------------------|---------------------|
| **Who deploys?** | Platform team only | Each app team |
| **State files** | 2 per environment (platform + apps) | 1 per app per environment |
| **Team independence** | Low — must request changes | High — self-service |
| **Conflict risk** | Lower — separated state | Lowest — separate state |
| **Deployment speed** | Slower — bottleneck | Faster — parallel |
| **Consistency** | Very high | High (via global_standards module) |
| **Complexity** | Lower | Higher |
| **Best for** | Small org (< 5 teams) | Large org (5+ teams) |
| **Blast radius** | Platform OR apps (separated) | Only one application |
| **Networking** | Created in platform layer | Read via `data` blocks |
| **Tags** | From global_standards module | From global_standards module |

### Growth Path: Start Simple, Scale Up

Most organizations follow this path:

```
Phase 1 (Month 1-3):   Pattern 1 only → Learn Terraform, simple setup
Phase 2 (Month 3-6):   Hybrid → Mature teams get Pattern 2 folders
Phase 3 (Month 6+):    Pattern 2 → Full self-service for most teams
```

---

## Key Demo Talking Points

| Time | Show | Say |
|------|------|-----|
| 0-5 min | CRM folder structure | "Each team has their own folder and state file" |
| 5-10 min | `data` sources in main.tf | "Teams READ networking from Platform — they don't create it" |
| 10-15 min | Deploy CRM + E-commerce parallel | "Two teams deploying at the same time — zero conflicts!" |
| 15-20 min | State files in Azure Storage | "Three separate state files — complete isolation" |

> **Key takeaway**: "Pattern 2 gives teams independence while Platform maintains governance over networking. The framework ensures consistency through shared modules and naming conventions."

---

## Common Questions

| Question | Answer |
|----------|--------|
| "Can Pattern 2 teams delete the VNet?" | "No! VNet is in Platform layer's state file. Pattern 2 teams can only READ it." |
| "What if Platform renames a VNet?" | "Pattern 2 teams need to update their data source names. This is coordinated." |
| "Can two Pattern 2 teams affect each other?" | "No. Separate VNets, separate state files, separate resource groups." |
| "How do we add a new Pattern 2 team?" | "1) Platform creates new VNet in platform layer. 2) Copy an existing Pattern 2 folder. 3) Update variables." |
| "Do Pattern 2 teams inherit tags?" | "Yes! Via `module \"global_standards\"` — same tags as Platform layer." |
| "What about production?" | "Same structure! Each team has `prod.tfvars` with stronger settings." |

---

*Previous: [04 - Pattern 1 Demo](04-PATTERN1-DEMO.md)* | *Next: [06 - Diagrams Collection →](06-DIAGRAMS.md)*
