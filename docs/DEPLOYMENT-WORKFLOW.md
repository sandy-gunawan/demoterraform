# Deployment Workflow Guide

**Common Question:** "I deployed my foundation + AKS last week. Now I want to add a Web App. Do I need to re-deploy everything?"

**Short Answer:** No! Terraform tracks what's already deployed and only creates new resources.

---

## 🔄 How It Works: Once vs Every Time

### The Key Principle

**Terraform State** = A record of what resources currently exist

When you run `terraform apply`:
1. Terraform reads the state file (what exists now)
2. Compares it to your configuration (what you want)
3. Only creates/modifies/deletes what's different

---

## 📊 Deployment Lifecycle Example

### Week 1: Initial Setup (Platform Team)

```powershell
# Step 1: Deploy Global Standards (ONCE ONLY)
cd infra/global
terraform init
terraform apply

# What gets created:
# ✅ Naming conventions
# ✅ Tagging standards
# ✅ Provider configuration
# State: Stored in Azure Storage (contoso-tfstate-rg)
```

### Week 1: Foundation Setup

```powershell
# Step 2: Deploy Landing Zone (ONCE ONLY)
cd infra/envs/dev

# Edit dev.tfvars - enable what you need:
enable_aks = true
enable_cosmosdb = false
enable_webapp = false

# Deploy
terraform init
terraform plan -var-file=dev.tfvars
terraform apply -var-file=dev.tfvars

# What gets created:
# ✅ Resource Group
# ✅ Virtual Network (10.1.0.0/16)
# ✅ Subnets (aks-subnet, app-subnet)
# ✅ Network Security Groups
# ✅ Log Analytics Workspace
# ✅ AKS Cluster (because enable_aks = true)
#
# State: dev.terraform.tfstate (in Azure Storage)
```

**✅ Result:** Your foundation is deployed. State file tracks everything.

---

### Week 2: Add Cosmos DB (No Re-deployment)

```powershell
# Same directory: infra/envs/dev

# Edit dev.tfvars:
enable_aks = true          # ← KEEP TRUE (don't change existing)
enable_cosmosdb = true     # ← ENABLE NEW SERVICE
enable_webapp = false

# Preview changes
terraform plan -var-file=dev.tfvars
```

**What Terraform Shows:**

```
Terraform will perform the following actions:

  # azurerm_cosmosdb_account.db[0] will be created
  + resource "azurerm_cosmosdb_account" "db" {
      + name     = "contoso-cosmos-dev"
      + location = "southeastasia"
      ...
    }

Plan: 1 to add, 0 to change, 0 to destroy.

---
📝 Notice:
  - Resource Group: No changes (already exists)
  - VNet: No changes (already exists)
  - AKS: No changes (already exists)
  - Cosmos DB: Will be created ← NEW!
```

```powershell
# Apply the changes
terraform apply -var-file=dev.tfvars
```

**✅ Result:** Only Cosmos DB is created. VNet, AKS untouched.

---

### Week 3: Add Web App

```powershell
# Same directory: infra/envs/dev

# Edit dev.tfvars:
enable_aks = true          # ← Keep existing
enable_cosmosdb = true     # ← Keep existing
enable_webapp = true       # ← Enable new service

terraform plan -var-file=dev.tfvars
# Shows: Only Web App will be created

terraform apply -var-file=dev.tfvars
```

**✅ Result:** Only Web App is created. Everything else unchanged.

---

## 🗂️ State File Evolution

Think of the state file as a living inventory:

```
WEEK 1: State File Contents
┌─────────────────────────────────────┐
│ dev.terraform.tfstate               │
├─────────────────────────────────────┤
│ ✅ Resource Group                   │
│ ✅ VNet (10.1.0.0/16)              │
│ ✅ Subnets                          │
│ ✅ NSGs                             │
│ ✅ Log Analytics Workspace          │
│ ✅ AKS Cluster                      │
└─────────────────────────────────────┘

WEEK 2: State File (After Adding Cosmos DB)
┌─────────────────────────────────────┐
│ dev.terraform.tfstate               │
├─────────────────────────────────────┤
│ ✅ Resource Group                   │
│ ✅ VNet (10.1.0.0/16)              │
│ ✅ Subnets                          │
│ ✅ NSGs                             │
│ ✅ Log Analytics Workspace          │
│ ✅ AKS Cluster                      │
│ ✅ Cosmos DB Account        ← NEW   │
└─────────────────────────────────────┘

WEEK 3: State File (After Adding Web App)
┌─────────────────────────────────────┐
│ dev.terraform.tfstate               │
├─────────────────────────────────────┤
│ ✅ Resource Group                   │
│ ✅ VNet (10.1.0.0/16)              │
│ ✅ Subnets                          │
│ ✅ NSGs                             │
│ ✅ Log Analytics Workspace          │
│ ✅ AKS Cluster                      │
│ ✅ Cosmos DB Account                │
│ ✅ Web App                  ← NEW   │
└─────────────────────────────────────┘
```

---

## ⚠️ Critical Warning: Disabling Features

**BE CAREFUL:** Setting a feature to `false` **DELETES** that resource!

```powershell
# ❌ DANGER: This will DELETE your AKS cluster!
enable_aks = false
terraform apply
# Terraform will show:
# Plan: 0 to add, 0 to change, 15 to destroy. ← ALL AKS RESOURCES!

# ✅ SAFE: Keep it enabled if you want to keep it
enable_aks = true
```

### Safe Practice

If you want to **temporarily stop using** a service without deleting it:
1. Keep the toggle `true`
2. Scale it down (if applicable)
3. Or comment out the module in `main.tf` instead of changing tfvars

---

## 🔀 Common Workflows

### Adding a New Service

```powershell
# 1. Edit dev.tfvars
# Change: enable_cosmosdb = false
# To:     enable_cosmosdb = true

# 2. Preview
terraform plan -var-file=dev.tfvars

# 3. Review output - should only create Cosmos DB resources

# 4. Apply
terraform apply -var-file=dev.tfvars
```

### Modifying Existing Service

```powershell
# 1. Edit dev.tfvars
# Change: aks_node_count = 1
# To:     aks_node_count = 2

# 2. Preview
terraform plan -var-file=dev.tfvars
# Shows: azurerm_kubernetes_cluster.aks will be updated in-place

# 3. Apply
terraform apply -var-file=dev.tfvars
```

### Removing a Service (CAREFUL!)

```powershell
# 1. Edit dev.tfvars
# Change: enable_webapp = true
# To:     enable_webapp = false

# 2. Preview - PAY ATTENTION!
terraform plan -var-file=dev.tfvars
# Shows: Plan: 0 to add, 0 to change, 5 to destroy.

# 3. Confirm you really want to delete
terraform apply -var-file=dev.tfvars
# Type: yes (only if you're sure!)
```

---

## 🏗️ Multi-Environment Strategy

Each environment has its **own state file**:

```
State Storage in Azure
├── dev.terraform.tfstate       ← Dev environment
├── staging.terraform.tfstate   ← Staging environment
└── prod.terraform.tfstate      ← Prod environment

Changes to dev → ONLY affects dev.terraform.tfstate
Changes to prod → ONLY affects prod.terraform.tfstate
```

### Deploying to Multiple Environments

```powershell
# Deploy to Dev
cd infra/envs/dev
terraform apply -var-file=dev.tfvars

# Test in Dev, then deploy to Staging
cd ../staging
terraform apply -var-file=staging.tfvars

# Test in Staging, then deploy to Prod
cd ../prod
terraform apply -var-file=prod.tfvars
```

---

## 📋 Quick Reference

| Question | Answer |
|----------|--------|
| Do I re-deploy global? | ❌ No, it's deployed once and outputs are referenced |
| Do I re-deploy landing-zone (VNet/NSGs)? | ❌ No, it stays in state and is reused |
| How do I add a new service? | ✅ Enable the toggle in `.tfvars`, run `terraform apply` |
| Will it recreate my VNet? | ❌ No, Terraform sees it exists in state |
| Will it recreate my AKS? | ❌ No, unless you changed AKS-specific settings |
| What if I disable a toggle? | ⚠️ **Terraform will DELETE that resource!** |
| Can I see what will change? | ✅ Yes! Always run `terraform plan` first |
| What if I make a mistake? | ✅ State is backed up in Azure Storage, can be recovered |

---

## 🎯 Best Practices

### 1. Always Preview First

```powershell
terraform plan -var-file=dev.tfvars
# Read the output carefully!
# Look for: "Plan: X to add, Y to change, Z to destroy"
```

### 2. Never Manually Delete State

The state file is Terraform's memory. If you delete it:
- Terraform forgets what exists
- Can't manage existing resources
- May try to recreate everything

**Always use `terraform destroy` to remove resources.**

### 3. Use Version Control for .tfvars

```powershell
git add infra/envs/dev/dev.tfvars
git commit -m "feat: enable Cosmos DB in dev"
git push
```

### 4. Keep Feature Toggles True

If a service is deployed and you want to keep it:
```hcl
# ✅ GOOD: Keeps the service
enable_aks = true

# ❌ BAD: Deletes the service
enable_aks = false
```

### 5. Test in Dev First

```
Dev (test changes) → Staging (validate) → Prod (deploy)
```

---

## 🔧 Troubleshooting

### "Terraform wants to recreate everything!"

**Cause:** State file is out of sync or missing

**Fix:**
```powershell
# Re-initialize backend
terraform init -reconfigure

# Import existing resources if needed
terraform import azurerm_resource_group.main /subscriptions/.../resourceGroups/contoso-rg-dev
```

### "Error: Resource already exists"

**Cause:** Resource exists in Azure but not in state

**Fix:**
```powershell
# Import the existing resource
terraform import <resource_type>.<name> <azure_resource_id>

# Example:
terraform import azurerm_virtual_network.vnet /subscriptions/.../virtualNetworks/contoso-vnet-dev
```

### "How do I see what's in my state?"

```powershell
# List all resources in state
terraform state list

# Show details of a specific resource
terraform state show azurerm_kubernetes_cluster.aks[0]
```

---

## 📚 Related Documentation

- [Getting Started Guide](GETTING-STARTED.md) - Initial deployment walkthrough
- [Feature Toggles](GETTING-STARTED.md#33-feature-toggles---choose-what-to-deploy) - Understanding toggles
- [How Everything Connects](HOW-EVERYTHING-CONNECTS.md) - Architecture overview

---

## 🏗️ Complete Architecture: Multiple Apps (Visual Guide)

This section shows the complete stack from Global Standards down to Database level for multiple applications.

---

### Option A: Shared Infrastructure (Recommended)

**Use Case:** Multiple apps from same team/org share resources

```
┌─────────────────────────────────────────────────────────────────────────┐
│  Layer 1: GLOBAL STANDARDS (Deployed ONCE)                              │
│  ═══════════════════════════════════════════════════════════════════════│
│  infra/global/                                                           │
│  ├── Naming Convention: ${org}-${project}-${env}-${service}            │
│  ├── Tags: cost_center, owner, environment                              │
│  └── Provider Config: Azure RM with OIDC                                │
│                                                                          │
│  State: global.tfstate (in Azure Storage)                               │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ↓
┌─────────────────────────────────────────────────────────────────────────┐
│  Layer 2: LANDING ZONE (Dev Environment - Deployed ONCE)                │
│  ═══════════════════════════════════════════════════════════════════════│
│  infra/envs/dev/                                                         │
│                                                                          │
│  📦 Resource Group: contoso-rg-dev                                      │
│  └── Location: southeastasia                                            │
│                                                                          │
│  🌐 Virtual Network: contoso-vnet-dev (10.1.0.0/16)                      │
│  ├── Subnet: aks-subnet (10.1.1.0/24)                                  │
│  │   └── Service Endpoints: KeyVault, CosmosDB                          │
│  ├── Subnet: app-subnet (10.1.2.0/24)                                  │
│  │   └── Service Endpoints: KeyVault, CosmosDB                          │
│  └── Subnet: data-subnet (10.1.3.0/24)                                 │
│                                                                          │
│  🛡️  Network Security Groups                                           │
│  ├── aks-nsg: Allow 443 (HTTPS)                                        │
│  └── app-nsg: Allow 443 from VNet                                      │
│                                                                          │
│  📊 Log Analytics: contoso-logs-dev                                       │
│  └── Retention: 30 days                                                 │
│                                                                          │
│  State: dev.tfstate (in Azure Storage)                                  │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                    ┌───────────────┴───────────────┐
                    ↓                               ↓
┌─────────────────────────────────────┐  ┌────────────────────────────────┐
│  Layer 3: COMPUTE (Shared AKS)      │  │  Layer 3: COMPUTE (App Service)│
│  ═══════════════════════════════════│  │  ══════════════════════════════│
│  AKS Cluster: contoso-aks-dev       │  │  App Service Plan              │
│  ├── VNet: contoso-vnet-dev         │  │  └── SKU: B1 (Basic)           │
│  ├── Subnet: aks-subnet             │  │                                │
│  ├── Nodes: 1x Standard_B2s         │  │  Web App: contoso-app3-dev      │
│  └── Azure CNI networking           │  │  ├── Runtime: .NET/Node/Python │
│                                     │  │  ├── HTTPS Only: true          │
│  ┌─────────────────────────────┐   │  │  └── Managed Identity: enabled │
│  │ Namespace: app1             │   │  └────────────────────────────────┘
│  │ ─────────────────────────── │   │                  │
│  │ 📦 Deployment: app1-api     │   │                  ↓
│  │    ├── Replicas: 2          │   │       ┌──────────────────────┐
│  │    ├── Image: app1:latest   │   │       │ 🗄️ Cosmos DB         │
│  │    └── Env Vars (from KV)   │   │       │ ────────────────────│
│  │                              │   │       │ Account: contoso-db   │
│  │ 🌐 Service: app1-svc        │   │       │ Database: app3-db   │
│  │    ├── Type: LoadBalancer   │   │       │ Container: items    │
│  │    └── Port: 80 → 8080      │   │       │ Partition: /userId  │
│  │                              │   │       │ Throughput: 400 RUs │
│  │ 🔗 Ingress: app1.dev.com   │   │       └──────────────────────┘
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ Namespace: app2             │   │
│  │ ─────────────────────────── │   │
│  │ 📦 Deployment: app2-api     │   │
│  │    ├── Replicas: 2          │   │
│  │    ├── Image: app2:latest   │   │
│  │    └── Env Vars (from KV)   │   │
│  │                              │   │
│  │ 🌐 Service: app2-svc        │   │
│  │    ├── Type: LoadBalancer   │   │
│  │    └── Port: 80 → 8080      │   │
│  │                              │   │
│  │ 🔗 Ingress: app2.dev.com   │   │
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘
                │
                ↓
┌─────────────────────────────────────────────────────────────────────────┐
│  Layer 4: DATA LAYER (Shared Cosmos DB)                                 │
│  ═══════════════════════════════════════════════════════════════════════│
│  Cosmos DB Account: contoso-cosmos-dev                                     │
│  ├── API: SQL (Core)                                                    │
│  ├── Consistency: Session                                               │
│  ├── Public Access: Enabled (dev only)                                  │
│  └── Connected via Service Endpoint from VNet                           │
│                                                                          │
│  📚 Database: app1-database                                             │
│  │   ├── Container: users (Partition: /userId, 400 RUs)                │
│  │   ├── Container: orders (Partition: /customerId, 400 RUs)           │
│  │   └── Used by: AKS App1                                              │
│                                                                          │
│  📚 Database: app2-database                                             │
│  │   ├── Container: products (Partition: /categoryId, 400 RUs)         │
│  │   ├── Container: inventory (Partition: /warehouseId, 400 RUs)       │
│  │   └── Used by: AKS App2                                              │
│                                                                          │
│  📚 Database: app3-database                                             │
│      ├── Container: items (Partition: /userId, 400 RUs)                │
│      └── Used by: App Service                                           │
│                                                                          │
│  🔒 Security                                                            │
│  ├── Authentication: Managed Identity from AKS & App Service            │
│  ├── Network: VNet Service Endpoint                                     │
│  └── Backup: Periodic (8 hours)                                         │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ↓
┌─────────────────────────────────────────────────────────────────────────┐
│  Layer 5: SECRETS MANAGEMENT                                            │
│  ═══════════════════════════════════════════════════════════════════════│
│  Key Vault: myappkvdev                                                   │
│  ├── Cosmos DB Connection Strings                                       │
│  │   ├── app1-cosmos-connection (used by App1 pods)                    │
│  │   ├── app2-cosmos-connection (used by App2 pods)                    │
│  │   └── app3-cosmos-connection (used by App Service)                  │
│  ├── API Keys                                                           │
│  └── Certificates                                                        │
│                                                                          │
│  🔒 Access via Managed Identity (no keys in code!)                     │
└─────────────────────────────────────────────────────────────────────────┘
```

**Key Points for Option A:**
- ✅ **1 AKS Cluster** shared by App1 and App2 (using Kubernetes namespaces)
- ✅ **1 Cosmos DB Account** with separate databases per app
- ✅ **1 Virtual Network** - all apps communicate internally
- ✅ **1 Terraform State** - all managed together
- 💰 **Lower Cost** - Shared load balancer, shared node pools
- 🔧 **Simpler Operations** - One cluster to manage

**Connection Flow Example (App1 → Cosmos DB):**
```
User Request
    ↓
Ingress (app1.dev.com)
    ↓
Service (app1-svc)
    ↓
Pod (app1-api container)
    ↓
Managed Identity → Key Vault (get connection string)
    ↓
Service Endpoint → Cosmos DB (app1-database)
    ↓
Response back to user
```

---

### Option B: Separate Infrastructure (For Strict Isolation)

**Use Case:** Different customers/tenants, strict compliance, independent teams

```
┌─────────────────────────────────────────────────────────────────────────┐
│  Layer 1: GLOBAL STANDARDS (Deployed ONCE - Shared by All Apps)         │
│  ═══════════════════════════════════════════════════════════════════════│
│  infra/global/ (SAME as Option A)                                       │
│  └── Shared naming conventions, tags, provider config                   │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                    ┌───────────────┴───────────────┬───────────────────┐
                    ↓                               ↓                   ↓
┌─────────────────────────────┐  ┌──────────────────────────┐  ┌─────────────────────────┐
│  Layer 2: LANDING ZONE      │  │  Layer 2: LANDING ZONE   │  │  Layer 2: LANDING ZONE  │
│  (App1 - Isolated)          │  │  (App2 - Isolated)       │  │  (App3 - Isolated)      │
│  ═══════════════════════════│  │  ════════════════════════│  │  ═══════════════════════│
│  infra/envs/dev-app1/       │  │  infra/envs/dev-app2/    │  │  infra/envs/dev-app3/   │
│                             │  │                          │  │                         │
│  📦 RG: app1-rg-dev         │  │  📦 RG: app2-rg-dev      │  │  📦 RG: app3-rg-dev     │
│                             │  │                          │  │                         │
│  🌐 VNet: app1-vnet-dev     │  │  🌐 VNet: app2-vnet-dev  │  │  🌐 VNet: app3-vnet-dev │
│     (10.1.0.0/16)           │  │     (10.2.0.0/16)        │  │     (10.3.0.0/16)       │
│  ├── aks-subnet             │  │  ├── aks-subnet          │  │  ├── app-subnet         │
│  ├── data-subnet            │  │  ├── data-subnet         │  │  └── data-subnet        │
│  └── NSGs                   │  │  └── NSGs                │  │                         │
│                             │  │                          │  │  📊 Logs: app3-logs     │
│  📊 Logs: app1-logs-dev     │  │  📊 Logs: app2-logs-dev  │  │                         │
│                             │  │                          │  │  State: dev-app3.tfstate│
│  State: dev-app1.tfstate    │  │  State: dev-app2.tfstate │  └─────────────────────────┘
└─────────────────────────────┘  └──────────────────────────┘              │
                │                              │                            │
                ↓                              ↓                            ↓
┌─────────────────────────────┐  ┌──────────────────────────┐  ┌─────────────────────────┐
│  Layer 3: COMPUTE           │  │  Layer 3: COMPUTE        │  │  Layer 3: COMPUTE       │
│  ═══════════════════════════│  │  ════════════════════════│  │  ═══════════════════════│
│  AKS: app1-aks-dev          │  │  AKS: app2-aks-dev       │  │  App Service Plan       │
│  ├── Nodes: 1x B2s          │  │  ├── Nodes: 1x B2s       │  │  └── SKU: B1            │
│  └── Subnet: aks-subnet     │  │  └── Subnet: aks-subnet  │  │                         │
│                             │  │                          │  │  Web App: app3-dev      │
│  Namespace: default (only)  │  │  Namespace: default      │  │  └── Runtime: Node.js   │
│  ├── Deployment: app1-api   │  │  ├── Deployment: app2    │  └─────────────────────────┘
│  ├── Service: app1-svc      │  │  └── Service: app2-svc   │              │
│  └── Ingress: app1.com      │  └──────────────────────────┘              │
└─────────────────────────────┘              │                             │
                │                            │                             │
                ↓                            ↓                             ↓
┌─────────────────────────────┐  ┌──────────────────────────┐  ┌─────────────────────────┐
│  Layer 4: DATA (Isolated)   │  │  Layer 4: DATA (Isolated)│  │  Layer 4: DATA          │
│  ═══════════════════════════│  │  ════════════════════════│  │  ═══════════════════════│
│  Cosmos: app1-cosmos-dev    │  │  Cosmos: app2-cosmos-dev │  │  Cosmos: app3-cosmos    │
│  ├── Database: users-db     │  │  ├── Database: products  │  │  ├── Database: items-db │
│  └── Container: users       │  │  └── Container: items    │  │  └── Container: data    │
│     Partition: /userId      │  │     Partition: /category │  │     Partition: /userId  │
│     RUs: 400                │  │     RUs: 400             │  │     RUs: 400            │
│                             │  │                          │  │                         │
│  🔒 Private Endpoint        │  │  🔒 Private Endpoint     │  │  🔒 Private Endpoint    │
│     (prod only)             │  │     (prod only)          │  │     (prod only)         │
└─────────────────────────────┘  └──────────────────────────┘  └─────────────────────────┘
                │                              │                            │
                ↓                              ↓                            ↓
┌─────────────────────────────┐  ┌──────────────────────────┐  ┌─────────────────────────┐
│  Layer 5: SECRETS           │  │  Layer 5: SECRETS        │  │  Layer 5: SECRETS       │
│  ═══════════════════════════│  │  ════════════════════════│  │  ═══════════════════════│
│  KeyVault: app1kvdev        │  │  KeyVault: app2kvdev     │  │  KeyVault: app3kvdev    │
│  └── app1-cosmos-conn       │  │  └── app2-cosmos-conn    │  │  └── app3-cosmos-conn   │
└─────────────────────────────┘  └──────────────────────────┘  └─────────────────────────┘
```

**Key Points for Option B:**
- ❌ **Separate AKS Clusters** - Complete isolation
- ❌ **Separate Cosmos DB Accounts** - No shared data plane
- ❌ **Separate VNets** - No network connectivity between apps
- ❌ **Multiple Terraform States** - Managed independently
- 💰 **Higher Cost** - 3x everything (clusters, load balancers, etc.)
- 🔒 **Maximum Security** - Zero cross-app communication
- 🎯 **Clear Ownership** - Each team fully owns their infrastructure

**Use Cases for Option B:**
- Multi-tenant SaaS (Customer A, Customer B, Customer C)
- Compliance requirements (PCI-DSS, HIPAA)
- Different teams with different SLAs
- Security-critical production workloads

---

### 🔄 Hybrid Approach (Recommended for Real-World)

**Dev/Staging:** Use Option A (Shared - save cost)  
**Production:** Use Option B (Separate - maximize security)

```
Environment Strategy:
├── Dev (Shared)
│   ├── 1 AKS cluster with App1, App2, App3
│   └── 1 Cosmos DB with multiple databases
│   Monthly Cost: ~$300
│
├── Staging (Shared)
│   ├── 1 AKS cluster with App1, App2, App3
│   └── 1 Cosmos DB with multiple databases
│   Monthly Cost: ~$800
│
└── Production (Separated by criticality)
    ├── Critical App1 (Separate)
    │   ├── Dedicated AKS + Cosmos DB
    │   └── Monthly Cost: ~$3,000
    │
    ├── Critical App2 (Separate)
    │   ├── Dedicated AKS + Cosmos DB
    │   └── Monthly Cost: ~$3,000
    │
    └── Internal App3 (Shared with App4, App5)
        ├── Shared AKS + Cosmos DB
        └── Monthly Cost: ~$2,000 total
```

---

## 💡 Key Takeaway

**Terraform is incremental, not all-or-nothing.**

You deploy your foundation once, then add services over time by:
1. Enabling the feature toggle
2. Running `terraform apply`
3. Only new resources are created

No need to redeploy everything each time! 🎉

---

## 🤝 Team Collaboration Models

How your teams work with this Terraform framework depends on your organizational structure.

### Pattern 1: Centralized (Platform Team Manages)

**Who:** Platform/SRE/DevOps team manages ALL Terraform  
**Best for:** Organizations starting their cloud journey, or strict governance requirements

```
terraform-framework/
├── infra/
│   ├── global/                ← Platform team manages (Layer 0)
│   ├── envs/
│   │   ├── dev/               ← Platform team manages (Layer 1 + 2)
│   │   │   ├── main.tf        ← Contains Landing Zone + Workloads
│   │   │   ├── dev.tfvars     ← Feature toggles (what to deploy)
│   │   │   └── backend.tf
│   │   └── prod/              ← Platform team manages (Layer 1 + 2)
│   │       ├── main.tf
│   │       └── prod.tfvars
│   └── modules/               ← Shared modules
```

**How it works:**
- App teams request infrastructure via ticket/form
- Platform team enables toggles and deploys
- App teams deploy applications to provisioned infrastructure

**Pros:**
- ✅ Consistent standards enforced
- ✅ Easier compliance auditing
- ✅ Centralized cost control

**Cons:**
- ❌ Platform team can become bottleneck
- ❌ App teams lack autonomy

---

### Pattern 2: Delegated (App Teams Manage Their Own)

**Who:** Each app team manages their own workload Terraform  
**Best for:** Mature organizations with experienced teams

```
terraform-framework/
├── infra/
│   ├── global/                ← Platform team: Global standards
│   ├── envs/
│   │   ├── dev-shared/        ← Platform team: Landing Zone
│   │   │   ├── main.tf        ← VNet, subnets, NSGs, logs
│   │   │   └── dev.tfvars
│   │   ├── dev-app-ecommerce/ ← E-commerce team: Workloads
│   │   │   ├── main.tf        ← AKS, Cosmos DB, Key Vault
│   │   │   └── dev.tfvars
│   │   ├── dev-app-crm/       ← CRM team: Workloads
│   │   │   ├── main.tf        ← App Service, Cosmos DB
│   │   │   └── dev.tfvars
│   │   └── prod-shared/       ← Platform team: Landing Zone
│   │       ├── main.tf
│   │       └── prod.tfvars
│   └── modules/               ← Shared reusable modules
```

**How it works:**
- Platform team maintains global + Landing Zone (foundation)
- Each app team has their own folder and state file
- App teams self-service their infrastructure needs
- All teams use SAME module structure from `modules/`

**Pros:**
- ✅ App teams have autonomy
- ✅ Faster iteration cycles
- ✅ Clear ownership boundaries

**Cons:**
- ❌ Requires training investment
- ❌ Risk of inconsistent configurations
- ❌ More complex CI/CD setup

---

### Pattern 3: Hybrid (Gradual Delegation)

**Who:** Start centralized, gradually delegate  
**Best for:** Most organizations (recommended starting point)

**Phase 1 (Month 1-3):**
```
Platform team manages everything
App teams learn by observing
```

**Phase 2 (Month 4-6):**
```
Platform team: Global + Landing Zone + Databases
App teams: Compute resources (AKS namespaces, App Service plans)
```

**Phase 3 (Month 7+):**
```
Platform team: Global + Landing Zone only
App teams: Everything else (workloads)
```

**Pros:**
- ✅ Gradual learning curve
- ✅ De-risk the transition
- ✅ Build team capability over time

**Cons:**
- ❌ Longer transition period
- ❌ Requires change management

---

### 📊 Comparison Table

| Aspect | Centralized | Delegated | Hybrid |
|--------|-------------|-----------|--------|
| **App Team Autonomy** | Low | High | Medium → High |
| **Deployment Speed** | Slower (bottleneck) | Faster | Medium |
| **Consistency** | High | Medium | Medium → High |
| **Training Required** | Low | High | Medium |
| **Best For** | Small teams, strict compliance | Large orgs, mature teams | Growing organizations |
| **Platform Team Size** | 2-3 people | 1-2 people | 2-3 → 1-2 people |

---

### 🎯 Recommendation

**Start with Pattern 1 (Centralized), evolve to Pattern 2 (Delegated):**

1. **Weeks 1-4:** Platform team builds foundation (Global + Landing Zone)
2. **Weeks 5-12:** Platform team deploys first 2-3 apps (learn the patterns)
3. **Weeks 13-24:** Create app team guides, start delegation (Pattern 3)
4. **Month 7+:** Full delegation, platform team maintains foundation only

**All teams use the SAME framework structure** — just organized into different folders!
