# 🧪 Scenario Testing Guide - Step-by-Step Infrastructure Deployment

> **Perfect for:** Complete beginners who want to test the framework incrementally  
> **Time:** 2-4 hours (including all scenarios)  
> **Cost:** $0-300/month depending on scenario

Welcome! This guide walks you through testing different infrastructure deployment scenarios, **one step at a time**. By the end, you'll understand how to deploy, modify, and clean up Azure infrastructure confidently.

---

## 📌 Table of Contents

1. [Prerequisites](#-1-prerequisites)
2. [Initial Setup](#-2-initial-setup)
3. [Scenario 1: Deploy AKS Only](#-scenario-1-deploy-aks-only)
4. [Scenario 2: Add Cosmos DB](#-scenario-2-add-cosmos-db)
5. [Scenario 3: Add App Service](#-scenario-3-add-app-service)
6. [Scenario 4: Deploy to Production](#-scenario-4-deploy-to-production)
7. [Scenario 5: Clean Up Everything](#-scenario-5-clean-up-everything)
8. [Troubleshooting](#-8-troubleshooting)
9. [Cost Breakdown](#-9-cost-breakdown)
10. [FAQ](#-10-faq)

---

## 🎯 What You'll Learn

By completing all scenarios, you'll know how to:
- ✅ Deploy Azure infrastructure incrementally
- ✅ Verify deployments using CLI and Azure Portal
- ✅ Add resources to existing infrastructure safely
- ✅ Deploy to multiple environments (dev/prod)
- ✅ Troubleshoot common deployment issues
- ✅ Estimate and control costs
- ✅ Clean up resources properly

---

## ✅ 1. Prerequisites

### 1.1 Required Tools

Before starting, ensure you have these tools installed:

#### Check if Already Installed

```powershell
# Check Azure CLI
az --version
# Should show: azure-cli 2.50.0 or higher

# Check Terraform
terraform --version
# Should show: Terraform v1.5.0 or higher

# Check Git
git --version
# Should show: git version 2.x.x
```

#### Install Missing Tools (Windows)

```powershell
# Install Azure CLI
winget install Microsoft.AzureCLI

# Install Terraform
winget install HashiCorp.Terraform

# Install Git
winget install Git.Git

# Install VS Code (recommended)
winget install Microsoft.VisualStudioCode
```

#### Install Missing Tools (macOS)

```bash
# Install Homebrew first if you don't have it
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install tools
brew install azure-cli
brew install terraform
brew install git

# Install VS Code
brew install --cask visual-studio-code
```

#### Install Missing Tools (Linux)

```bash
# Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Git
sudo apt-get install git
```

---

### 1.2 Azure Subscription Required

You need an Azure subscription with these permissions:

- [ ] **Contributor** role (to create resources)
- [ ] **User Access Administrator** role (to assign permissions)
- [ ] Or **Owner** role (includes both)

**Check your access:**

```powershell
# Login to Azure
az login

# Check your subscriptions
az account list --output table

# Check your permissions
az role assignment list --assignee your.email@company.com --output table
```

**What you should see:**
```
Name                                  Type                                     Scope
------------------------------------  ---------------------------------------  -------------------
Contributor                          BuiltInRole                              /subscriptions/...
User Access Administrator            BuiltInRole                              /subscriptions/...
```

⚠️ **Don't have access?** Ask your Azure administrator to grant you Contributor + User Access Administrator roles.

---

### 1.3 Estimated Costs

**Important:** Running these scenarios will create Azure resources that cost money.

| Scenario | Resources Created | Estimated Cost/Month | Time Running |
|----------|-------------------|----------------------|--------------|
| Setup Only | Storage Account | ~$1 | Always |
| Scenario 1 | AKS (2 nodes) | ~$140 | 1-2 hours |
| Scenario 2 | + Cosmos DB | ~$188 | 1 hour |
| Scenario 3 | + App Service | ~$243 | 1 hour |
| Scenario 4 | Production env | ~$450 | 1 hour |

💡 **Cost-saving tips:**
- Delete resources immediately after testing (Scenario 5)
- Only run scenarios during business hours
- Use the smallest VM sizes for testing
- Skip Scenario 4 (production) if only learning

---

## 🚀 2. Initial Setup

This section sets up the foundation needed for all scenarios.

**Time required:** ~15 minutes

---

### Step 2.1: Login to Azure

```powershell
# Login to Azure (will open browser)
az login

# List your subscriptions
az account list --output table

# Set the subscription you want to use
az account set --subscription "Your Subscription Name"

# Verify it's set
az account show --query "{Name:name, SubscriptionId:id}" --output table
```

**What you should see:**
```
Name                    SubscriptionId
----------------------  ------------------------------------
My Azure Subscription   12345678-1234-1234-1234-123456789012
```

✅ **Checkpoint:** You should see your subscription name and ID displayed.

---

### Step 2.2: Create Terraform State Storage

Terraform needs a place to store its "state" (a record of what resources exist).

**Why?** Without this, Terraform doesn't know what it created previously!

```powershell
# Set variables (customize these)
$RESOURCE_GROUP = "contoso-tfstate-rg"
$STORAGE_ACCOUNT = "stcontosotfstate001"
$CONTAINER = "tfstate"
$LOCATION = "southeastasia"

# Create resource group
Write-Host "Creating resource group..." -ForegroundColor Green
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create storage account (this takes ~30 seconds)
Write-Host "Creating storage account (this takes ~30 seconds)..." -ForegroundColor Green
az storage account create `
  --name $STORAGE_ACCOUNT `
  --resource-group $RESOURCE_GROUP `
  --location $LOCATION `
  --sku Standard_LRS `
  --encryption-services blob

# Enable versioning (protects against accidental deletion)
Write-Host "Enabling versioning..." -ForegroundColor Green
az storage account blob-service-properties update `
  --account-name $STORAGE_ACCOUNT `
  --enable-versioning true

# Create container
Write-Host "Creating container..." -ForegroundColor Green
az storage container create `
  --name $CONTAINER `
  --account-name $STORAGE_ACCOUNT `
  --auth-mode login

# Display success message
Write-Host "✅ Backend storage created successfully!" -ForegroundColor Green
Write-Host "Storage Account Name: $STORAGE_ACCOUNT" -ForegroundColor Yellow
Write-Host "📝 IMPORTANT: Write down this storage account name!" -ForegroundColor Yellow
```

**Expected output:**
```json
{
  "created": true,
  "name": "tfstate12345"
}
```

📝 **WRITE THIS DOWN:** Your storage account name (e.g., `tfstate12345`) - you'll need it in the next step!

---

### Step 2.3: Clone the Repository

```powershell
# Navigate to where you keep code projects
cd C:\Users\YourName\codes

# Clone the repository
git clone <your-repo-url> terraform-framework
cd terraform-framework

# Verify the structure
ls
```

**What you should see:**
```
Directory: C:\Users\YourName\codes\terraform-framework

Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
d-----        2026-02-11     10:00                docs
d-----        2026-02-11     10:00                examples
d-----        2026-02-11     10:00                infra
d-----        2026-02-11     10:00                pipelines
d-----        2026-02-11     10:00                scripts
-a----        2026-02-11     10:00           5432 README.md
```

✅ **Checkpoint:** You should see the folders: `docs`, `infra`, `examples`, `pipelines`, `scripts`.

---

### Step 2.4: Configure Backend

Now link Terraform to the storage account you created.

```powershell
# Navigate to dev environment
cd infra\envs\dev

# Open backend.tf in your editor
code backend.tf
```

**Edit this file** and replace `YOUR_STORAGE_ACCOUNT_NAME` with your actual storage account name:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "contoso-tfstate-rg"
    storage_account_name = "stcontosotfstate001"
    container_name       = "tfstate"
    key                  = "dev.terraform.tfstate"
    use_azuread_auth     = true
  }
}
```

💾 **Save the file** (Ctrl+S or Cmd+S).

---

### Step 2.5: Get Your Azure Tenant ID

```powershell
# Get your tenant ID
az account show --query tenantId --output tsv
```

**Expected output:**
```
12345678-90ab-cdef-1234-567890abcdef
```

📝 **Copy this value** - you'll use it in the next step.

---

### Step 2.6: Create Your First Variables File

```powershell
# Still in infra\envs\dev folder
code dev.tfvars
```

**Replace the entire content with this:**

```hcl
# =============================================================================
# SCENARIO TESTING CONFIGURATION
# =============================================================================
# This configuration is designed for testing scenarios incrementally
# =============================================================================

# -----------------------------------------------------------------------------
# Basic Configuration
# -----------------------------------------------------------------------------
organization_name = "contoso"           # ← Company name
project_name      = "scenariotest"     # ← Keep as-is for testing
location          = "southeastasia"    # ← Closest to Indonesia

# Azure AD Configuration (IMPORTANT - fill this!)
tenant_id = "12345678-90ab-cdef-1234-567890abcdef"  # ← PASTE YOUR TENANT ID HERE

# Governance
cost_center    = "Engineering-Testing"
owner_email    = "your.email@company.com"  # ← Change to your email
repository_url = "https://github.com/yourorg/terraform-framework"

# -----------------------------------------------------------------------------
# Feature Toggles - START WITH EVERYTHING OFF!
# We'll enable them one by one in each scenario
# -----------------------------------------------------------------------------
enable_aks            = false  # Scenario 1: We'll set this to true
enable_container_apps = false
enable_webapp         = false  # Scenario 3: We'll set this to true
enable_cosmosdb       = false  # Scenario 2: We'll set this to true
enable_key_vault      = true   # Always enabled for security

# -----------------------------------------------------------------------------
# Security Features - Disabled for cost-effective testing
# -----------------------------------------------------------------------------
enable_nat_gateway         = false
enable_private_endpoints   = false
enable_ddos_protection     = false
key_vault_purge_protection = false
network_acl_default_action = "Allow"

# -----------------------------------------------------------------------------
# Monitoring - Minimal
# -----------------------------------------------------------------------------
enable_application_insights = false
enable_diagnostic_settings  = false
log_retention_days          = 30

# -----------------------------------------------------------------------------
# Scaling - Small for testing
# -----------------------------------------------------------------------------
enable_auto_scaling      = false
enable_geo_redundancy    = false
enable_continuous_backup = false
aks_node_count           = 2  # Small cluster for testing
aks_node_size            = "Standard_D2s_v3"  # 2 CPU, 8GB RAM
```

**Important changes to make:**
1. Line 9: Change `organization_name` to your company or your name
2. Line 13: Paste your actual tenant_id (from Step 2.5)
3. Line 17: Change `owner_email` to your email

💾 **Save the file** (Ctrl+S or Cmd+S).

✅ **Checkpoint:** You have a `dev.tfvars` file with all features set to `false` except `enable_key_vault = true`.

---

### Step 2.7: Initialize Terraform

```powershell
# Make sure you're in infra\envs\dev
pwd
# Should show: C:\Users\...\terraform-framework\infra\envs\dev

# Initialize Terraform (downloads Azure provider, connects to backend)
terraform init
```

**Expected output:**
```
Initializing the backend...

Successfully configured the backend "azurerm"!

Initializing provider plugins...
- Finding hashicorp/azurerm versions matching "~> 3.0"...
- Installing hashicorp/azurerm v3.85.0...
- Installed hashicorp/azurerm v3.85.0

Terraform has been successfully initialized!
```

⚠️ **If you see an error here:** Check that you updated `backend.tf` with the correct storage account name.

✅ **Checkpoint:** Terraform is initialized and connected to your state storage.

---

## 🎬 Scenario 1: Deploy AKS Only

**Goal:** Deploy Azure Kubernetes Service (AKS) as your first compute resource.

**Time:** ~20 minutes  
**Cost:** ~$140/month (we'll delete it in Scenario 5)

### What You'll Deploy

```
📦 Resource Group (container for all resources)
└── 🌐 Virtual Network (10.1.0.0/16)
    ├── 📡 aks-subnet (10.1.1.0/24)
    ├── 📡 app-subnet (10.1.2.0/24)
    └── 🔒 Network Security Group
└── ☸️ AKS Cluster (2 nodes, Kubernetes 1.28)
└── 🔐 Key Vault (for secrets)
```

---

### Step 1.1: Enable AKS in Configuration

```powershell
# Open dev.tfvars
code dev.tfvars
```

**Find this line** (around line 29) and change it from `false` to `true`:

```hcl
# Before:
enable_aks = false

# After:
enable_aks = true  # ← CHANGED!
```

💾 **Save the file**.

---

### Step 1.2: Preview Changes (Terraform Plan)

```powershell
# Run terraform plan to see what will be created
terraform plan -var-file="dev.tfvars" -out=scenario1.tfplan
```

**What this command does:**
- Reads your configuration from `dev.tfvars`
- Compares it with what currently exists (nothing yet!)
- Shows you exactly what will be created
- Saves the plan to a file for safety

**Expected output (abbreviated):**
```
Terraform will perform the following actions:

  # azurerm_resource_group.main will be created
  + resource "azurerm_resource_group" "main" {
      + name     = "scenariotest-rg-dev"
      + location = "southeastasia"
    }

  # module.networking.azurerm_virtual_network.vnet will be created
  + resource "azurerm_virtual_network" "vnet" {
      + name          = "scenariotest-vnet-dev"
      + address_space = ["10.1.0.0/16"]
    }

  # module.aks[0].azurerm_kubernetes_cluster.aks will be created
  + resource "azurerm_kubernetes_cluster" "aks" {
      + name       = "scenariotest-aks-dev"
      + node_count = 2
      + vm_size    = "Standard_D2s_v3"
    }

  # module.key_vault[0].azurerm_key_vault.kv will be created
  + resource "azurerm_key_vault" "kv" {
      + name = "scenariotest-kv-dev"
    }

Plan: 12 to add, 0 to change, 0 to destroy.
```

**Key things to verify:**
- ✅ "12 to add, 0 to change, 0 to destroy" (exact number may vary)
- ✅ You see `azurerm_kubernetes_cluster.aks` being created
- ✅ You see `azurerm_virtual_network` being created  
- ✅ You see `azurerm_key_vault` being created
- ❌ No errors in red

⚠️ **If you see errors:** Jump to [Troubleshooting Section](#-8-troubleshooting) before continuing.

---

### Step 1.3: Apply Changes (Actually Create Resources)

```powershell
# Apply the plan (this creates the resources)
terraform apply scenario1.tfplan
```

**What happens now:**
- Terraform creates resources in Azure
- This takes **~15-20 minutes** ⏱️ (AKS clusters are slow to create)
- You'll see progress messages as each resource is created

**Expected output (real-time progress):**
```
module.networking.azurerm_resource_group.rg: Creating...
module.networking.azurerm_resource_group.rg: Creation complete after 2s

module.networking.azurerm_virtual_network.vnet: Creating...
module.networking.azurerm_virtual_network.vnet: Creation complete after 8s

module.aks[0].azurerm_kubernetes_cluster.aks: Creating...
module.aks[0].azurerm_kubernetes_cluster.aks: Still creating... [1m0s elapsed]
module.aks[0].azurerm_kubernetes_cluster.aks: Still creating... [2m0s elapsed]
...
module.aks[0].azurerm_kubernetes_cluster.aks: Creation complete after 15m23s

Apply complete! Resources: 12 added, 0 changed, 0 destroyed.

Outputs:

aks_cluster_name = "scenariotest-aks-dev"
aks_kube_config_command = "az aks get-credentials --resource-group scenariotest-rg-dev --name scenariotest-aks-dev"
key_vault_uri = "https://scenariotest-kv-dev.vault.azure.net/"
resource_group_name = "scenariotest-rg-dev"
```

☕ **Time for coffee!** This takes 15-20 minutes. Monitor the progress.

---

### Step 1.4: Verify Deployment (Azure CLI)

After the apply completes, verify everything was created:

```powershell
# Check resource group
az group show --name scenariotest-rg-dev --output table

# List all resources in the group
az resource list --resource-group scenariotest-rg-dev --output table

# Check AKS cluster status
az aks show --resource-group scenariotest-rg-dev --name scenariotest-aks-dev --query "{Name:name, Status:provisioningState, NodeCount:agentPoolProfiles[0].count}" --output table
```

**What you should see:**
```
Name                    Status     NodeCount
----------------------  ---------  -----------
scenariotest-aks-dev    Succeeded  2
```

✅ **Success indicator:** Status = "Succeeded" and NodeCount = 2

---

### Step 1.5: Verify Deployment (Azure Portal)

Let's verify in the Azure Portal (great for visual learners!):

1. **Open Azure Portal:** https://portal.azure.com
2. **Navigate to Resource Groups:** Click "Resource groups" in the left menu
3. **Find your resource group:** Search for "scenariotest-rg-dev"
4. **You should see these resources:**

   ```
   📦 scenariotest-rg-dev
   ├── ☸️ scenariotest-aks-dev (Kubernetes service)
   ├── 🌐 scenariotest-vnet-dev (Virtual network)
   ├── 🔐 scenariotest-kv-dev (Key vault)
   ├── 📡 aks-subnet (Subnet)
   ├── 📡 app-subnet (Subnet)
   ├── 🔒 aks-nsg (Network security group)
   └── 💾 MC_scenariotest-rg-dev_scenariotest-aks-dev_eastus (AKS managed resource group)
   ```

5. **Click on the AKS cluster** (`scenariotest-aks-dev`)
6. **Check Overview tab:**
   - Status: ✅ Running
   - Node count: 2
   - Kubernetes version: 1.28.x

**Screenshot description:** You should see a green "Running" status with 2 nodes listed in the node pools section.

---

### Step 1.6: Connect to AKS Cluster

Let's verify you can actually use this cluster:

```powershell
# Get credentials (configures kubectl to connect to your cluster)
az aks get-credentials --resource-group scenariotest-rg-dev --name scenariotest-aks-dev --overwrite-existing

# Verify connection
kubectl get nodes
```

**Expected output:**
```
NAME                                STATUS   ROLES   AGE   VERSION
aks-systempool-12345678-vmss000000  Ready    agent   5m    v1.28.3
aks-systempool-12345678-vmss000001  Ready    agent   5m    v1.28.3
```

✅ **Success:** You see 2 nodes in "Ready" status!

---

### Step 1.7: Check Current Costs

```powershell
# Get cost information for the last 7 days
az consumption usage list --start-date $(Get-Date).AddDays(-7).ToString("yyyy-MM-dd") --output table
```

**Or check in Azure Portal:**
1. Go to **Cost Management + Billing**
2. Click **Cost analysis**
3. Filter by resource group: "scenariotest-rg-dev"
4. **What you should see:** ~$4-5 per day (~$140/month projected)

💰 **Cost breakdown:**
- AKS nodes (2x D2s_v3): ~$135/month
- Key Vault: ~$1/month  
- VNet: $0 (free)
- **Total:** ~$140/month

---

### Scenario 1 Checklist

- [ ] `terraform apply` completed successfully
- [ ] Resource group created in Azure Portal
- [ ] AKS cluster shows "Running" status
- [ ] 2 nodes visible in kubectl
- [ ] Can connect to cluster with kubectl
- [ ] Estimated cost: ~$140/month

✅ **Congratulations!** You've successfully deployed your first Azure infrastructure with Terraform!

**Time taken:** ~20 minutes (mostly waiting for AKS)

---

## 🗄️ Scenario 2: Add Cosmos DB

**Goal:** Add a managed NoSQL database to your existing infrastructure.

**Time:** ~10 minutes  
**Additional Cost:** +$48/month (total: ~$188/month)

### What You'll Add

```
📦 Existing Resource Group
└── [All resources from Scenario 1]
└── 🌍 Cosmos DB Account (NoSQL API) ← NEW!
    └── 📊 Database: "testdb"
        └── 📋 Container: "items"
```

---

### Step 2.1: Enable Cosmos DB in Configuration

```powershell
# Open dev.tfvars
code dev.tfvars
```

**Find this line** (around line 31) and change it from `false` to `true`:

```hcl
# Before:
enable_cosmosdb = false

# After:
enable_cosmosdb = true  # ← CHANGED!
```

**Add additional Cosmos DB configuration** at the end of the file:

```hcl
# -----------------------------------------------------------------------------
# Cosmos DB Configuration (for Scenario 2)
# -----------------------------------------------------------------------------
cosmosdb_account_name     = "scenariotest-cosmos-dev"
cosmosdb_consistency_level = "Session"  # Good for dev (lower cost than Strong)
cosmosdb_database_name     = "testdb"
cosmosdb_containers = {
  "items" = {
    partition_key_path       = "/userId"
    partition_key_version    = 2
    autoscale_max_throughput = 1000
  }
}
```

💾 **Save the file**.

**What these settings mean:**
- `consistency_level = "Session"`: Balances consistency and performance (good for dev)
- `partition_key_path = "/userId"`: Data is distributed by userId
- `autoscale_max_throughput = 1000`: Automatically scales from 100-1000 RU/s (saves money!)

---

### Step 2.2: Preview the Changes

```powershell
# Plan the changes (only Cosmos DB should be added)
terraform plan -var-file="dev.tfvars" -out=scenario2.tfplan
```

**Expected output:**
```
Terraform will perform the following actions:

  # module.cosmosdb[0].azurerm_cosmosdb_account.account will be created
  + resource "azurerm_cosmosdb_account" "account" {
      + name                = "scenariotest-cosmos-dev"
      + offer_type          = "Standard"
      + kind                = "GlobalDocumentDB"
      + consistency_level   = "Session"
    }

  # module.cosmosdb[0].azurerm_cosmosdb_sql_database.db will be created
  + resource "azurerm_cosmosdb_sql_database" "db" {
      + name       = "testdb"
      + throughput = null
    }

  # module.cosmosdb[0].azurerm_cosmosdb_sql_container.container["items"] will be created
  + resource "azurerm_cosmosdb_sql_container" "container" {
      + name               = "items"
      + partition_key_path = "/userId"
    }

Plan: 3 to add, 0 to change, 0 to destroy.
```

**Key things to verify:**
- ✅ "3 to add, 0 to change, 0 to destroy"
- ✅ You see `azurerm_cosmosdb_account.account` being created
- ✅ **ZERO "to destroy"** - this is important! We're adding, not replacing.
- ❌ No errors

⚠️ **If you see anything "to destroy":** Don't apply! Check [Troubleshooting](#-8-troubleshooting) first.

---

### Step 2.3: Apply the Changes

```powershell
# Apply the plan
terraform apply scenario2.tfplan
```

**Expected output:**
```
module.cosmosdb[0].azurerm_cosmosdb_account.account: Creating...
module.cosmosdb[0].azurerm_cosmosdb_account.account: Still creating... [1m0s elapsed]
module.cosmosdb[0].azurerm_cosmosdb_account.account: Still creating... [2m0s elapsed]
module.cosmosdb[0].azurerm_cosmosdb_account.account: Creation complete after 5m12s

module.cosmosdb[0].azurerm_cosmosdb_sql_database.db: Creating...
module.cosmosdb[0].azurerm_cosmosdb_sql_database.db: Creation complete after 30s

module.cosmosdb[0].azurerm_cosmosdb_sql_container.container["items"]: Creating...
module.cosmosdb[0].azurerm_cosmosdb_sql_container.container["items"]: Creation complete after 45s

Apply complete! Resources: 3 added, 0 changed, 0 destroyed.

Outputs:

cosmosdb_endpoint = "https://scenariotest-cosmos-dev.documents.azure.com:443/"
cosmosdb_database_name = "testdb"
```

⏱️ **Time:** ~5-7 minutes (Cosmos DB accounts take time to provision)

---

### Step 2.4: Verify Deployment (Azure CLI)

```powershell
# Check Cosmos DB account
az cosmosdb show --resource-group scenariotest-rg-dev --name scenariotest-cosmos-dev --query "{Name:name, Status:provisioningState, ConsistencyLevel:consistencyPolicy.defaultConsistencyLevel}" --output table

# List databases
az cosmosdb sql database list --resource-group scenariotest-rg-dev --account-name scenariotest-cosmos-dev --output table

# List containers in the database
az cosmosdb sql container list --resource-group scenariotest-rg-dev --account-name scenariotest-cosmos-dev --database-name testdb --output table
```

**Expected output:**
```
Name                      Status     ConsistencyLevel
------------------------  ---------  -----------------
scenariotest-cosmos-dev   Succeeded  Session

DatabaseName
------------
testdb

ContainerName    PartitionKey
---------------  --------------
items            /userId
```

✅ **Success indicators:**
- Status = "Succeeded"
- Database "testdb" exists
- Container "items" with partition key "/userId" exists

---

### Step 2.5: Verify Deployment (Azure Portal)

1. **Open Azure Portal:** https://portal.azure.com
2. **Navigate to your resource group:** scenariotest-rg-dev
3. **Click on Cosmos DB account:** scenariotest-cosmos-dev
4. **Check Overview:**
   - Status: ✅ Online
   - API: Core (SQL)
5. **Click on "Data Explorer" in left menu**
6. **Expand your database:** testdb → items
7. **You should see:**
   ```
   🌍 scenariotest-cosmos-dev
   └── 📊 testdb
       └── 📋 items
           ├── Partition key: /userId
           └── Throughput: Autoscale (max 1000 RU/s)
   ```

**Screenshot description:** Data Explorer shows your database structure with the "items" container. Throughput shows "Autoscale" with a max of 1000 RU/s.

---

### Step 2.6: Test Cosmos DB (Insert Sample Data)

Let's insert some test data to verify everything works:

```powershell
# Get the Cosmos DB connection information
$COSMOS_NAME = "scenariotest-cosmos-dev"
$DB_NAME = "testdb"
$CONTAINER_NAME = "items"

# Get the primary key
$PRIMARY_KEY = az cosmosdb keys list --name $COSMOS_NAME --resource-group scenariotest-rg-dev --query "primaryMasterKey" --output tsv

# Create a test item using Azure CLI
az cosmosdb sql database container item-upsert `
  --account-name $COSMOS_NAME `
  --resource-group scenariotest-rg-dev `
  --database-name $DB_NAME `
  --container-name $CONTAINER_NAME `
  --item '{\"id\": \"1\", \"userId\": \"user123\", \"name\": \"Test Item\", \"description\": \"This is a test item from Scenario 2\"}'

# Query the data back
az cosmosdb sql database container item-read `
  --account-name $COSMOS_NAME `
  --resource-group scenariotest-rg-dev `
  --database-name $DB_NAME `
  --container-name $CONTAINER_NAME `
  --item-id "1" `
  --partition-key-value "user123"
```

**Expected output:**
```json
{
  "id": "1",
  "userId": "user123",
  "name": "Test Item",
  "description": "This is a test item from Scenario 2",
  "_rid": "...",
  "_ts": 1707659412
}
```

✅ **Success:** You can write and read data from Cosmos DB!

---

### Step 2.7: Check Updated Costs

```powershell
# Check cost trend
az consumption usage list --start-date $(Get-Date).AddDays(-1).ToString("yyyy-MM-dd") --output table
```

💰 **Updated cost breakdown:**
- AKS nodes (2x D2s_v3): ~$135/month (unchanged)
- Cosmos DB (autoscale 100-1000 RU/s): ~$48/month (NEW)
- Key Vault: ~$1/month (unchanged)
- **New Total:** ~$188/month (+$48)

**Cost note:** Because you're using autoscale, Cosmos DB only charges for the RU/s you actually use. If idle, it scales down to 100 RU/s (~$5/month).

---

### Scenario 2 Checklist

- [ ] `terraform apply` added 3 resources (0 destroyed)
- [ ] Cosmos DB account status: "Online"
- [ ] Database "testdb" created
- [ ] Container "items" created with correct partition key
- [ ] Successfully inserted and retrieved test data
- [ ] Estimated cost: ~$188/month

✅ **Excellent!** You've added a database to your infrastructure without breaking anything!

**What you learned:**
- How to add resources incrementally
- How to verify no existing resources are affected (0 to destroy)
- How to test Cosmos DB with sample data
- How additional resources affect cost

---

## 🌐 Scenario 3: Add App Service

**Goal:** Add Azure App Service (Web Apps) for hosting a web application or REST API.

**Time:** ~8 minutes  
**Additional Cost:** +$55/month (total: ~$243/month)

### What You'll Add

```
📦 Existing Resource Group
└── [All resources from Scenarios 1 & 2]
└── 🏢 App Service Plan (Linux, B2 tier) ← NEW!
    └── 🌐 App Service (Web App) ← NEW!
```

---

### Step 3.1: Enable Web App in Configuration

```powershell
# Open dev.tfvars
code dev.tfvars
```

**Find this line** (around line 30) and change it from `false` to `true`:

```hcl
# Before:
enable_webapp = false

# After:
enable_webapp = true  # ← CHANGED!
```

**Add Web App configuration** at the end of the file:

```hcl
# -----------------------------------------------------------------------------
# Web App Configuration (for Scenario 3)
# -----------------------------------------------------------------------------
webapp_name         = "scenariotest-webapp-dev"
webapp_sku          = "B2"  # Basic tier: 2 cores, 3.5GB RAM (~$55/month)
webapp_runtime      = "NODE|18-lts"  # Node.js 18 LTS (change if needed)
```

💾 **Save the file**.

**What these settings mean:**
- `B2` SKU: Basic tier with 2 cores and 3.5GB RAM (good for testing)
- `NODE|18-lts`: Runs Node.js 18. Other options:
  - `DOTNETCORE|8.0` for .NET 8
  - `PYTHON|3.11` for Python 3.11
  - `JAVA|17-java17` for Java 17

---

### Step 3.2: Preview the Changes

```powershell
# Plan the changes
terraform plan -var-file="dev.tfvars" -out=scenario3.tfplan
```

**Expected output:**
```
Terraform will perform the following actions:

  # module.webapp[0].azurerm_service_plan.plan will be created
  + resource "azurerm_service_plan" "plan" {
      + name            = "scenariotest-plan-dev"
      + os_type         = "Linux"
      + sku_name        = "B2"
    }

  # module.webapp[0].azurerm_linux_web_app.app will be created
  + resource "azurerm_linux_web_app" "app" {
      + name                = "scenariotest-webapp-dev"
      + https_only          = true
      + default_hostname    = "scenariotest-webapp-dev.azurewebsites.net"
    }

Plan: 2 to add, 0 to change, 0 to destroy.
```

**Key things to verify:**
- ✅ "2 to add, 0 to change, 0 to destroy"
- ✅ You see `azurerm_service_plan.plan` being created
- ✅ You see `azurerm_linux_web_app.app` being created
- ✅ **ZERO "to destroy"** - still building incrementally!
- ❌ No errors

⚠️ **If you see "Error: Web App name already exists":** The name must be globally unique. Change `webapp_name` in `dev.tfvars` to something more unique (e.g., add your initials).

---

### Step 3.3: Apply the Changes

```powershell
# Apply the plan
terraform apply scenario3.tfplan
```

**Expected output:**
```
module.webapp[0].azurerm_service_plan.plan: Creating...
module.webapp[0].azurerm_service_plan.plan: Creation complete after 12s

module.webapp[0].azurerm_linux_web_app.app: Creating...
module.webapp[0].azurerm_linux_web_app.app: Still creating... [1m0s elapsed]
module.webapp[0].azurerm_linux_web_app.app: Creation complete after 1m45s

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:

webapp_default_hostname = "scenariotest-webapp-dev.azurewebsites.net"
webapp_id = "/subscriptions/.../resourceGroups/scenariotest-rg-dev/providers/Microsoft.Web/sites/scenariotest-webapp-dev"
```

⏱️ **Time:** ~2-3 minutes

---

### Step 3.4: Verify Deployment (Azure CLI)

```powershell
# Check App Service status
az webapp show --resource-group scenariotest-rg-dev --name scenariotest-webapp-dev --query "{Name:name, State:state, DefaultHostName:defaultHostName}" --output table

# Check App Service Plan
az appservice plan show --resource-group scenariotest-rg-dev --name scenariotest-plan-dev --query "{Name:name, Tier:sku.tier, Size:sku.name, Status:status}" --output table
```

**Expected output:**
```
Name                       State     DefaultHostName
-------------------------  --------  ----------------------------------------
scenariotest-webapp-dev    Running   scenariotest-webapp-dev.azurewebsites.net

Name                    Tier    Size  Status
----------------------  ------  ----  ------
scenariotest-plan-dev   Basic   B2    Ready
```

✅ **Success indicators:**
- State = "Running"
- Status = "Ready"
- Default hostname is displayed

---

### Step 3.5: Verify Deployment (Azure Portal)

1. **Open Azure Portal:** https://portal.azure.com
2. **Navigate to your resource group:** scenariotest-rg-dev
3. **Click on App Service:** scenariotest-webapp-dev
4. **Check Overview:**
   - Status: ✅ Running
   - URL: https://scenariotest-webapp-dev.azurewebsites.net
5. **Click the URL** (opens in browser)
6. **What you should see:**
   - Default Azure App Service page (shows your app is running!)
   - Message: "Your web app is running and waiting for your content"

**Screenshot description:** The default Azure App Service landing page with a blue and white theme, indicating the service is online and ready to receive your application code.

---

### Step 3.6: Test the Web App

```powershell
# Test the web app endpoint
curl https://scenariotest-webapp-dev.azurewebsites.net

# Or open in browser:
Start-Process "https://scenariotest-webapp-dev.azurewebsites.net"
```

**Expected result:** You should see the default Azure App Service HTML page load successfully.

---

### Step 3.7: Configure Environment Variables (Connect to Cosmos DB)

Let's configure the Web App to access Cosmos DB:

```powershell
# Get Cosmos DB connection string
$COSMOS_CONNECTION_STRING = az cosmosdb keys list `
  --name scenariotest-cosmos-dev `
  --resource-group scenariotest-rg-dev `
  --type connection-strings `
  --query "connectionStrings[0].connectionString" `
  --output tsv

# Set app settings (environment variables)
az webapp config appsettings set `
  --resource-group scenariotest-rg-dev `
  --name scenariotest-webapp-dev `
  --settings `
    COSMOS_CONNECTION_STRING=$COSMOS_CONNECTION_STRING `
    COSMOS_DATABASE_NAME="testdb" `
    COSMOS_CONTAINER_NAME="items" `
    APP_ENVIRONMENT="development"

# Verify settings were applied
az webapp config appsettings list `
  --resource-group scenariotest-rg-dev `
  --name scenariotest-webapp-dev `
  --output table
```

**Expected output:**
```
Name                       Value
-------------------------  -----------------------------------------
COSMOS_CONNECTION_STRING   AccountEndpoint=https://scenariotest...
COSMOS_DATABASE_NAME       testdb
COSMOS_CONTAINER_NAME      items
APP_ENVIRONMENT            development
```

✅ **Success:** Your Web App now has the connection information for Cosmos DB!

**How to use in your app code:**
```javascript
// Node.js example
const connectionString = process.env.COSMOS_CONNECTION_STRING;
const databaseName = process.env.COSMOS_DATABASE_NAME;
```

---

### Step 3.8: Check Updated Costs

💰 **Updated cost breakdown:**
- AKS nodes (2x D2s_v3): ~$135/month (unchanged)
- Cosmos DB (autoscale): ~$48/month (unchanged)
- App Service Plan (B2 - Linux): ~$55/month (NEW)
- Key Vault: ~$1/month (unchanged)
- **New Total:** ~$243/month (+$55)

---

### Scenario 3 Checklist

- [ ] `terraform apply` added 2 resources (0 destroyed)
- [ ] App Service status: "Running"
- [ ] Can access Web App URL in browser
- [ ] Environment variables configured with Cosmos DB connection
- [ ] Estimated cost: ~$243/month

✅ **Fantastic!** You now have a complete stack: compute (AKS + Web App), data (Cosmos DB), and security (Key Vault)!

**What you learned:**
- How to add App Service to existing infrastructure
- How to configure environment variables for app settings
- How to connect Web App to Cosmos DB
- The  incremental nature of Infrastructure as Code

---

## 🚀 Scenario 4: Deploy to Production

**Goal:** Deploy a production-ready environment with enhanced security and redundancy.

**Time:** ~25 minutes  
**Cost:** ~$450/month (separate from dev)

### What's Different in Production

| Aspect | Development | Production |
|--------|-------------|------------|
| **Environment** | dev | prod |
| **Nodes** | 2 (fixed) | 3-10 (autoscale) |
| **Cosmos DB** | Single region | Multi-region with failover |
| **Security** | Public access | Private endpoints |
| **Monitoring** | Minimal | Full diagnostics + alerts |
| **Backup** | Periodic | Continuous |
| **Cost** | ~$243/month | ~$450/month |

---

### Step 4.1: Create Production Configuration Folder

```powershell
# Navigate to envs folder
cd ..\..  # Go back to infra folder
cd envs

# Verify you see prod folder
ls

# Navigate to prod folder
cd prod
```

**What you should see:**
```
Directory: C:\Users\...\terraform-framework\infra\envs\prod

Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-a----        2026-02-11     10:00           2234 backend.tf
-a----        2026-02-11     10:00          15234 main.tf
-a----        2026-02-11     10:00           3456 outputs.tf
-a----        2026-02-11     10:00           8234 prod.tfvars
-a----        2026-02-11     10:00           4567 variables.tf
```

---

### Step 4.2: Configure Production Backend

```powershell
# Open backend.tf
code backend.tf
```

**Edit the file** to use the same storage account but a different state file:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "contoso-tfstate-rg"
    storage_account_name = "stcontosotfstate001"  # ← SAME as dev!
    container_name       = "tfstate"
    key                  = "prod.terraform.tfstate"  # ← DIFFERENT KEY!
    use_azuread_auth     = true
  }
}
```

💾 **Save the file**.

**Important:** The `key` is different (`prod.terraform.tfstate`), so dev and prod states are completely separate!

---

### Step 4.3: Configure Production Variables

```powershell
# Open prod.tfvars
code prod.tfvars
```

**Replace the entire content with this:**

```hcl
# =============================================================================
# PRODUCTION ENVIRONMENT - Security and reliability first!
# =============================================================================
# Philosophy: High availability, security, monitoring
# Monthly cost estimate: $400-600
# =============================================================================

# -----------------------------------------------------------------------------
# Basic Configuration
# -----------------------------------------------------------------------------
organization_name = "contoso"           # ← Same as dev
project_name      = "scenariotest"     # ← Same as dev (different resources due to env)
location          = "southeastasia"    # ← Same as dev (or choose different region)

# Azure AD Configuration
tenant_id = "12345678-90ab-cdef-1234-567890abcdef"  # ← PASTE YOUR TENANT ID

# Governance
cost_center    = "Engineering-Production"
owner_email    = "your.email@company.com"  # ← Your email
repository_url = "https://github.com/yourorg/terraform-framework"

# -----------------------------------------------------------------------------
# Feature Toggles - Production-grade features
# -----------------------------------------------------------------------------
enable_aks            = true   # Full AKS cluster
enable_container_apps = false
enable_webapp         = true   # Web App
enable_cosmosdb       = true   # Multi-region database
enable_key_vault      = true   # Always enabled

# -----------------------------------------------------------------------------
# Security Features - ENABLED for production
# -----------------------------------------------------------------------------
enable_nat_gateway         = true   # Secure outbound traffic
enable_private_endpoints   = true   # No public access
enable_ddos_protection     = false  # Optional: adds $3000/month!
key_vault_purge_protection = true   # Prevent accidental deletion
network_acl_default_action = "Deny" # Deny all by default

# -----------------------------------------------------------------------------
# Monitoring - Full production monitoring
# -----------------------------------------------------------------------------
enable_application_insights = true
enable_diagnostic_settings  = true
log_retention_days          = 90  # Longer retention for compliance

# -----------------------------------------------------------------------------
# Scaling - Production-grade scaling
# -----------------------------------------------------------------------------
enable_auto_scaling      = true
enable_geo_redundancy    = true   # Multi-region for Cosmos DB
enable_continuous_backup = true   # Point-in-time restore
aks_node_count           = 3      # Min 3 nodes for HA
aks_max_node_count       = 10     # Auto-scale up to 10
aks_node_size            = "Standard_D4s_v3"  # 4 CPU, 16GB RAM

# -----------------------------------------------------------------------------
# Cosmos DB Configuration - Multi-region setup
# -----------------------------------------------------------------------------
cosmosdb_account_name      = "scenariotest-cosmos-prod"
cosmosdb_consistency_level = "Session"  # Or "Strong" for stronger guarantees
cosmosdb_database_name     = "proddb"
cosmosdb_failover_locations = [
  {
    location          = "westus"
    failover_priority = 1
  }
]
cosmosdb_containers = {
  "items" = {
    partition_key_path       = "/userId"
    partition_key_version    = 2
    autoscale_max_throughput = 4000  # Higher for production
  }
}

# -----------------------------------------------------------------------------
# Web App Configuration - Production settings
# -----------------------------------------------------------------------------
webapp_name    = "scenariotest-webapp-prod"
webapp_sku     = "P1v3"  # Premium tier: 2 cores, 8GB RAM, better SLA
webapp_runtime = "NODE|18-lts"
```

**Important changes from dev:**
1. Update `tenant_id` with your actual tenant ID
2. Update `owner_email` with your email
3. Note the production-specific settings (more nodes, better SKUs, security enabled)

💾 **Save the file**.

---

### Step 4.4: Initialize Production Environment

```powershell
# Initialize Terraform for production
terraform init
```

**Expected output:**
```
Initializing the backend...

Successfully configured the backend "azurerm"!

Terraform has been successfully initialized!
```

✅ **Checkpoint:** Production environment is initialized with its own state file.

---

### Step 4.5: Preview Production Deployment

```powershell
# Plan production deployment
terraform plan -var-file="prod.tfvars" -out=production.tfplan
```

**Expected output (abbreviated):**
```
Terraform will perform the following actions:

  # azurerm_resource_group.main will be created
  + resource "azurerm_resource_group" "main" {
      + name     = "scenariotest-rg-prod"  # ← Different from dev!
    }

  # module.aks[0].azurerm_kubernetes_cluster.aks will be created
  + resource "azurerm_kubernetes_cluster" "aks" {
      + name       = "scenariotest-aks-prod"  # ← Different from dev!
      + node_count = 3  # ← More nodes than dev!
    }

  # module.cosmosdb[0].azurerm_cosmosdb_account.account will be created
  + resource "azurerm_cosmosdb_account" "account" {
      + name     = "scenariotest-cosmos-prod"  # ← Different from dev!
      + geo_replicated = true  # ← Multi-region!
    }

Plan: 18 to add, 0 to change, 0 to destroy.
```

**Key things to verify:**
- ✅ All resource names end with `-prod` (not `-dev`)
- ✅ Resource group is `scenariotest-rg-prod`
- ✅ Plan shows ~18-20 resources to add
- ✅ AKS node_count = 3 (not 2)
- ❌ No errors

---

### Step 4.6: Apply Production Deployment

⚠️ **WARNING:** This creates production resources that cost ~$450/month. Ensure you understand the costs before proceeding.

```powershell
# Deploy production environment
terraform apply production.tfplan
```

**Expected output:**
```
module.networking.azurerm_virtual_network.vnet: Creating...
module.networking.azurerm_virtual_network.vnet: Creation complete after 8s

module.aks[0].azurerm_kubernetes_cluster.aks: Creating...
module.aks[0].azurerm_kubernetes_cluster.aks: Still creating... [5m0s elapsed]
module.aks[0].azurerm_kubernetes_cluster.aks: Still creating... [10m0s elapsed]
module.aks[0].azurerm_kubernetes_cluster.aks: Still creating... [15m0s elapsed]
module.aks[0].azurerm_kubernetes_cluster.aks: Creation complete after 18m34s

module.cosmosdb[0].azurerm_cosmosdb_account.account: Creating...
module.cosmosdb[0].azurerm_cosmosdb_account.account: Still creating... [5m0s elapsed]
module.cosmosdb[0].azurerm_cosmosdb_account.account: Creation complete after 7m23s

Apply complete! Resources: 18 added, 0 changed, 0 destroyed.
```

⏱️ **Time:** ~20-25 minutes (production resources take longer)

---

### Step 4.7: Verify Both Environments Exist Separately

```powershell
# List all resource groups
az group list --query "[?contains(name, 'scenariotest')].{Name:name, Location:location}" --output table
```

**Expected output:**
```
Name                     Location
-----------------------  ----------
scenariotest-rg-dev      southeastasia
scenariotest-rg-prod     southeastasia
contoso-tfstate-rg       southeastasia
```

✅ **Success:** You have TWO separate environments running simultaneously!

```powershell
# Compare dev and prod AKS clusters
az aks list --query "[?contains(name, 'scenariotest')].{Name:name, NodeCount:agentPoolProfiles[0].count, VmSize:agentPoolProfiles[0].vmSize, ResourceGroup:resourceGroup}" --output table
```

**Expected output:**
```
Name                     NodeCount  VmSize             ResourceGroup
-----------------------  ---------  -----------------  -----------------------
scenariotest-aks-dev     2          Standard_D2s_v3    scenariotest-rg-dev
scenariotest-aks-prod    3          Standard_D4s_v3    scenariotest-rg-prod
```

**Notice the differences:**
- Dev: 2 smaller nodes (D2s_v3)
- Prod: 3 larger nodes (D4s_v3)

---

### Step 4.8: Verify Production in Azure Portal

1. **Open Azure Portal:** https://portal.azure.com
2. **Navigate to Resource Groups**
3. **You should see TWO resource groups:**
   - `scenariotest-rg-dev` (from Scenarios 1-3)
   - `scenariotest-rg-prod` (just created)
4. **Click on `scenariotest-rg-prod`**
5. **Verify these resources exist:**
   ```
   📦 scenariotest-rg-prod
   ├── ☸️ scenariotest-aks-prod (3 nodes)
   ├── 🌍 scenariotest-cosmos-prod (multi-region)
   ├── 🌐 scenariotest-webapp-prod (Premium tier)
   ├── 🔐 scenariotest-kv-prod
   ├── 🌐 scenariotest-vnet-prod
   └── [Additional networking resources]
   ```

6. **Check Cosmos DB multi-region:**
   - Click on `scenariotest-cosmos-prod`
   - Go to "Replicate data globally"
   - **What you should see:** Two regions (eastus + westus) with automatic failover configured

**Screenshot description:** The Cosmos DB "Replicate data globally" page showing a map with two data center icons (East US and West US) connected by lines, indicating multi-region replication.

---

### Step 4.9: Compare Environment Costs

```powershell
# Get cost for dev environment (approximate)
az consumption usage list `
  --start-date $(Get-Date).AddDays(-1).ToString("yyyy-MM-dd") `
  --query "[?contains(resourceGroup, 'scenariotest-rg-dev')]" `
  --output table

# Get cost for prod environment (approximate)
az consumption usage list `
  --start-date $(Get-Date).AddDays(-1).ToString("yyyy-MM-dd") `
  --query "[?contains(resourceGroup, 'scenariotest-rg-prod')]" `
  --output table
```

💰 **Cost comparison:**

| Environment | Daily | Monthly |
|-------------|-------|---------|
| **Dev**     | ~$8   | ~$243   |
| **Prod**    | ~$15  | ~$450   |
| **Total**   | ~$23  | ~$693   |

---

### Scenario 4 Checklist

- [ ] Production environment initialized with separate state
- [ ] `terraform apply` completed successfully
- [ ] Both `scenariotest-rg-dev` and `scenariotest-rg-prod` exist  
- [ ] Production has 3 AKS nodes (vs 2 in dev)
- [ ] Cosmos DB shows multi-region replication
- [ ] Can distinguish between dev and prod resources
- [ ] Estimated total cost: ~$693/month (both environments)

✅ **Outstanding!** You now understand multi-environment deployment and production-grade configurations!

**What you learned:**
- How to maintain separate environments (dev/prod)
- The difference between dev and production configurations
- How to use the same backend storage with different state files
- Production best practices (more nodes, better SKUs, security features)
- Cost implications of production-grade infrastructure

---

## 🧹 Scenario 5: Clean Up Everything

**Goal:** Safely destroy all resources to avoid ongoing costs.

**Time:** ~20 minutes  
**Cost Saved:** ~$693/month

⚠️ **CRITICAL WARNING:** This will permanently delete all resources. Data will be lost!

---

### Step 5.1: Understand What Will Be Deleted

You currently have TWO environments:
- **Dev environment:** ~$243/month
- **Prod environment:** ~$450/month

We'll delete them in order: Prod first (most expensive), then Dev.

---

### Step 5.2: Destroy Production Environment

```powershell
# Make sure you're in the prod folder
cd C:\Users\YourName\codes\terraform-framework\infra\envs\prod

# Verify you're in the right place
pwd
# Should show: ...\infra\envs\prod

# Preview what will be destroyed
terraform plan -destroy -var-file="prod.tfvars" -out=destroy-prod.tfplan
```

**Expected output:**
```
Terraform will perform the following actions:

  # module.aks[0].azurerm_kubernetes_cluster.aks will be destroyed
  - resource "azurerm_kubernetes_cluster" "aks" {
      - name = "scenariotest-aks-prod"
    }

  # module.cosmosdb[0].azurerm_cosmosdb_account.account will be destroyed
  - resource "azurerm_cosmosdb_account" "account" {
      - name = "scenariotest-cosmos-prod"
    }

  [... more resources ...]

Plan: 0 to add, 0 to change, 18 to destroy.
```

**Key things to verify:**
- ✅ "0 to add, 0 to change, 18 to destroy"
- ✅ All resources have `-prod` suffix (not `-dev`!)
- ✅ Only production resources are listed
- ❌ No `-dev` resources in the list

⚠️ **Final confirmation:** Are you 100% sure you want to delete production?

```powershell
# Apply the destruction plan
terraform apply destroy-prod.tfplan
```

**Expected output:**
```
module.webapp[0].azurerm_linux_web_app.app: Destroying...
module.webapp[0].azurerm_linux_web_app.app: Destruction complete after 45s

module.cosmosdb[0].azurerm_cosmosdb_sql_container.container["items"]: Destroying...
module.cosmosdb[0].azurerm_cosmosdb_sql_container.container["items"]: Destruction complete after 12s

module.cosmosdb[0].azurerm_cosmosdb_sql_database.db: Destroying...
module.cosmosdb[0].azurerm_cosmosdb_sql_database.db: Destruction complete after 8s

module.cosmosdb[0].azurerm_cosmosdb_account.account: Destroying...
module.cosmosdb[0].azurerm_cosmosdb_account.account: Still destroying... [2m0s elapsed]
module.cosmosdb[0].azurerm_cosmosdb_account.account: Destruction complete after 3m45s

module.aks[0].azurerm_kubernetes_cluster.aks: Destroying...
module.aks[0].azurerm_kubernetes_cluster.aks: Still destroying... [5m0s elapsed]
module.aks[0].azurerm_kubernetes_cluster.aks: Destruction complete after 8m12s

module.networking.azurerm_virtual_network.vnet: Destroying...
module.networking.azurerm_virtual_network.vnet: Destruction complete after 15s

azurerm_resource_group.main: Destroying...
azurerm_resource_group.main: Destruction complete after 45s

Destroy complete! Resources: 18 destroyed.
```

⏱️ **Time:** ~10 minutes (AKS takes the longest to delete)

---

### Step 5.3: Verify Production is Deleted

```powershell
# Check if resource group still exists
az group show --name scenariotest-rg-prod
```

**Expected output:**
```
ResourceNotFound: Resource group 'scenariotest-rg-prod' could not be found.
```

✅ **Success:** Production environment is completely deleted!

---

### Step 5.4: Destroy Development Environment

```powershell
# Navigate to dev folder
cd ..\dev

# Verify you're in the right place
pwd
# Should show: ...\infra\envs\dev

# Preview what will be destroyed
terraform plan -destroy -var-file="dev.tfvars" -out=destroy-dev.tfplan
```

**Expected output:**
```
Plan: 0 to add, 0 to change, 15 to destroy.
```

**Key things to verify:**
- ✅ All resources have `-dev` suffix
- ✅ About 15 resources to destroy
- ❌ No `-prod` resources (already deleted)

```powershell
# Destroy dev environment
terraform apply destroy-dev.tfplan
```

**Expected output:**
```
[Similar destruction progress as production]

Destroy complete! Resources: 15 destroyed.
```

⏱️ **Time:** ~10 minutes

---

### Step 5.5: Verify Development is Deleted

```powershell
# Check if resource group still exists
az group show --name scenariotest-rg-dev
```

**Expected output:**
```
ResourceNotFound: Resource group 'scenariotest-rg-dev' could not be found.
```

✅ **Success:** Development environment is completely deleted!

---

### Step 5.6: Cleanup Terraform State Storage (Optional)

If you're completely done and want to delete the state storage too:

```powershell
# Delete the state storage resource group
az group delete --name contoso-tfstate-rg --yes --no-wait

# Check deletion status
az group show --name contoso-tfstate-rg --query properties.provisioningState
```

⚠️ **Warning:** This deletes the Terraform state files. Only do this if you're completely finished with all scenarios!

---

### Step 5.7: Final Verification (Azure Portal)

1. **Open Azure Portal:** https://portal.azure.com
2. **Navigate to Resource Groups**
3. **What you should see:**
   - ❌ `scenariotest-rg-dev` - GONE
   - ❌ `scenariotest-rg-prod` - GONE
   - ❌ `contoso-tfstate-rg` - GONE (if you deleted it in Step 5.6)
4. **Resource Groups should be nearly empty** (only default Azure subscriptions remain)

**Screenshot description:** The Resource Groups page showing an empty list or only system/default resource groups, with no "scenariotest" prefixed groups.

---

### Step 5.8: Verify No Ongoing Costs

```powershell
# Check cost for the current day
az consumption usage list --start-date $(Get-Date).ToString("yyyy-MM-dd") --output table
```

**Expected:** No charges for "scenariotest" resources. Any remaining charges are from deletion activity (minimal).

💰 **Cost saved:** ~$693/month! 🎉

---

### Scenario 5 Checklist

- [ ] Production environment destroyed (18 resources)
- [ ] Development environment destroyed (15 resources)
- [ ] Both resource groups deleted and verified
- [ ] (Optional) State storage deleted
- [ ] No "scenariotest" resources in Azure Portal
- [ ] Estimated cost reduced to $0/month

✅ **Perfect cleanup!** You've safely destroyed all test resources to avoid ongoing costs.

**What you learned:**
- How to use `terraform plan -destroy` to preview deletions
- The importance of verifying what will be deleted before applying
- Destruction happens in reverse dependency order (apps → data → network → group)
- How to verify complete cleanup
- Cost implications of leaving resources running

---

## 🔧 8. Troubleshooting

Common issues and how to fix them.

---

### Issue 1: "Storage account name already exists"

**Symptoms:**
```
Error: creating Storage Account "tfstate12345": storage.AccountsClient#Create:
Failure responding to request: StatusCode=409
Code="StorageAccountAlreadyTaken"
Message="The storage account named tfstate12345 is already taken."
```

**Cause:** Storage account names must be globally unique across all of Azure.

**Solution:**
```powershell
# Generate a new unique name with more random digits
$STORAGE_ACCOUNT = "tfstate$(Get-Random -Maximum 999999)"
Write-Host "New storage account name: $STORAGE_ACCOUNT"

# Retry creating the storage account with the new name
az storage account create --name $STORAGE_ACCOUNT --resource-group contoso-tfstate-rg --location southeastasia --sku Standard_LRS
```

---

### Issue 2: "Invalid count argument"

**Symptoms:**
```
Error: Invalid count argument

on main.tf line 45, in module "aks":
  count = var.enable_aks ? 1 : 0

The "count" value depends on resource attributes that cannot be determined until apply.
```

**Cause:** You enabled a feature but didn't provide required variables.

**Solution:**
Check `dev.tfvars` for missing required variables. If `enable_aks = true`, ensure these variables are set:
```hcl
aks_node_count = 2
aks_node_size  = "Standard_D2s_v3"
```

---

### Issue 3: "Authentication failed"

**Symptoms:**
```
Error: Error building account: Error getting authenticated object ID: getting authenticated object ID: Error listing Service Principals
```

**Cause:** Not logged into Azure CLI or session expired.

**Solution:**
```powershell
# Login again
az login

# Verify you're logged in
az account show

# Set the correct subscription
az account set --subscription "Your Subscription Name"

# Retry terraform
terraform plan -var-file="dev.tfvars"
```

---

### Issue 4: "Insufficient permissions"

**Symptoms:**
```
Error: authorization.RoleAssignmentsClient#Create: Failure responding to request:
StatusCode=403 -- Original Error: The client with object id does not have authorization
to perform action 'Microsoft.Authorization/roleAssignments/write'
```

**Cause:** Your Azure account lacks required permissions.

**Solution:**
```powershell
# Check your current roles
az role assignment list --assignee your.email@company.com --output table

# Ask your Azure administrator to grant you:
# 1. Contributor (for creating resources)
# 2. User Access Administrator (for role assignments)
# Or simply: Owner role (includes both)
```

---

### Issue 5: "Plan shows unexpected changes"

**Symptoms:**
You run `terraform plan` and it wants to change or destroy existing resources you didn't modify.

**Cause:** Could be:
1. Someone made manual changes in Azure Portal
2. Terraform state is out of sync
3. Provider version changed

**Solution:**
```powershell
# Refresh state to match reality
terraform refresh -var-file="dev.tfvars"

# Review the plan carefully
terraform plan -var-file="dev.tfvars"

# If the changes look reasonable, apply them:
terraform apply -var-file="dev.tfvars"

# If unsure, ask your team or restore from a backup
```

---

### Issue 6: "Error locking state"

**Symptoms:**
```
Error: Error acquiring the state lock

Error message: Blob is already locked by lease id xxxxxx
```

**Cause:** Another terraform operation is running, or a previous one didn't complete cleanly.

**Solution:**

**Option 1: Wait** - If someone else is running terraform, wait for them to finish.

**Option 2: Force unlock** (only if you're SURE no one else is running):
```powershell
# Force unlock (use the Lock ID from the error message)
terraform force-unlock xxxxx-xxxxx-xxxxx
```

---

### Issue 7: "Cosmos DB: partition key already set"

**Symptoms:**
```
Error: Partition key cannot be changed

The partition key for container "items" cannot be changed after creation.
```

**Cause:** You tried to change the partition key of an existing container.

**Solution:**
Partition keys are immutable. You must:

**Option 1: Create a new container:**
```hcl
cosmosdb_containers = {
  "items-v2" = {  # New name
    partition_key_path = "/newKey"
    ...
  }
}
```

**Option 2: Destroy and recreate** (⚠️ DATA LOSS!):
```powershell
# This will delete the container and all data!
terraform destroy -target=module.cosmosdb[0].azurerm_cosmosdb_sql_container.container[\"items\"] -var-file="dev.tfvars"

# Then apply with new partition key
terraform apply -var-file="dev.tfvars"
```

---

### Issue 8: "AKS: VM size not available"

**Symptoms:**
```
Error: creating Managed Kubernetes Cluster: containerservice.ManagedClustersClient#CreateOrUpdate:
Failure sending request: StatusCode=400
Code="InvalidParameter"
Message="The VM SKU 'Standard_D2s_v3' is not available in this region."
```

**Cause:** The VM size you selected isn't available in your chosen region.

**Solution:**
```powershell
# Check available VM sizes in your region
az vm list-skus --location eastus --size Standard_D --output table | grep -i "available"

# Common alternatives:
# - Standard_D2s_v3 → Standard_DS2_v2
# - Standard_D4s_v3 → Standard_DS4_v2

# Update dev.tfvars:
aks_node_size = "Standard_DS2_v2"  # Change to available size
```

---

### Issue 9: "State file not found"

**Symptoms:**
```
Error: Failed to get existing workspaces: storage: service returned error:
StatusCode=404, ErrorCode=ContainerNotFound
```

**Cause:** Backend storage doesn't exist or `backend.tf` has wrong configuration.

**Solution:**
```powershell
# Verify backend storage exists
az storage account show --name stcontosotfstate001

# If it doesn't exist, recreate it:
az storage account create --name stcontosotfstate001 --resource-group contoso-tfstate-rg --location southeastasia --sku Standard_LRS

az storage container create --name tfstate --account-name stcontosotfstate001 --auth-mode login

# Then reinitialize terraform
terraform init -reconfigure
```

---

### Issue 10: "Resource name already exists"

**Symptoms:**
```
Error: A resource with the ID "/subscriptions/.../resourceGroups/scenariotest-rg-dev" already exists
```

**Cause:** Resources from a previous run weren't cleaned up or you're trying to create duplicate resources.

**Solution:**

**Option 1: Import existing resource into state:**
```powershell
terraform import azurerm_resource_group.main /subscriptions/YOUR_SUB_ID/resourceGroups/scenariotest-rg-dev
```

**Option 2: Delete manually and retry:**
```powershell
# Delete the existing resource group
az group delete --name scenariotest-rg-dev --yes

# Retry terraform
terraform apply -var-file="dev.tfvars"
```

**Option 3: Use a different name:**
```hcl
# In dev.tfvars:
project_name = "scenariotest2"  # Change to unique name
```

---

## 💰 9. Cost Breakdown

Detailed cost analysis for each scenario.

---

### Scenario 1: AKS Only

| Resource | Specification | Hourly | Daily | Monthly |
|----------|--------------|--------|-------|---------|
| **AKS Node Pool** | 2x Standard_D2s_v3 (2 vCPU, 8GB RAM) | $0.19 | $4.56 | $137.00 |
| **Key Vault** | Standard tier, 100 operations/day | $0.003 | $0.08 | $2.40 |
| **Virtual Network** | Standard VNet with 2 subnets | $0 | $0 | $0 |
| **NSG** | Network Security Group | $0 | $0 | $0 |
| **Public IP** | Basic tier | $0.012 | $0.29 | $8.76 |
| **Bandwidth** | First 5GB free, ~100GB/month | $0.16 | $1.12 | $33.60 |
| **TOTAL** | | **$0.37** | **$8.83** | **$141.76** |

**Notes:**
- AKS control plane is free (Microsoft-managed)
- Storage for system OS disks included
- First 5GB egress bandwidth free

---

### Scenario 2: AKS + Cosmos DB

| Resource | Specification | Hourly | Daily | Monthly |
|----------|--------------|--------|-------|---------|
| **AKS** | (Same as Scenario 1) | $0.19 | $4.56 | $137.00 |
| **Cosmos DB Account** | Session consistency, single region | $0 | $0 | $0 |
| **Cosmos DB Throughput** | Autoscale 100-1000 RU/s (avg 400 RU/s) | $0.067 | $1.60 | $48.00 |
| **Cosmos DB Storage** | 10GB data stored | $0.011 | $0.27 | $8.00 |
| **Key Vault** | (Same as Scenario 1) | $0.003 | $0.08 | $2.40 |
| **Other** | VNet, NSG, IP, Bandwidth | $0.176 | $4.22 | $42.36 |
| **TOTAL** | | **$0.43** | **$10.32** | **$187.76** |

**Cost increase:** +$48/month for Cosmos DB

**Notes:**
- Autoscale starts at 100 RU/s when idle (saves money!)
- Storage charged per GB at $0.27/GB/month
- Backup storage (first 2 copies) included free

---

### Scenario 3: Full Stack (AKS + Cosmos DB + App Service)

| Resource | Specification | Hourly | Daily | Monthly |
|----------|--------------|--------|-------|---------|
| **AKS** | (Same as Scenario 1) | $0.19 | $4.56 | $137.00 |
| **Cosmos DB** | (Same as Scenario 2) | $0.078 | $1.87 | $56.00 |
| **App Service Plan** | B2 - Linux (2 cores, 3.5GB RAM) | $0.075 | $1.80 | $54.00 |
| **Key Vault** | (Same as Scenario 1) | $0.003 | $0.08 | $2.40 |
| **Other** | VNet, NSG, IP, Bandwidth | $0.176 | $4.22 | $42.36 |
| **TOTAL** | | **$0.522** | **$12.53** | **$291.76** |

**Cost increase:** +$54/month for App Service

**Notes:**
- B2 tier provides good balance for dev/test
- Includes 50GB storage
- SSL/TLS certificates free

**Cost optimization tips:**
- Scale down App Service Plan during nights/weekends
- Use "Development/Test" pricing if available
- Consider stopping dev resources when not in use

---

### Scenario 4: Production Environment

| Resource | Specification | Hourly | Daily | Monthly |
|----------|--------------|--------|-------|---------|
| **AKS Node Pool** | 3x Standard_D4s_v3 (4 vCPU, 16GB RAM) | $0.76 | $18.24 | $547.00 |
| **Cosmos DB (Multi-region)** | 2 regions, autoscale max 4000 RU/s | $0.27 | $6.48 | $194.40 |
| **App Service Plan** | P1v3 (2 cores, 8GB RAM, better SLA) | $0.227 | $5.45 | $163.50 |
| **NAT Gateway** | Outbound internet traffic | $0.045 | $1.08 | $32.40 |
| **Private Endpoints** | 3 private endpoints | $0.04 | $0.96 | $28.80 |
| **Application Insights** | 5GB/month | $0.01 | $0.24 | $7.20 |
| **Key Vault** | Premium tier | $0.083 | $2.00 | $60.00 |
| **Log Analytics** | 10GB ingestion/month | $0.04 | $0.96 | $28.80 |
| **Other** | VNet, NSG, IP, Bandwidth (higher) | $0.25 | $6.00 | $180.00 |
| **TOTAL** | | **$1.72** | **$41.36** | **$1,242.10** |

**Cost increase:** +$950/month compared to dev

**Production-grade features included:**
- Multi-region failover for Cosmos DB
- Higher availability SLA (99.95%+)
- Better performance (more/larger VMs)
- Enhanced security (Private Endpoints, NAT Gateway)
- Full monitoring and diagnostics

---

### Total Cost Summary (All Scenarios Running)

| Environment | Resources | Monthly Cost |
|-------------|-----------|--------------|
| **Dev (Scenario 1)** | AKS only | $141.76 |
| **Dev (Scenario 2)** | + Cosmos DB | $187.76 |
| **Dev (Scenario 3)** | + App Service | $291.76 |
| **Prod (Scenario 4)** | Production-grade | $1,242.10 |
| **Dev + Prod Parallel** | Both environments | **$1,533.86** |

---

### Cost Optimization Tips

#### For Development:
1. **Stop resources when not in use:**
   ```powershell
   # Stop AKS cluster (pauses node pool VMs)
   az aks stop --resource-group scenariotest-rg-dev --name scenariotest-aks-dev
   
   # Start when needed
   az aks start --resource-group scenariotest-rg-dev --name scenariotest-aks-dev
   ```
   **Savings:** ~$135/month when stopped

2. **Scale down Cosmos DB:**
   ```powershell
   # Reduce max throughput to 400 RU/s
   az cosmosdb sql container throughput update \
     --account-name scenariotest-cosmos-dev \
     --database-name testdb \
     --name items \
     --max-throughput 400
   ```
   **Savings:** ~$24/month

3. **Use smaller VM sizes:**
   ```hcl
   aks_node_size = "Standard_B2s"  # ~$30/month vs $137/month
   ```
   **Savings:** ~$100/month (but slower performance)

#### For Production:
1. **Use Azure Reserved Instances:**
   - Commit to 1-3 years
   - Save up to 72% on compute
   - Apply to AKS nodes, App Service

2. **Enable Cosmos DB autoscale:**
   - Already configured in examples
   - Scales down when idle
   - Saves ~30-50% during low traffic

3. **Set up alerts for unexpected usage:**
   ```powershell
   # Create cost alert
   az consumption budget create \
     --resource-group scenariotest-rg-prod \
     --name "monthly-budget" \
     --amount 1500 \
     --time-grain Monthly
   ```

---

## ❓ 10. FAQ

### General Questions

**Q: Do I need to run the scenarios in order?**  
**A:** Yes, for the first time. Scenario 2 builds on Scenario 1, and Scenario 3 builds on Scenario 2. However, you can skip scenarios by enabling multiple features at once.

**Q: Can I skip Scenario 4 (Production)?**  
**A:** Absolutely! Scenario 4 is optional and primarily demonstrates multi-environment deployment. If you're just learning, you can stop after Scenario 3.

**Q: How long does everything take total?**  
**A:** 
- Setup (Scenario 0): ~15 min
- Scenario 1: ~20 min
- Scenario 2: ~10 min
- Scenario 3: ~8 min
- Scenario 4: ~25 min (optional)
- Cleanup: ~20 min
- **Total: ~1.5-2 hours**

**Q: What if I need to pause in the middle?**  
**A:** No problem! Terraform state is saved after each successful `apply`. You can come back anytime and continue. Just remember you're being charged for running resources.

---

### Azure & Costs

**Q: Will this work with Azure Free Tier?**  
**A:** Partially. The Free Tier includes $200 credit for 30 days, which covers Scenarios 1-3 easily. However, some services (like AKS) don't have a free tier, so you'll use your credit.

**Q: How do I check my current costs?**  
**A:** 
```powershell
# Via CLI
az consumption usage list --start-date $(Get-Date).AddDays(-7).ToString("yyyy-MM-dd") --output table

# Or in Azure Portal:
# Cost Management + Billing → Cost analysis → Filter by resource group
```

**Q: What if I forget to delete resources?**  
**A:** You'll be charged the monthly rate. Set up budget alerts:
```powershell
az consumption budget create --resource-group scenariotest-rg-dev --name "dev-budget" --amount 200 --time-grain Monthly
```

**Q: Can I use a different Azure region?**  
**A:** Yes! Change the `location` variable in `dev.tfvars`. Popular choices: `eastus`, `westus2`, `westeurope`, `southeastasia`.

---

### Terraform Questions

**Q: What if `terraform apply` fails halfway?**  
**A:** Terraform is safe! It will:
1. Keep what was successfully created
2. Save the state
3. Show you the error
4. Let you fix the issue and re-run `terraform apply`

**Q: How do I start over completely?**  
**A:** 
```powershell
# Option 1: Destroy everything
terraform destroy -var-file="dev.tfvars"

# Option 2: Delete the resource group manually
az group delete --name scenariotest-rg-dev --yes
```

**Q: What's the difference between `terraform plan` and `terraform apply`?**  
**A:** 
- `plan`: Shows what WOULD change (preview only, safe)
- `apply`: Actually makes the changes (executes the plan)

**Q: Can multiple people work on the same environment?**  
**A:** Yes, but be careful! The state lock prevents simultaneous changes, but coordinate with your team to avoid conflicts.

---

### Technical Questions

**Q: Why use Terraform instead of Azure Portal?**  
**A:** 
- **Reproducibility:** Create identical environments easily
- **Version Control:** Track changes in Git
- **Automation:** Integrate with CI/CD
- **Documentation:** Your infrastructure IS the documentation

**Q: What's the best partition key for Cosmos DB?**  
**A:** It depends on your data access patterns:
- High cardinality (many unique values)
- Even distribution of requests
- Common examples: `/userId`, `/tenantId`, `/deviceId`
- Avoid: `/country`, `/status` (low cardinality)

**Q: Should I use AKS or App Service?**  
**A:** 
- **Use AKS if:** You need Kubernetes features, microservices, complex orchestration
- **Use App Service if:** Simple web apps, REST APIs, less operational overhead
- **Use Container Apps if:** Similar to App Service but containerized, scale to zero

**Q: How do I connect my application to these resources?**  
**A:** Terraform outputs provide connection strings:
```powershell
# Get Cosmos DB connection string
terraform output cosmosdb_connection_string

# Get Web App URL
terraform output webapp_url

# Get AKS connection command
terraform output aks_kubeconfig_command
```

**Q: Why do I configure Cosmos DB containers in `dev.tfvars` and not in the `modules/cosmosdb/` folder?**  
**A:** This is a core Terraform best practice called **separation of concerns**:

**Architecture Pattern:**
```
┌─────────────────────────────────────┐
│ infra/modules/cosmosdb/             │
│ (REUSABLE TEMPLATE)                 │
│                                     │
│ Defines HOW to create Cosmos DB    │
│ - Generic, no hardcoded values     │
│ - Used by all environments         │
└─────────────────────────────────────┘
                ↑
                │ receives values
                ↓
┌─────────────────────────────────────┐
│ infra/envs/dev/dev.tfvars           │
│ (ENVIRONMENT-SPECIFIC CONFIG)       │
│                                     │
│ Defines WHAT to create              │
│ - Specific to dev environment       │
│ - Different from prod config        │
└─────────────────────────────────────┘
```

**Why this is better:**

1. **Reusability** - Same module works for all environments:
   ```hcl
   # Dev: Small and cheap
   cosmosdb_containers = {
     "items" = { autoscale_max_throughput = 1000 }
   }
   
   # Prod: Larger and more containers
   cosmosdb_containers = {
     "items" = { autoscale_max_throughput = 10000 }
     "audit" = { autoscale_max_throughput = 2000 }
   }
   ```

2. **Flexibility** - Different needs per environment:
   | Environment | Containers | Throughput | Cost |
   |-------------|-----------|------------|------|
   | Dev | 1 | 1000 RU/s | $48/mo |
   | Prod | 3 | 15000 RU/s | $360/mo |

3. **Separation of concerns**:
   - **Module's job:** "I know HOW to create Cosmos DB"
   - **Environment's job:** "I know WHAT config I need"

**Think of it like:**
- **Modules** = Kitchen (can cook anything)
- **Tfvars** = Recipe (what to cook today)

You change the recipe (tfvars), not rebuild the kitchen (module) for each meal!

---

### Troubleshooting FAQs

**Q: Error: "Resource name must be unique"**  
**A:** Many Azure resources require globally unique names (storage accounts, Cosmos DB, Web Apps). Add a unique suffix to your `project_name` in `dev.tfvars`.

**Q: Error: "Authentication failed"**  
**A:**
```powershell
# Re-login
az login
az account set --subscription "Your Subscription Name"
```

**Q: Error: "State locked"**  
**A:** Someone else is running Terraform, or a previous run didn't complete. Wait or force-unlock:
```powershell
terraform force-unlock <lock-id>
```

**Q: Changes I made in Azure Portal are overwritten by Terraform**  
**A:** This is expected! Terraform enforces the configuration in your `.tfvars` files. Make changes in code, not in the Portal.

---

### Next Steps

**Q: I finished all scenarios. What's next?**  
**A:** Great job! Here are next steps:
1. **Learn CI/CD:** Read [docs/AZURE-DEVOPS-SETUP.md](docs/AZURE-DEVOPS-SETUP.md)
2. **Explore modules:** Check `infra/modules/` for other services
3. **Practice:** Try deploying your own application architecture
4. **Advanced topics:** Hub-spoke networking, monitoring, security hardening

**Q: Where can I learn more about Terraform?**  
**A:**
- Official docs: https://www.terraform.io/docs
- Azure provider: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs
- This repo's docs: `docs/` folder

**Q: How do I deploy a real application to this infrastructure?**  
**A:** 
- **For AKS:** Use `kubectl` to deploy containers
- **For App Service:** Use Azure DevOps, GitHub Actions, or `az webapp deploy`
- **Connection strings:** Get from Terraform outputs

---

### Contribution & Support

**Q: I found a bug or typo in this guide. How do I report it?**  
**A:** Open an issue or pull request in the repository!

**Q: Can I share this guide with my team?**  
**A:** Absolutely! This guide is part of your team's documentation.

**Q: I still have questions after reading this guide. Where do I ask?**  
**A:** 
1. Check the other docs in `docs/` folder
2. Ask your team's platform/DevOps team
3. Open an issue in the repository
4. Azure support: https://azure.microsoft.com/support/

---

## 🎓 What You've Learned

**Congratulations!** By completing all scenarios, you now understand:

✅ **Infrastructure as Code fundamentals**
- How to define infrastructure in code
- Benefits of IaC over manual Portal clicks
- Version control for infrastructure

✅ **Terraform workflow**
- `init` → `plan` → `apply` → `destroy`
- State management and backends
- Incremental changes and safety

✅ **Azure services**
- Azure Kubernetes Service (AKS)
- Cosmos DB for NoSQL data
- App Service for web hosting
- Virtual Networks and security

✅ **Multi-environment deployment**
- Dev vs Production configurations
- Separate state management
- Cost implications of different environments

✅ **DevOps best practices**
- Preview changes before applying
- Verify deployments multiple ways (CLI, Portal)
- Clean up resources to control costs
- Troubleshoot common issues

✅ **Cloud cost management**
- Estimate costs before deploying
- Monitor ongoing expenses
- Optimize for cost vs performance
- Clean up to avoid surprise bills

---

## 📚 Recommended Next Steps

1. **Practice!** Run through the scenarios again with different configurations
2. **Explore modules:** Check out other services in `infra/modules/`
3. **Set up CI/CD:** Read [docs/AZURE-DEVOPS-SETUP.md](docs/AZURE-DEVOPS-SETUP.md)
4. **Deploy a real app:** Use this infrastructure for an actual project
5. **Learn advanced topics:** Hub-spoke networking, monitoring, auto-scaling

---

## 🙏 Feedback

Found this guide helpful? Have suggestions for improvement? Please contribute back to the repository!

**Happy Infrastructure Coding!** 🚀

---

*Last updated: February 2026*  
*Framework version: 1.0*  
*Terraform version: >= 1.5.0*  
*Azure CLI version: >= 2.50.0*
