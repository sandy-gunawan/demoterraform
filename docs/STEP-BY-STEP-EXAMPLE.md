# 📖 Step-by-Step Example: Deploy Your First Application

This guide walks you through deploying a complete application infrastructure **from scratch**, step by step.

**Use Case:** Deploy a simple **Task Management API** for a mobile app

---

## 🎯 The Scenario

**You are:** Sarah, a backend developer on the Mobile Apps team

**Your task:** Deploy infrastructure for a new Task Management API that:
- Runs on Azure Kubernetes Service (AKS)
- Stores data in Cosmos DB
- Uses managed identities for security
- Will have 1000 users initially (small scale)

**Environment:** Development (dev)

---

## 🏗️ Understanding the Framework Structure

**IMPORTANT:** Before you start, understand where things live in the actual folder structure.

### Actual Folder Structure
```
terraform-framework/
├── infra/
│   ├── global/           ← Layer 0: Global standards
│   ├── envs/
│   │   └── dev/          ← Layer 1 + 2 combined!
│   │       ├── main.tf   ← Contains BOTH Landing Zone AND Workloads
│   │       └── dev.tfvars ← Feature toggles (what to enable)
│   └── modules/          ← Reusable modules (aks, cosmosdb, etc.)
```

### The 3 Logical Layers (in main.tf)

**Layer 0: Global Standards** (`infra/global/`)  
- Naming conventions, tags, provider config  
- Deploy once, used by all environments

**Layer 1: Landing Zone** (networking section of `main.tf`)  
- VNet, subnets, NSGs, Log Analytics  
- Deployed once per environment  
- Provides networking foundation for all apps

**Layer 2: Workloads** (workload section of `main.tf`)  
- AKS, Cosmos DB, Key Vault, etc.  
- Toggle on/off via `dev.tfvars`  
- Uses subnets from Layer 1

**Key insight:** Landing Zone isn't a separate folder - it's the networking section in your environment's `main.tf` file!

---

## 📋 Prerequisites Checklist

Before you start, ensure you have:

- [ ] Azure subscription access (ask your admin for subscription ID)
- [ ] Terraform installed (`terraform version` should show >= 1.6.0)
- [ ] Azure CLI installed (`az --version`)
- [ ] Git installed
- [ ] Access to your company's Terraform repository
- [ ] Your team's information (team name, cost center, tech lead email)
- [ ] **Landing Zone already deployed** (VNet, subnets, NSGs) by Platform team

---

## 🗺️ The Big Picture

You'll be filling out a `dev.tfvars` file with ~15 parameters. Here's what you need to know:

| Parameter | What It Is | Where to Get It | Example |
|-----------|-----------|----------------|---------|
| `organization_name` | Your organization name | Your company | `contoso` |
| `environment` | Which environment | Choose one: dev/staging/prod | `dev` |
| `project_name` | Your application/project name | Your project | `tasks` |
| `location` | Azure region | Ask your admin or choose closest | `eastus` |
| `enable_aks` | Enable Kubernetes? | Yes for your API | `true` |
| `enable_cosmosdb` | Enable database? | Yes for storing data | `true` |
| `enable_key_vault` | Enable secrets? | Yes for security | `true` |

---

## 🚶 Step-by-Step Walkthrough

### Step 1: Gather Your Information

**Fill out this form first:**

```yaml
# ============================================================================
# INFORMATION GATHERING FORM
# Fill this out before touching Terraform!
# ============================================================================

MY APPLICATION:
  Name: Task Management API
  Team: Mobile Apps Team
  Tech Lead Email: sarah.jones@contoso.com
  Cost Center: CC-9999

AZURE BASICS:
  Subscription ID: _______________________________ (Get from: az account show)
  Resource Group Prefix: rg-contoso-dev-tasks     (Pattern: rg-{company}-{env}-{app})
  Location: eastus                                (Get from: Ask your admin)

WHAT I NEED:
  ☑️ Kubernetes (AKS) - Yes, for running containers
  ☑️ Cosmos DB - Yes, for storing task data
  ☑️ Key Vault - Yes, for storing secrets
  ☐ Container Apps - No, using AKS instead
  ☐ Web App - No, not needed

DATABASE REQUIREMENTS:
  Database Name: tasks-db
  
  Container 1:
    Name: tasks
    Partition Key: /userId               (Tasks grouped by user)
    Estimated size: 10,000 items
    RU/s needed: 400 (minimum for dev)
  
  Container 2:
    Name: projects
    Partition Key: /teamId               (Projects grouped by team)
    Estimated size: 1,000 items
    RU/s needed: 400 (minimum for dev)

NETWORKING:
  Will connect to on-premises? No
  Needs public internet access? Yes (for mobile app)
  Needs private endpoints? No (dev environment, save costs)

KUBERNETES:
  Node count: 2 (minimum for dev)
  Node size: Standard_D2s_v3 (2 CPU, 8GB RAM)
  Kubernetes version: 1.28 (ask platform team for approved versions)
```

---

### Step 2: Get Your Azure Subscription ID

**Run this command:**

```bash
az login
az account list --output table
```

**Output example:**
```
Name              CloudName    SubscriptionId                        State    IsDefault
----------------  -----------  ------------------------------------  -------  -----------
Contoso-Dev       AzureCloud   12345678-1234-1234-1234-123456789abc  Enabled  True
Contoso-Prod      AzureCloud   87654321-4321-4321-4321-cba987654321  Enabled  False
```

**Copy the SubscriptionId for your environment:**
```
Dev: 12345678-1234-1234-1234-123456789abc
```

---

### Step 3: Clone the Repository

```bash
# Clone your company's Terraform repo
git clone https://github.com/contoso/terraform-framework.git
cd terraform-framework

# Create a new branch for your work
git checkout -b feature/tasks-api-infrastructure
```

---

### Step 4: Choose Your Deployment Pattern

**Pattern 1 (Centralized):** Platform team manages everything
- ➡️ Go to: `infra/envs/dev/`
- You'll edit `dev.tfvars` to enable features
- Landing Zone (VNet, subnets) already deployed
- You're just toggling workloads on/off

**Pattern 2 (Delegated):** Your team manages your own folder
- ➡️ Copy from: `examples/pattern-2-delegated/dev-app-ecommerce/`
- Create: `infra/envs/dev-app-tasks/`
- You'll create your own `main.tf` and `dev.tfvars`

**For this example, we'll use Pattern 1 (simpler for first time).**

```bash
cd infra/envs/dev
```

---

### Step 5: Edit the Configuration File

**Open:** `infra/envs/dev/dev.tfvars`

**Important:** The `main.tf` in this folder contains BOTH:
- 🏗️ Landing Zone code (networking - already deployed)
- 🚀 Workload code (AKS, Cosmos DB - you're enabling via toggles)

**What to fill in order:**

#### 5.1 Core Information (FILL THESE FIRST)

```hcl
# ============================================================================
# STEP 1: Core Information (Copy from your form)
# ============================================================================

organization_name = "contoso"   # ← Your organization name (lowercase, no spaces)
environment       = "dev"       # ← Always "dev" for dev environment
project_name      = "tasks"     # ← Your app/project name (lowercase, no spaces)
location          = "indonesiacentral"    # ← Azure region (from your form)
```

**Where each value comes from:**
- `organization_name`: Your organization (ask platform team if unsure)
- `environment`: Fixed as `dev` (this file is for dev environment)
- `project_name`: Your application name - keep it short and descriptive
- `location`: Azure region - common options: `indonesiacentral`, `eastasia`, `westeurope`

---

#### 5.2 Tags (FILL THESE NEXT)

```hcl
# ============================================================================
# STEP 2: Tags for Cost Tracking (Copy from your form)
# ============================================================================

default_tags = {
  Environment = "dev"                              # ← Fixed as "dev"
  ManagedBy   = "Terraform"                        # ← Fixed as "Terraform"
  Team        = "Mobile Apps Team"                 # ← Your team name
  TechLead    = "sarah.jones@contoso.com"         # ← Your email
  CostCenter  = "CC-9999"                          # ← From finance team
  Application = "Task Management API"              # ← Your app description
}
```

**Where each value comes from:**
- `Team`: Your team's official name (for cost allocation)
- `TechLead`: Your email or your manager's email
- `CostCenter`: Get this from your finance/accounting team
- `Application`: Brief description of what this app does

---

#### 5.3 Feature Toggles (ENABLE WHAT YOU NEED)

```hcl
# ============================================================================
# STEP 3: Enable the Features You Need (From your checklist)
# ============================================================================

# Toggle each feature on/off
enable_aks            = true   # ← ☑️ You need Kubernetes
enable_container_apps = false  # ← ☐ Not using Container Apps
enable_webapp         = false  # ← ☐ Not using App Service
enable_cosmosdb       = true   # ← ☑️ You need database
enable_key_vault      = true   # ← ☑️ You need secrets storage
```

**Decision tree:**
- **Need containers with Kubernetes features?** → `enable_aks = true`
- **Need simple serverless containers?** → `enable_container_apps = true`
- **Need web hosting (not containers)?** → `enable_webapp = true`
- **Need NoSQL database?** → `enable_cosmosdb = true`
- **Need secrets storage?** → `enable_key_vault = true` (recommended: always)

**Rule of thumb for dev:**
- Start with MINIMUM features needed
- Add more later (Terraform is incremental!)
- For tasks API: Just need AKS + Cosmos DB + Key Vault

---

#### 5.4 AKS Configuration (ONLY IF ENABLED)

```hcl
# ============================================================================
# STEP 4: Configure Kubernetes (Only if enable_aks = true)
# ============================================================================

kubernetes_version = "1.28"              # ← Ask platform team for approved version
aks_node_count     = 2                   # ← How many servers? (2-3 for dev)
aks_vm_size        = "Standard_D2s_v3"   # ← Server size (D2s_v3 = 2 CPU, 8GB RAM)
```

**How to choose values:**

| Parameter | Dev | Staging | Prod | How to Decide |
|-----------|-----|---------|------|---------------|
| `kubernetes_version` | 1.28 | 1.28 | 1.28 | Ask platform team |
| `aks_node_count` | 2 | 3 | 5 | 2 = minimum, 3 = comfortable |
| `aks_vm_size` | D2s_v3 | D4s_v3 | D8s_v3 | D2s_v3 = basic (2 CPU), D4s_v3 = standard (4 CPU) |

**Common VM sizes:**
- `Standard_D2s_v3`: 2 vCPU, 8 GB RAM (~$70/month)
- `Standard_D4s_v3`: 4 vCPU, 16 GB RAM (~$140/month)
- `Standard_D8s_v3`: 8 vCPU, 32 GB RAM (~$280/month)

**Cost tip:** Dev = use smallest size, Prod = use larger + autoscale

---

#### 5.5 Cosmos DB Configuration (ONLY IF ENABLED)

```hcl
# ============================================================================
# STEP 5: Configure Database (Only if enable_cosmosdb = true)
# ============================================================================

# Basic settings
cosmos_consistency_level = "Session"     # ← Leave as "Session" for most apps
cosmos_allowed_ips       = ""            # ← Leave empty (allow from Azure only)

# Container 1: Tasks
cosmos_database_name     = "tasks-db"    # ← Your database name
cosmos_container_tasks   = "tasks"       # ← Container name
cosmos_partition_key_tasks = "/userId"   # ← How data is split (IMPORTANT!)
cosmos_tasks_ru          = 400           # ← Throughput (400 = minimum)

# Container 2: Projects
cosmos_container_projects   = "projects"      # ← Second container name
cosmos_partition_key_projects = "/teamId"     # ← Partition key
cosmos_projects_ru          = 400             # ← Throughput
```

**Understanding partition keys (MOST IMPORTANT CONCEPT):**

A partition key determines how Cosmos DB splits your data across servers.

**✅ GOOD partition keys:**
- `/userId` - If you query by user (e.g., "Show me all tasks for user123")
- `/teamId` - If you query by team (e.g., "Show me all projects for team456")
- `/categoryId` - If you query by category
- `/tenantId` - For multi-tenant apps

**❌ BAD partition keys:**
- `/id` - Too unique, every item is a partition (expensive queries)
- `/status` - Too few values (hot partitions)
- `/createdDate` - Time-based (hot partitions)

**How to choose:**
1. What field do you **ALWAYS** filter by in queries?
2. Does it have many unique values? (cardinality > 100)
3. Use that field as partition key!

**Example:**
```
Query: "Get all tasks where userId = 'user123'"
Partition Key: /userId ✅ PERFECT!

Query: "Get all tasks where status = 'completed'"
Partition Key: /status ❌ BAD! (Only 3 values: pending/in-progress/completed)
```

**Request Units (RU/s):**
- 400 RU/s = minimum, good for dev ($24/month)
- 1000 RU/s = staging ($60/month)
- 4000+ RU/s = prod with autoscale ($240+/month)

---

#### 5.6 Key Vault Configuration (ONLY IF ENABLED)

```hcl
# ============================================================================
# STEP 6: Configure Secrets Storage (Only if enable_key_vault = true)
# ============================================================================

key_vault_sku = "standard"  # ← Leave as "standard" (premium = HSM hardware)
```

**SKU options:**
- `standard`: Regular secrets, certificates ($0.03 per 10K operations)
- `premium`: Hardware security module (HSM), for compliance (10x more expensive)

**For most apps:** Use `standard`

---

### Step 6: Review Your Complete Configuration

Your final `dev.tfvars` should look like this:

```hcl
# ============================================================================
# TASK MANAGEMENT API - DEV ENVIRONMENT
# Generated: 2026-02-03
# Owner: sarah.jones@contoso.com
# ============================================================================

# ----------------------------------------------------------------------------
# Core Configuration
# ----------------------------------------------------------------------------

organization_name = "contoso"
project_name      = "tasks"
environment       = "dev"
location          = "indonesiacentral"

# ----------------------------------------------------------------------------
# Tags
# ----------------------------------------------------------------------------

default_tags = {
  Environment = "dev"
  ManagedBy   = "Terraform"
  Team        = "Mobile Apps Team"
  TechLead    = "sarah.jones@contoso.com"
  CostCenter  = "CC-9999"
  Application = "Task Management API"
}

# ----------------------------------------------------------------------------
# Feature Toggles - What infrastructure to create
# ----------------------------------------------------------------------------

enable_aks            = true   # ✅ Kubernetes for running API
enable_container_apps = false  # ❌ Not using Container Apps
enable_webapp         = false  # ❌ Not using App Service
enable_cosmosdb       = true   # ✅ Database for tasks
enable_key_vault      = true   # ✅ Secrets storage

# ----------------------------------------------------------------------------
# AKS Configuration
# ----------------------------------------------------------------------------

kubernetes_version = "1.28"
aks_node_count     = 2
aks_vm_size        = "Standard_D2s_v3"

# ----------------------------------------------------------------------------
# Cosmos DB Configuration
# ----------------------------------------------------------------------------

cosmos_consistency_level = "Session"
cosmos_allowed_ips       = ""

# Database and containers
cosmos_database_name           = "tasks-db"
cosmos_container_tasks         = "tasks"
cosmos_partition_key_tasks     = "/userId"
cosmos_tasks_ru                = 400

cosmos_container_projects      = "projects"
cosmos_partition_key_projects  = "/teamId"
cosmos_projects_ru             = 400

# ----------------------------------------------------------------------------
# Key Vault Configuration
# ----------------------------------------------------------------------------

key_vault_sku = "standard"
```

---

### Step 7: Validate Your Configuration

Before deploying, check your work:

```bash
# Check Terraform syntax
terraform fmt

# Validate configuration
terraform validate

# See what will be created (DRY RUN)
terraform plan -var-file="dev.tfvars"
```

**What to look for in `terraform plan` output:**

```
Plan: 15 to add, 0 to change, 0 to destroy.

Terraform will perform the following actions:

  # azurerm_kubernetes_cluster.main will be created
  ✅ Creating AKS cluster

  # azurerm_cosmosdb_account.main will be created
  ✅ Creating Cosmos DB

  # azurerm_key_vault.main will be created
  ✅ Creating Key Vault

  # ... (more resources)
```

**Sanity checks:**
- ✅ Resource names follow pattern: `rg-contoso-dev-tasks-001`
- ✅ All resources in correct location: `eastus`
- ✅ All resources have correct tags
- ✅ No errors in red

---

### Step 8: Deploy!

```bash
# Apply the configuration (DEPLOY FOR REAL)
terraform apply -var-file="dev.tfvars"

# Terraform will ask for confirmation
# Review the plan one more time
# Type: yes
```

**Deployment time:** 15-20 minutes (AKS takes longest)

**What happens:**

**If Landing Zone not yet deployed:**
1. Creates resource group
2. 🏗️ **Layer 1: Landing Zone**
   - Creates VNet (10.1.0.0/16)
   - Creates subnets (aks-subnet, app-subnet, data-subnet)
   - Creates NSGs
   - Creates Log Analytics Workspace
3. 🚀 **Layer 2: Workloads** (what you enabled)
   - Creates AKS cluster (~15 min)
   - Creates Cosmos DB (~2 min)
   - Creates Key Vault (~1 min)
4. Configures permissions
5. Stores outputs

**If Landing Zone already deployed:**
- Terraform sees Layer 1 in state file, skips it ✅
- Only creates new workloads you enabled ✅

---

### Step 9: Get Your Connection Information

After deployment, Terraform shows outputs:

```bash
terraform output
```

**Example output:**
```
aks_cluster_name = "aks-contoso-dev-tasks-001"
aks_resource_group = "rg-contoso-dev-tasks-001"
cosmos_endpoint = "https://cosmos-contoso-dev-tasks-001.documents.azure.com"
cosmos_database = "tasks-db"
key_vault_name = "kv-contoso-dev-tasks"
managed_identity_client_id = "a1b2c3d4-1234-5678-90ab-cdef12345678"
```

**Save these values!** You'll need them to deploy your application.

---

### Step 10: Deploy Your Application

Now that infrastructure is ready, connect to AKS and deploy your app:

```bash
# Connect to AKS cluster
az aks get-credentials \
  --resource-group rg-contoso-dev-tasks-001 \
  --name aks-contoso-dev-tasks-001

# Verify connection
kubectl get nodes

# Create namespace for your app
kubectl create namespace tasks

# Deploy your application (example)
kubectl apply -f k8s/deployment.yaml -n tasks

# Check if running
kubectl get pods -n tasks
```

---

## 🎉 Success Checklist

- [ ] `terraform apply` completed without errors
- [ ] All outputs are displayed
- [ ] Can connect to AKS cluster
- [ ] Application deployed and running
- [ ] Can access API endpoint

---

## 🔧 Troubleshooting Common Issues

### Issue 1: "Error: Invalid count argument"

**Problem:** You enabled a feature but didn't fill in required parameters

**Solution:**
```hcl
# If enable_cosmosdb = true, you MUST also set:
cosmos_database_name = "tasks-db"  # ← Add this!
```

---

### Issue 2: "Error: Name already exists"

**Problem:** Resource name is taken (globally unique names)

**Solution:**
```hcl
# Add a unique suffix or change workload name
workload = "tasks-v2"  # or "tasks-mobile", "tasks-api"
```

---

### Issue 3: "Error: Insufficient permissions"

**Problem:** Your Azure account lacks required permissions

**Solution:**
```bash
# Check your permissions
az role assignment list --assignee your.email@contoso.com

# Ask platform team to grant:
# - Contributor (for resources)
# - User Access Administrator (for IAM)
```

---

### Issue 4: "Plan shows unexpected changes"

**Problem:** Terraform wants to change existing resources

**Solution:**
```bash
# Check what changed
terraform plan -var-file="dev.tfvars" -out=tfplan

# Review the plan carefully
terraform show tfplan

# If unsure, ask platform team before applying
```

---

## 📊 Cost Estimate

Based on this configuration, expected monthly costs:

| Resource | Type | Monthly Cost |
|----------|------|--------------|
| AKS | 2x D2s_v3 nodes | ~$140 |
| Cosmos DB | 2 containers @ 400 RU/s each | ~$48 |
| Key Vault | Standard | ~$1 |
| VNet | Standard | ~$0 |
| **Total** | | **~$189/month** |

**Cost optimization tips:**
- Dev: Use this config (~$189/month)
- After hours: Scale down AKS to 1 node (~$70/month)
- Weekends: Consider stopping dev resources

---

## 🎓 What You Learned

✅ How to gather requirements before starting  
✅ How to fill out `dev.tfvars` step by step  
✅ Where each parameter value comes from  
✅ How to choose Cosmos DB partition keys  
✅ How to deploy infrastructure with Terraform  
✅ How to get connection info for your app  
✅ How to troubleshoot common issues  

---

## 📚 Next Steps

1. **Add more containers:** Edit `dev.tfvars`, add new Cosmos DB containers, re-run `terraform apply`
2. **Enable Web App:** Set `enable_webapp = true`, configure settings
3. **Deploy to staging:** Copy config to `infra/envs/staging/`, adjust SKUs
4. **Set up CI/CD:** Automate deployments with [Azure DevOps Pipelines](AZURE-DEVOPS-SETUP.md)
5. **Monitor costs:** Set up Azure Cost Management alerts

---

## 🤝 Getting Help

**Stuck?** Contact:
- **Platform team:** #platform-team on Slack
- **Documentation:** [TEAM-COLLABORATION.md](TEAM-COLLABORATION.md)
- **Training:** Weekly office hours (Tuesday 2-4pm)

**Have feedback?** Create an issue or PR to improve this guide!

---

**Congratulations! You've deployed your first infrastructure with Terraform!** 🚀
