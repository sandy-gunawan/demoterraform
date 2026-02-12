# Can You Use Both Pattern 1 and Pattern 2 at the Same Time?

## **YES! Platform creates all VNets, Pattern 2 teams focus on apps!**

> **✨ KEY ARCHITECTURE:** Platform team creates **all 3 VNets** (including Pattern 2 app VNets).  
> Pattern 2 teams **read** VNets via data sources → Focus on applications only!

---

## Your Question Answered

**Q: "Can I use Pattern 1 AND Pattern 2 at the same time?"**

**A: YES, absolutely!** This architecture shows the framework's true value:
- ✅ Platform team governs networking (creates all 3 VNets)
- ✅ Pattern 2 teams read VNets via data sources (reusability!)
- ✅ Pattern 2 teams focus on apps (no networking code duplication)
- ✅ Separate state files (team independence)
- ✅ Network isolation (each app has dedicated VNet)

---

## How It Works (Platform-Managed Networking!)

```
Pattern 1 (Platform team creates ALL VNets):
========================================================
VNet 1: 10.1.0.0/16 (shared services)
VNet 2: 10.2.0.0/16 (CRM app - Platform-created!)
VNet 3: 10.3.0.0/16 (E-commerce app - Platform-created!)
Resources: Shared AKS, Shared CosmosDB, Log Analytics
State file: dev.terraform.tfstate

Pattern 2 CRM (Reads Platform's VNet):
========================================================
Reads: data.azurerm_virtual_network.crm (10.2.0.0/16)
Creates: App Service, CosmosDB, Key Vault, Managed Identity
State file: dev-app-crm.tfstate (SEPARATE!)

Pattern 2 E-commerce (Reads Platform's VNet):
========================================================
Reads: data.azurerm_virtual_network.ecommerce (10.3.0.0/16)
Creates: AKS, CosmosDB, Key Vault, Managed Identity
State file: dev-app-ecommerce.tfstate (SEPARATE!)
```

**Result: Platform governs, teams build apps, everyone benefits!**

---

## How It Works

```
Step 1: Platform Team Deploys (infra/envs/dev/)
========================================================
enable_aks = true         ← Creates SHARED AKS
enable_cosmosdb = true    ← Creates SHARED CosmosDB

Result:
✅ VNet: platform-vnet-dev (EVERYONE uses this!)
✅ Subnets: aks-subnet, app-subnet (EVERYONE uses these!)
✅ NSGs, Log Analytics
✅ Shared AKS cluster (Team Alpha & Beta use this)
✅ Shared CosmosDB (Team Alpha uses this)

State file: dev.terraform.tfstate

Step 2: CRM Team Deploys (examples/pattern-2-delegated/dev-app-crm/)
========================================================
data "azurerm_virtual_network" "landing_zone" {
  name = "platform-vnet-dev"  ← Reads Platform's VNet!
}

resource "azurerm_cosmosdb_account" "crm" {
  name = "cosmos-crm-dev"   ← DIFFERENT from Platform's CosmosDB!
}

Result:
✅ Uses same VNet as Pattern 1
✅ Creates OWN CosmosDB (separate from Pattern 1)
✅ Creates OWN App Service
✅ Creates OWN Key Vault

State file: dev-app-crm.tfstate (SEPARATE!)

Step 3: E-commerce Team Deploys (examples/pattern-2-delegated/dev-app-ecommerce/)
========================================================
data "azurerm_virtual_network" "landing_zone" {
  name = "platform-vnet-dev"  ← Reads same Platform VNet!
}

resource "azurerm_kubernetes_cluster" "ecommerce" {
  name = "aks-ecommerce-dev"  ← DIFFERENT from Platform's AKS!
}

Result:
✅ Uses same VNet as Pattern 1
✅ Creates OWN AKS cluster (separate from Pattern 1)
✅ Creates OWN CosmosDB (separate from everyone)
✅ Creates OWN Key Vault

State file: dev-app-ecommerce.tfstate (SEPARATE!)
```

---

## The Result: Three AKS Clusters!

After running the demo, you'll have:

| AKS Cluster | Created By | Used By | State File |
|-------------|-----------|---------|-----------|
| **aks-platform-dev** | Platform (Pattern 1) | Team Alpha, Team Beta | dev.terraform.tfstate |
| **aks-ecommerce-dev** | E-commerce team (Pattern 2) | E-commerce team only | dev-app-ecommerce.tfstate |

And potentially:
| CosmosDB | Created By | Used By | State File |
|----------|-----------|---------|-----------|
| **cosmos-platform-dev** | Platform (Pattern 1) | Team Alpha | dev.terraform.tfstate |
| **cosmos-crm-dev** | CRM team (Pattern 2) | CRM team only | dev-app-crm.tfstate |
| **cosmos-ecommerce-dev** | E-commerce team (Pattern 2) | E-commerce team only | dev-app-ecommerce.tfstate |

**But all use the SAME VNet!**

---

## Visual Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│  Azure Subscription                                               │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  Resource Group: rg-platform-dev                            │ │
│  │  (Pattern 1 - created by Platform team)                     │ │
│  │                                                             │ │
│  │  ✅ VNet: platform-vnet-dev (10.1.0.0/16)                  │ │
│  │     ├── Subnet: aks-subnet (10.1.1.0/24)                   │ │
│  │     └── Subnet: app-subnet (10.1.2.0/24)                   │ │
│  │  ✅ AKS: aks-platform-dev (Team Alpha & Beta use this)     │ │
│  │  ✅ CosmosDB: cosmos-platform-dev (Team Alpha uses this)   │ │
│  │  ✅ Log Analytics (everyone uses this)                      │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  Resource Group: rg-crm-dev                                 │ │
│  │  (Pattern 2 - created by CRM team)                          │ │
│  │                                                             │ │
│  │  🔗 Uses VNet from above (via data source)                 │ │
│  │  ✅ App Service: app-crm-dev                               │ │
│  │  ✅ CosmosDB: cosmos-crm-dev (DIFFERENT!)                  │ │
│  │  ✅ Key Vault: kv-crm-dev                                   │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  Resource Group: rg-ecommerce-dev                           │ │
│  │  (Pattern 2 - created by E-commerce team)                   │ │
│  │                                                             │ │
│  │  🔗 Uses VNet from above (via data source)                 │ │
│  │  ✅ AKS: aks-ecommerce-dev (DIFFERENT!)                    │ │
│  │  ✅ CosmosDB: cosmos-ecommerce-dev (DIFFERENT!)            │ │
│  │  ✅ Key Vault: kv-ecommerce-dev                             │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## Do You Need Option B (New Folder)?

**NO!** For the demo, use the existing `infra/envs/dev/` with `enable_aks=true`.

**Option B (separate `infra/landing-zone/` folder) is ONLY needed if:**
- You want to completely separate the networking code from Pattern 1
- You want cleaner code organization
- You never want to use Pattern 1 at all

**For the demo: Stick with Option A (existing folder with apps enabled)**

---

## Summary: Demo Setup

```bash
# 1. Platform team (Pattern 1)
cd infra/envs/dev
enable_aks=true, enable_cosmosdb=true
terraform apply
# Creates: VNet, AKS, CosmosDB

# 2. CRM team (Pattern 2) - at the SAME time!
cd examples/pattern-2-delegated/dev-app-crm
# Uses data source to read Platform's VNet
terraform apply
# Creates: Own App Service, Own CosmosDB

# 3. E-commerce team (Pattern 2) - at the SAME time!
cd examples/pattern-2-delegated/dev-app-ecommerce
# Uses data source to read Platform's VNet
terraform apply
# Creates: Own AKS, Own CosmosDB
```

**All three deployments coexist!**

---

## Key Takeaway

> **Pattern 1 and Pattern 2 are NOT mutually exclusive. They work TOGETHER!**
>
> - **Pattern 1**: Shared resources (VNet, shared AKS, shared CosmosDB)
> - **Pattern 2**: Independent resources (own AKS, own CosmosDB) that USE the shared VNet
>
> **The demo shows BOTH patterns at once to demonstrate maximum flexibility!**
