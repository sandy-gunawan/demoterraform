# Document 04: Pattern 1 Demo — Centralized Deployment

> **Test Case**: Platform team deploys ALL shared infrastructure using a single `main.tf` with feature toggles.
> This is a **standalone test case** — can be run independently for CI/CD pipeline demos.

---

## What Is Pattern 1?

**Pattern 1 = One team controls everything.** A central Platform/DevOps team manages a single `main.tf` that deploys all resources for an environment.

### Analogy: Apartment Building

Think of Pattern 1 like an **apartment building**:
- The **building manager** (Platform team) controls all shared facilities
- **Tenants** (app teams) request features: "I need a gym" → manager adds it
- Only the manager has the keys to the building systems
- Everything is in **one building** (one state file)

### Where It Lives

```
infra/envs/dev/
├── backend.tf       ← Where state is stored (shared filing cabinet)
├── main.tf          ← ONE file controls ALL resources
├── variables.tf     ← All variable definitions
├── dev.tfvars       ← All values for dev environment
└── outputs.tf       ← What gets exported
```

### Key Characteristics

| Feature | How It Works |
|---------|-------------|
| **Who deploys?** | Platform team only |
| **State file** | 1 per environment (`dev.terraform.tfstate`) |
| **How teams request?** | Teams ask Platform team to toggle features on/off |
| **Control mechanism** | Feature toggles (boolean `true`/`false`) |
| **Best for** | Small teams (< 5), starting with Terraform |

---

## Architecture

```
┌─────────────────────────────────────────────────┐
│              Platform Team (Andi)                │
│         infra/envs/dev/main.tf                  │
│                                                  │
│  Feature Toggles:                               │
│  ├── enable_aks = true            → AKS ✅      │
│  ├── enable_cosmosdb = true       → CosmosDB ✅ │
│  ├── enable_container_apps = true → ContainerApp│
│  ├── enable_postgresql = true     → PostgreSQL  │
│  └── enable_webapp = false        → (skip) ❌   │
│                                                  │
│  ALL created in ONE state file:                  │
│  dev.terraform.tfstate                          │
└─────────────────────────────────────────────────┘
```

---

## Step-by-Step Demo

### Pre-requisites

- Azure CLI installed (`az --version`)
- Terraform installed (`terraform --version`)
- Azure subscription access
- Git clone of this repository

### STEP 1: Create State Storage (One-Time Setup)

Before Terraform can run, we need storage for state files.

```powershell
# Login to Azure
az login

# Set your subscription
az account set --subscription "Your-Subscription-ID"

# Option A: Use the helper script (recommended)
./scripts/init-backend.ps1

# Option B: Manual creation
az group create \
  --name contoso-tfstate-rg \
  --location indonesiacentral

az storage account create \
  --name stcontosotfstate001 \
  --resource-group contoso-tfstate-rg \
  --location indonesiacentral \
  --sku Standard_GRS

az storage container create \
  --name tfstate \
  --account-name stcontosotfstate001
```

> **Explain to client**: "This storage account is like a shared filing cabinet. Every team's Terraform state is stored here, but in separate files so they don't interfere with each other."

### STEP 2: Deploy Foundation (Networking + Monitoring)

```powershell
# Navigate to dev environment
cd infra/envs/dev

# Initialize Terraform (downloads plugins, connects to state)
terraform init

# Preview what will be created
terraform plan -var-file="dev.tfvars"

# Expected output:
# Plan: ~8 to add, 0 to change, 0 to destroy.
#   + azurerm_resource_group.main
#   + module.networking.azurerm_virtual_network.vnet          (10.1.0.0/16)
#   + module.networking_crm.azurerm_virtual_network.vnet      (10.2.0.0/16)
#   + module.networking_ecommerce.azurerm_virtual_network.vnet (10.3.0.0/16)
#   + azurerm_log_analytics_workspace.main
#   + module.security[0].azurerm_key_vault.kv

# Apply (creates the resources)
terraform apply -var-file="dev.tfvars"
# Type "yes" when prompted
```

**What was created:**

```
Azure Resources:
├── Resource Group: contoso-platform-rg-dev
│   ├── VNet: 10.1.0.0/16 (shared services)
│   │   ├── aks-subnet (10.1.1.0/24)
│   │   └── app-subnet (10.1.2.0/24)
│   ├── VNet: 10.2.0.0/16 (CRM app — for Pattern 2)
│   │   └── crm-app-subnet (10.2.1.0/24)
│   ├── VNet: 10.3.0.0/16 (E-commerce app — for Pattern 2)
│   │   └── ecom-aks-subnet (10.3.1.0/24)
│   ├── Log Analytics: platform-logs-dev
│   └── Key Vault: platformkvdev
```

> **Key point**: Platform creates ALL 3 VNets — including the ones Pattern 2 teams will use later!

### STEP 3: Enable AKS + CosmosDB (Team Alpha's Request)

Team Alpha lead (Budi) asks: *"We need AKS and CosmosDB for our microservices."*

Andi simply changes two booleans in `dev.tfvars`:

```hcl
enable_aks      = true    # ← Changed from false to true
enable_cosmosdb = true    # ← Changed from false to true
```

```powershell
terraform plan -var-file="dev.tfvars"

# Expected: Plan: 2-3 to add
#   + module.aks[0].azurerm_kubernetes_cluster.aks
#   + module.cosmosdb[0].azurerm_cosmosdb_account.db
# (networking already exists — no changes!)

terraform apply -var-file="dev.tfvars"
```

> **Explain**: "One line change deploys an entire AKS cluster with best practices — correct subnet, proper tags, monitoring attached. The developer doesn't need to know Terraform."

### STEP 4: Enable Container Apps + PostgreSQL (Team Beta's Request)

Team Beta lead (Citra) asks: *"We need Container Apps and PostgreSQL."*

```hcl
enable_container_apps = true    # ← Changed from false to true
enable_postgresql     = true    # ← Changed from false to true
```

```powershell
terraform plan -var-file="dev.tfvars"

# Expected: Plan: ~4 to add
#   + module.container_apps[0].azurerm_container_app_environment.env
#   + module.postgresql[0].azurerm_postgresql_flexible_server.pg
# (everything else already exists!)

terraform apply -var-file="dev.tfvars"
```

### Final State After Pattern 1

```
State file: dev.terraform.tfstate

Azure Resources:
├── contoso-platform-rg-dev
│   ├── VNet 10.1.0.0/16 (shared services)
│   ├── VNet 10.2.0.0/16 (CRM VNet — ready for Pattern 2)
│   ├── VNet 10.3.0.0/16 (E-commerce VNet — ready for Pattern 2)
│   ├── Log Analytics, Key Vault
│   ├── AKS (Team Alpha)          ← Feature toggle: ON
│   ├── CosmosDB (Team Alpha)     ← Feature toggle: ON
│   ├── Container Apps (Team Beta) ← Feature toggle: ON
│   └── PostgreSQL (Team Beta)     ← Feature toggle: ON
```

---

## CI/CD Test Commands

Use these commands in Azure DevOps pipeline to validate Pattern 1:

```yaml
# Pipeline: ci-terraform-plan.yml
steps:
  - name: Pattern 1 - Validate
    run: |
      cd infra/envs/dev
      terraform init -backend=false
      terraform validate

  - name: Pattern 1 - Plan
    run: |
      cd infra/envs/dev
      terraform init
      terraform plan -var-file="dev.tfvars" -out=tfplan

  - name: Pattern 1 - Apply (CD only)
    run: |
      cd infra/envs/dev
      terraform apply tfplan
```

### Automated Validation Script

```powershell
# scripts/validate-pattern1.ps1
cd infra/envs/dev
terraform init -backend=false
terraform validate
if ($LASTEXITCODE -ne 0) { exit 1 }
terraform fmt -check
if ($LASTEXITCODE -ne 0) { exit 1 }
Write-Host "Pattern 1: All checks passed!"
```

---

## Pattern 1 Advantages & Disadvantages

### Advantages
1. **Single source of truth** — Everything in one place
2. **Strong consistency** — Same naming, tags, settings everywhere
3. **Simple to understand** — One folder, one state file
4. **Easy to debug** — All resources visible in one plan
5. **Clear ownership** — Platform team responsible for everything

### Disadvantages
1. **Bottleneck** — All changes go through Platform team
2. **Large state file** — Gets slow as resources grow
3. **Blast radius** — One bad change affects everything
4. **Team friction** — Teams wait for Platform team
5. **Scaling issues** — Hard to manage 20+ services in one file

---

## Key Demo Talking Points

| Time | Show | Say |
|------|------|-----|
| 0-5 min | Folder structure | "One folder controls the entire dev environment" |
| 5-10 min | `dev.tfvars` feature toggles | "Boolean switches control what gets deployed" |
| 10-15 min | `terraform plan` output | "Preview exactly what changes before applying" |
| 15-20 min | Azure Portal resources | "Everything consistently named and tagged" |

> **Key takeaway**: "Pattern 1 is perfect for getting started — one team, one file, complete control. When your organization grows, you can evolve to Pattern 2."

---

*Previous: [03 - How Files Connect](03-HOW-FILES-CONNECT.md)* | *Next: [05 - Pattern 2 Demo →](05-PATTERN2-DEMO.md)*
