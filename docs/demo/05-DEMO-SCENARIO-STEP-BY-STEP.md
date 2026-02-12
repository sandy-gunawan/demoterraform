# Document 05: Demo Scenario - Step by Step

> **🎉 UPDATED:** Pattern 2 now creates **separate VNets**! No dependencies on Platform team!  
> CRM (10.2.x.x), E-commerce (10.3.x.x) - fully independent deployments.

---

## Scenario Overview

You will demo the following scenario to the client:

### The Story

> "We have a company called **Contoso Indonesia** with multiple development teams. We'll show how all teams use the same Terraform framework to deploy their infrastructure consistently - some using shared resources (Pattern 1), others fully independent (Pattern 2)."

### Cast of Characters

| Team | Lead | Responsibility | What They Deploy |
|------|------|---------------|-----------------|
| **Platform Team** | Andi (DevOps Engineer) | Shared infrastructure, standards | VNet, Subnets, Log Analytics, State Storage |
| **Team Alpha** | Budi (Backend Developer) | Core microservices | AKS + CosmosDB (MongoDB) |
| **Team Beta** | Citra (Full-stack Developer) | Secondary services | Container Apps + PostgreSQL |
| **Team Gamma (CRM)** | Dewi (CRM Developer) | CRM application (Pattern 2) | App Service + CosmosDB |
| **Team Delta (E-commerce)** | Eka (E-commerce Developer) | E-commerce API (Pattern 2) | AKS + CosmosDB |

### Demo Flow

```
ACT 1: Foundation Setup (Platform Team)
   → Set up state storage
   → Deploy shared networking
   → This is what EVERY company needs first

ACT 2: Pattern 1 Demo (Team Alpha + Team Beta)
   → Team Alpha: Enable AKS + CosmosDB
   → Team Beta: Add Container Apps + PostgreSQL
   → Show: Same main.tf, feature toggles control what's deployed

ACT 3: Pattern 2 Demo (Team Gamma + Team Delta)
   → Team Gamma: Deploy CRM app independently
   → Team Delta: Deploy E-commerce app independently
   → Show: Separate state files, parallel work, no conflicts
```

---

## ACT 1: Foundation Setup (Platform Team - Andi)

### What Andi Does

Andi is the DevOps engineer. He sets up the foundation that ALL teams will use.

### Step 1.1: Create Terraform State Storage

Before any Terraform can run, we need a place to store state files.

```powershell
# Andi runs this once to create state storage
# This is a one-time setup command

# Login to Azure
az login

# Set subscription
az account set --subscription "Your-Subscription-ID"

# Create resource group for state
az group create \
  --name terraform-state-rg \
  --location southeastasia

# Create storage account (name must be globally unique!)
az storage account create \
  --name tfstatecontosoid \
  --resource-group terraform-state-rg \
  --location southeastasia \
  --sku Standard_LRS \
  --encryption-services blob

# Create containers for state files
az storage container create \
  --name tfstate \
  --account-name tfstatecontosoid
```

> **Explain to client**: "This storage account is like a shared filing cabinet. Every team's Terraform state will be stored here, but in separate files so they don't interfere with each other."

### Step 1.2: Configure the Dev Environment

Andi edits the configuration files:

**File: `infra/envs/dev/backend.tf`**
```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstatecontosoid"
    container_name       = "tfstate"
    key                  = "dev.terraform.tfstate"
    use_azuread_auth     = true
  }
}
```

**File: `infra/envs/dev/dev.tfvars`** (Andi sets initial values)
```hcl
# Basic Configuration
organization_name = "contoso"
project_name      = "platform"
location          = "southeastasia"      # Closest full-featured region to Indonesia
tenant_id         = "YOUR-TENANT-ID"     # Get from: az account show --query tenantId

# Governance
cost_center    = "Platform-Engineering"
owner_email    = "andi@contoso.co.id"
repository_url = "https://dev.azure.com/contoso/terraform-framework"

# Start with ONLY networking and monitoring (no apps yet)
enable_aks            = false
enable_container_apps = false
enable_webapp         = false
enable_cosmosdb       = false
enable_key_vault      = true    # Always have secrets management

# Security - Minimal for dev
enable_nat_gateway         = false
enable_private_endpoints   = false
enable_ddos_protection     = false
key_vault_purge_protection = false
network_acl_default_action = "Allow"

# Monitoring
enable_application_insights = false
enable_diagnostic_settings  = false
log_retention_days          = 30
```

### Step 1.3: Deploy the Foundation

```powershell
# Navigate to dev environment
cd infra/envs/dev

# Initialize Terraform (downloads plugins, connects to state)
terraform init

# Preview what will be created
terraform plan -var-file="dev.tfvars"

# Expected output:
# Plan: 5 to add, 0 to change, 0 to destroy.
#   + azurerm_resource_group.main
#   + module.networking.azurerm_virtual_network.vnet
#   + module.networking.azurerm_subnet.subnets["aks-subnet"]
#   + module.networking.azurerm_subnet.subnets["app-subnet"]
#   + azurerm_log_analytics_workspace.main

# Apply! (creates the resources)
terraform apply -var-file="dev.tfvars"
# Type "yes" when prompted
```

> **Explain to client**: "The foundation is now ready. We have a Virtual Network with 2 subnets (one for AKS, one for apps), Log Analytics for monitoring, and a Key Vault for secrets. This is the base that all teams will build on."

### What Was Created

```
Azure Resources Created:
├── Resource Group: contoso-platform-rg-dev
│   ├── VNet: platform-vnet-dev (10.1.0.0/16)
│   │   ├── Subnet: aks-subnet (10.1.1.0/24)
│   │   └── Subnet: app-subnet (10.1.2.0/24)
│   ├── NSG: aks-nsg (attached to aks-subnet)
│   ├── Log Analytics: platform-logs-dev
│   └── Key Vault: platformkvdev
```

---

## ACT 2: Pattern 1 Demo - Centralized Deployment

### Scene 2A: Team Alpha Requests AKS + CosmosDB

**Story**: Budi (Team Alpha lead) sends a message to Andi:

> "Hi Andi, we need an AKS cluster and CosmosDB (MongoDB API) for our microservices. Can you enable them in dev?"

### Step 2A.1: Andi Enables AKS + CosmosDB

Andi simply changes two lines in `dev.tfvars`:

```hcl
# Team Alpha request: AKS + CosmosDB
enable_aks     = true       # ← Changed from false to true
enable_cosmosdb = true      # ← Changed from false to true
```

### Step 2A.2: Preview and Apply

```powershell
# Still in infra/envs/dev/
terraform plan -var-file="dev.tfvars"

# Expected output:
# Plan: 3 to add, 0 to change, 0 to destroy.
#   + module.aks[0].azurerm_kubernetes_cluster.aks
#   + module.cosmosdb[0].azurerm_cosmosdb_account.db
#   (networking and monitoring already exist - no changes!)

terraform apply -var-file="dev.tfvars"
```

> **Explain to client**: "Notice how simple this was! Andi just changed two boolean values from `false` to `true`. The modules handle all the complexity - AKS automatically connects to the correct subnet, gets the right tags, and has monitoring attached. Budi doesn't need to know any Terraform."

### What Changed

```
Azure Resources (after Team Alpha):
├── Resource Group: contoso-platform-rg-dev
│   ├── VNet: platform-vnet-dev (10.1.0.0/16)     [existing]
│   │   ├── Subnet: aks-subnet (10.1.1.0/24)       [existing]
│   │   └── Subnet: app-subnet (10.1.2.0/24)       [existing]
│   ├── NSG: aks-nsg                                [existing]
│   ├── Log Analytics: platform-logs-dev            [existing]
│   ├── Key Vault: platformkvdev                    [existing]
│   ├── AKS: platform-aks-dev                       [NEW! ✨]
│   │   └── Node Pool: 1x Standard_D8ds_v5
│   └── CosmosDB: platformcosmosdev                 [NEW! ✨]
│       └── API: SQL (can also use MongoDB API)
```

---

### Scene 2B: Team Beta Adds Container Apps + PostgreSQL

**Story**: Citra (Team Beta lead) sends a message:

> "We need Container Apps for our frontend and PostgreSQL for our relational data. Can you add them too?"

### Step 2B.1: Andi Enables Container Apps

Andi changes one more line in `dev.tfvars`:

```hcl
# Team Alpha request (already done)
enable_aks     = true
enable_cosmosdb = true

# Team Beta request: Container Apps
enable_container_apps = true   # ← Changed from false to true
```

### Step 2B.2: Adding PostgreSQL (New Module Addition)

For PostgreSQL, we need to add a module call to `main.tf` since it's not there yet. Andi adds:

**Add to `infra/envs/dev/variables.tf`:**
```hcl
variable "enable_postgresql" {
  description = "Deploy PostgreSQL Flexible Server"
  type        = bool
  default     = false
}

variable "postgresql_admin_password" {
  description = "PostgreSQL admin password"
  type        = string
  sensitive   = true
  default     = ""
}
```

**Add to `infra/envs/dev/main.tf`:**
```hcl
# =============================================================================
# POSTGRESQL - Optional (controlled by feature toggle)
# =============================================================================
module "postgresql" {
  count  = var.enable_postgresql ? 1 : 0
  source = "../../modules/postgresql"

  resource_group_name           = azurerm_resource_group.main.name
  server_name                   = "${var.project_name}-pg-dev"
  location                      = var.location
  administrator_login           = "pgadmin"
  administrator_password        = var.postgresql_admin_password
  sku_name                      = "B_Standard_B1ms"     # Burstable - cheapest for dev
  storage_mb                    = 32768                   # 32 GB
  postgresql_version            = "16"
  backup_retention_days         = 7
  geo_redundant_backup_enabled  = false
  public_network_access_enabled = true                    # OK for dev

  databases = {
    "appdb" = {
      collation = "en_US.utf8"
      charset   = "UTF8"
    }
  }

  firewall_rules = {
    "allow-azure-services" = {
      start_ip_address = "0.0.0.0"
      end_ip_address   = "0.0.0.0"
    }
  }

  tags = module.global_standards.common_tags
}
```

**Update `dev.tfvars`:**
```hcl
# Team Beta request
enable_container_apps = true
enable_postgresql     = true
postgresql_admin_password = "DevP@ssw0rd123!"   # Use Key Vault in prod!
```

### Step 2B.3: Preview and Apply

```powershell
terraform plan -var-file="dev.tfvars"

# Expected output:
# Plan: 4 to add, 0 to change, 0 to destroy.
#   + module.container_apps[0].azurerm_container_app_environment.env
#   + module.postgresql[0].azurerm_postgresql_flexible_server.pg
#   + module.postgresql[0].azurerm_postgresql_flexible_server_database.db["appdb"]
#   + module.postgresql[0].azurerm_postgresql_flexible_server_firewall_rule.rules["allow-azure"]
#   (everything else already exists!)

terraform apply -var-file="dev.tfvars"
```

> **Explain to client**: "Two teams are sharing the same dev environment, but each team's services are independently toggled. If Team Alpha wants to remove AKS temporarily, we set `enable_aks = false` - it doesn't affect Team Beta's Container Apps at all."

### What Changed

```
Azure Resources (after both teams):
├── Resource Group: contoso-platform-rg-dev
│   ├── VNet: platform-vnet-dev                     [existing]
│   ├── Log Analytics: platform-logs-dev            [existing]
│   ├── Key Vault: platformkvdev                    [existing]
│   ├── AKS: platform-aks-dev                       [Team Alpha]
│   ├── CosmosDB: platformcosmosdev                 [Team Alpha]
│   ├── Container App Env: platform-cae-dev          [Team Beta ✨]
│   └── PostgreSQL: platform-pg-dev                  [Team Beta ✨]
│       └── Database: appdb
```

---

## ACT 3: Pattern 2 Demo - Delegated Per-Team (FULLY INDEPENDENT!)

### Setup Context

> **Explain to client**: "Now we'll show Pattern 2. This is for organizations where teams need **maximum independence**. Each team has:
> - Their own folder
> - Their own Terraform state file  
> - Their own VNet and networking (10.2.x for CRM, 10.3.x for E-commerce)
> - They can deploy **without ANY dependencies** on the Platform team or Pattern 1!"

### 🎯 Key Point: NO Prerequisites Needed!

**OLD approach (deprecated):** Pattern 2 teams shared Pattern 1's VNet  
**NEW approach (current):** Each Pattern 2 team creates their OWN VNet!

```
Pattern 1: VNet 10.1.0.0/16 (Optional! Pattern 2 doesn't need it)
CRM Team: VNet 10.2.0.0/16 (Completely isolated!)
E-commerce: VNet 10.3.0.0/16 (Completely isolated!)
```

**Benefits:**
- ✅ No coordination needed with Platform team
- ✅ Deploy in ANY order (Pattern 2 can deploy FIRST!)
- ✅ Perfect for independent CI/CD pipelines
- ✅ Network isolation by default

---

### Scene 3A: Team Gamma (CRM) - Dewi Deploys Independently

**Story**: Dewi (CRM team lead) deploys her team's infrastructure. No need to ask Platform team!

### Step 3A.1: Navigate to CRM Folder

```powershell
# Dewi goes to HER team's folder
cd examples/pattern-2-delegated/dev-app-crm
```

### Step 3A.2: Review What Will Be Created

The CRM team's `main.tf` creates EVERYTHING (networking + apps):

**Networking (CRM's Own):**
1. **VNet** - `vnet-contoso-dev-crm-001` (10.2.0.0/16)
2. **Subnets**:
   - app-subnet: 10.2.1.0/24 (256 IPs for App Services)
   - db-subnet: 10.2.2.0/24 (256 IPs for databases)
3. **NSGs** - Security rules for HTTP/HTTPS

**Application Resources:**
4. **Resource Group** - `rg-contoso-dev-crm-001`
5. **App Service** - `app-contoso-dev-crm-001` (Node.js web app)
6. **CosmosDB** - `cosmos-contoso-dev-crm-001` (customer data)
7. **Key Vault** - `kv-contoso-dev-crm` (secrets)
8. **Managed Identity** - `id-contoso-dev-crm-001` (secure auth)

### Step 3A.3: Configure and Deploy

```powershell
# Initialize (separate state file!)
terraform init

# Review the plan
terraform plan -var-file="dev.tfvars"

# Expected output:
# Plan: 15 to add, 0 to change, 0 to destroy.
# + VNet (10.2.0.0/16)
# + 2 Subnets
# + NSG
# + Resource Group
# + App Service (Plan + Web App)
# + CosmosDB (Account + Database + Containers)
# + Key Vault
# + Managed Identity

# Deploy!
terraform apply -var-file="dev.tfvars"
```

> **Explain to client**: "Notice the `backend.tf` has state key `dev-app-crm.tfstate`. This means the CRM team's state is completely separate. CRM can destroy their resources without affecting anyone else!"

### CRM Team's Resources (Complete Independence!)

```
State file: dev-app-crm.tfstate (SEPARATE!)

Azure Resources:
├── Resource Group: rg-contoso-dev-crm-001          [CRM Team owns EVERYTHING]
│   
│   ### NETWORKING (CRM's Own - 10.2.0.0/16)
│   ├── VNet: vnet-contoso-dev-crm-001
│   │   ├── app-subnet: 10.2.1.0/24
│   │   └── db-subnet: 10.2.2.0/24
│   ├── NSG: app-nsg
│   │   ├── Allow HTTPS (port 443)
│   │   └── Allow HTTP (port 80)
│   
│   ### APPLICATIONS
│   ├── App Service Plan: asp-contoso-dev-crm-001
│   ├── Web App: app-contoso-dev-crm-001
│   │   └── Connected to: CRM's own VNet (app-subnet)
│   ├── CosmosDB: cosmos-contoso-dev-crm-001
│   │   ├── Database: crm-db
│   │   ├── Container: customers (/companyId)
│   │   └── Container: interactions (/customerId)
│   ├── Key Vault: kv-contoso-dev-crm
│   │   └── Secret: cosmos-connection-string
│   └── Managed Identity: id-contoso-dev-crm-001
│       └── Has access to: Key Vault (read-only), CosmosDB (read/write)
```

---

### Scene 3B: Team Delta (E-commerce) - Eka Deploys Simultaneously

**Story**: AT THE SAME TIME Dewi is deploying CRM, Eka deploys e-commerce. No conflicts because they're in separate VNets!

### Step 3B.1: Navigate to E-commerce Folder

```powershell
# Eka goes to HIS team's folder (can be done at the same time as Dewi!)
cd examples/pattern-2-delegated/dev-app-ecommerce
```

### Step 3B.2: Review Configuration

The E-commerce team's `main.tf` creates EVERYTHING (networking + apps):

**Networking (E-commerce's Own):**
1. **VNet** - `vnet-contoso-dev-ecommerce-001` (10.3.0.0/16)
2. **Subnets**:
   - aks-subnet: 10.3.1.0/24 (256 IPs for AKS nodes)
   - db-subnet: 10.3.2.0/24 (256 IPs for databases)
3. **NSGs** - Security rules for AKS traffic

**Application Resources:**
4. **Resource Group** - `rg-contoso-dev-ecommerce-001`
5. **AKS Cluster** (dedicated) - `aks-contoso-dev-ecommerce-001`
6. **CosmosDB** - `cosmos-contoso-dev-ecommerce-001` (products, orders, inventory)
7. **Key Vault** - `kv-contoso-dev-ecommerce`
8. **Managed Identity** - `id-contoso-dev-ecommerce-001`

### Step 3B.3: Deploy

```powershell
# Initialize (separate state file!)
terraform init

# Deploy!
terraform plan -var-file="dev.tfvars"

# Expected output:
# Plan: 18 to add, 0 to change, 0 to destroy.
# + VNet (10.3.0.0/16)
# + 2 Subnets
# + NSG
# + Resource Group
# + AKS Cluster (2 nodes)
# + CosmosDB (Account + Database + 3 Containers)
# + Key Vault
# + Managed Identity

terraform apply -var-file="dev.tfvars"
```

### E-commerce Team's Resources (Complete Independence!)

```
State file: dev-app-ecommerce.tfstate (SEPARATE!)

Azure Resources:
├── Resource Group: rg-contoso-dev-ecommerce-001    [E-commerce Team owns EVERYTHING]
│   
│   ### NETWORKING (E-commerce's Own - 10.3.0.0/16)
│   ├── VNet: vnet-contoso-dev-ecommerce-001
│   │   ├── aks-subnet: 10.3.1.0/24
│   │   └── db-subnet: 10.3.2.0/24
│   ├── NSG: aks-nsg
│   │   ├── Allow HTTPS (port 443)
│   │   └── Allow HTTP (port 80)
│   
│   ### APPLICATIONS
│   ├── AKS Cluster: aks-contoso-dev-ecommerce-001
│   │   ├── Node Count: 2-5 (autoscale)
│   │   ├── VM Size: Standard_D2s_v3
│   │   └── Connected to: E-commerce's own VNet (aks-subnet)
│   ├── CosmosDB: cosmos-contoso-dev-ecommerce-001
│   │   ├── Database: ecommerce-db
│   │   ├── Container: products (/categoryId)
│   │   ├── Container: orders (/customerId)
│   │   └── Container: inventory (/warehouseId)
│   ├── Key Vault: kv-contoso-dev-ecommerce
│   │   └── Secrets: AKS credentials, CosmosDB keys
│   └── Managed Identity: id-contoso-dev-ecommerce-001
│       └── Has access to: Key Vault, CosmosDB, AKS
```

---

## Summary: What We Just Demonstrated

### The Big Picture After All 3 Acts

```
Azure Subscription
│
├── terraform-state-rg (State Storage)
│   └── tfstatecontosoid (Storage Account)
│       └── tfstate (Container)
│           ├── dev.terraform.tfstate           ← Pattern 1 (ACT 1 + 2)
│           ├── dev-app-crm.tfstate             ← CRM Team (ACT 3A)
│           └── dev-app-ecommerce.tfstate       ← E-commerce Team (ACT 3B)
│
├── contoso-platform-rg-dev (Pattern 1 - Shared Resources)
│   ├── VNet: 10.1.0.0/16 + Subnets
│   ├── Log Analytics
│   ├── Key Vault
│   ├── AKS (Team Alpha)
│   ├── CosmosDB (Team Alpha)
│   ├── Container App Env (Team Beta)
│   └── PostgreSQL (Team Beta)
│
├── rg-contoso-dev-crm-001 (Pattern 2 - CRM's Independent Network)
│   ├── VNet: 10.2.0.0/16 + Subnets
│   ├── NSG
│   ├── App Service
│   ├── CosmosDB
│   ├── Key Vault
│   └── Managed Identity
│
└── rg-contoso-dev-ecommerce-001 (Pattern 2 - E-commerce's Independent Network)
    ├── VNet: 10.3.0.0/16 + Subnets
    ├── NSG
    ├── AKS
    ├── CosmosDB
    ├── Key Vault
    └── Managed Identity
```

### Key Points to Highlight

| Point | How You Say It |
|-------|----------------|
| **Consistency** | "All teams use the same naming convention, same tags, same modules" |
| **Independence** | "Pattern 2 teams deploy without asking anyone" |
| **Safety** | "Each team's state is separate - mistakes are isolated" |
| **Simplicity** | "Pattern 1 uses boolean toggles - just true/false" |
| **Reusability** | "The AKS module is used in both Pattern 1 and Pattern 2" |
| **Cost tracking** | "Tags show which team and cost center each resource belongs to" |

### Common Client Questions

| Question | Answer |
|----------|--------|
| "What if Team Alpha needs to change AKS settings?" | "In Pattern 1, they ask Andi. In Pattern 2, they change their own `dev.tfvars` - complete independence!" |
| "Can two teams deploy to the same resource group?" | "Pattern 1: Yes, they share one RG. Pattern 2: No, each team has their own RG AND own VNet." |
| "What if someone accidentally deletes a VNet?" | "Pattern 1: Protected by `prevent_deletion_if_contains_resources = true`. Pattern 2: Each team owns their VNet (10.2.x, 10.3.x) - isolated, can't affect others!" |
| "How do Pattern 2 teams communicate if needed?" | "By default, isolated. Can add VNet peering if cross-team communication needed (advanced topic)." |
| "How do we move from Pattern 1 to Pattern 2?" | "Gradually. Start with shared infra in Pattern 1, then teams extract to Pattern 2 folders with own VNets." |
| "What about production?" | "Same framework! Just change `dev.tfvars` to `prod.tfvars` with stronger settings (more nodes, encryption, private endpoints, etc.)" |

---

## Demo Talking Points Timeline

| Time | What to Show | What to Say |
|------|-------------|-------------|
| 0-5 min | Framework overview, folder structure | "This is a standardized way for all teams to manage infrastructure" |
| 5-10 min | `infra/global/locals.tf` | "Every resource follows the same naming and tagging standard" |
| 10-15 min | ACT 1: Foundation setup | "The platform team sets up the shared base once" |
| 15-25 min | ACT 2A: Enable AKS + CosmosDB | "One line change enables an entire AKS cluster with best practices" |
| 25-30 min | ACT 2B: Add Container Apps + PostgreSQL | "Another team's request - just toggle on" |
| 30-40 min | ACT 3: Pattern 2 demo | "Teams can work independently with separate state files" |
| 40-45 min | Show Azure Portal | "Everything is consistently named, tagged, and organized" |
| 45-50 min | Q&A | Address specific client concerns |

---

*Previous: [04 - Pattern 1 vs Pattern 2](04-PATTERN1-VS-PATTERN2.md)* | *Next: [06 - Diagrams Collection →](06-DIAGRAMS.md)*
