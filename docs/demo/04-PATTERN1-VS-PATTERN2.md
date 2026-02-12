# Document 04: Pattern 1 vs Pattern 2 Explained

## The Two Patterns

This framework supports **two patterns** for organizing how teams deploy infrastructure. Understanding when to use each pattern is critical for a successful client demo.

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
