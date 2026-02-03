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
# State: Stored in Azure Storage (terraform-state-rg)
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
      + name     = "myapp-cosmos-dev"
      + location = "eastus"
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
terraform import azurerm_resource_group.main /subscriptions/.../resourceGroups/myapp-rg-dev
```

### "Error: Resource already exists"

**Cause:** Resource exists in Azure but not in state

**Fix:**
```powershell
# Import the existing resource
terraform import <resource_type>.<name> <azure_resource_id>

# Example:
terraform import azurerm_virtual_network.vnet /subscriptions/.../virtualNetworks/myapp-vnet-dev
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

## 💡 Key Takeaway

**Terraform is incremental, not all-or-nothing.**

You deploy your foundation once, then add services over time by:
1. Enabling the feature toggle
2. Running `terraform apply`
3. Only new resources are created

No need to redeploy everything each time! 🎉
