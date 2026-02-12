# Getting Started Guide

A step-by-step guide to deploy your first environment. No prior Azure or Terraform experience required!

---

## What You'll Accomplish

By the end of this guide, you'll have:
- ✅ A complete development environment in Azure
- ✅ Virtual Network with proper subnets
- ✅ Network security groups (firewalls)
- ✅ Log Analytics for monitoring
- ✅ Understanding of how to manage infrastructure as code

**Time required:** About 30-45 minutes

---

## Prerequisites Checklist

Before you start, make sure you have:

### 1. Azure Account

- [ ] Azure subscription (free tier works for learning)
- [ ] Permission to create resources (Contributor role or higher)

**How to check:**
```powershell
# Run this in PowerShell
az account show
```
If you see your subscription details, you're good!

### 2. Tools Installed

- [ ] **Azure CLI** - To talk to Azure
- [ ] **Terraform** - To deploy infrastructure
- [ ] **Git** - To manage code
- [ ] **VS Code** (recommended) - To edit code

**How to install:**

```powershell
# Install Azure CLI (Windows)
winget install Microsoft.AzureCLI

# Install Terraform (Windows)
winget install HashiCorp.Terraform

# Verify installations
az --version
terraform --version
```

### 3. Azure CLI Logged In

```powershell
# Login to Azure
az login

# Set your subscription (if you have multiple)
az account set --subscription "Your Subscription Name"
```

---

## Understanding the Architecture First

Before deploying, understand the **3 logical layers** in this framework:

### Layer 0: Global Standards
**Location:** `infra/global/`  
**What:** Company-wide naming conventions, tags, provider configuration  
**Deploy once:** Yes, shared across all environments

### Layer 1: Landing Zone (Shared Infrastructure)
**Location:** Part of `infra/envs/dev/main.tf` (networking section)  
**What:** Shared networking foundation:
- Virtual Network (VNet)
- Subnets (aks-subnet, app-subnet, data-subnet)
- Network Security Groups (NSGs)
- Log Analytics Workspace

**Deploy once per environment:** Yes, then reuse for all applications

### Layer 2: Workloads (Your Applications)
**Location:** Part of `infra/envs/dev/main.tf` (workload section)  
**What:** Application infrastructure:
- AKS clusters, App Services (compute)
- Cosmos DB, Redis (data)
- Key Vault (secrets)

**Deploy as needed:** Enable/disable via feature toggles in `dev.tfvars`

---

## Step 1: Create Terraform Backend (State Storage)

Terraform needs a place to store its "state" - a record of what it has created.

### Why?
Without shared state:
- You deploy something
- Your teammate doesn't know it exists
- They try to deploy → conflict!

### Create Storage Account

```powershell
# Set variables
$RESOURCE_GROUP = "contoso-tfstate-rg"
$STORAGE_ACCOUNT = "stcontosotfstate001"
$CONTAINER = "tfstate"
$LOCATION = "indonesiacentral"

# Create resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create storage account
az storage account create `
  --name $STORAGE_ACCOUNT `
  --resource-group $RESOURCE_GROUP `
  --location $LOCATION `
  --sku Standard_LRS

# Create container
az storage container create `
  --name $CONTAINER `
  --account-name $STORAGE_ACCOUNT

Write-Host "Backend storage created: $STORAGE_ACCOUNT in $RESOURCE_GROUP"
```

**📝 Write down your storage account name!** You'll need it in Step 3.

---

## Step 2: Clone the Repository

```powershell
# Clone the repository
git clone <your-repo-url> terraform-framework
cd terraform-framework
```

Your folder structure should look like this:
```
terraform-framework/
├── docs/
├── infra/
│   ├── envs/
│   │   ├── dev/      ← We'll start here!
│   │   ├── staging/
│   │   └── prod/
│   ├── global/
│   └── modules/
└── pipelines/
```

---

## Step 3: Configure Your Environment

### 3.1 Update Backend Configuration

Open `infra/envs/dev/main.tf` and find the backend block:

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

Replace `tfstate[yourname]` with the storage account name from Step 1.

### 3.2 Update Variables

Open `infra/envs/dev/dev.tfvars` and customize:

```hcl
# Change these to your values
organization_name = "contoso"          # Your company/org name
project_name      = "contoso"          # Your project name
location          = "indonesiacentral"    # Azure region (closest to Indonesia)

# Get your tenant ID by running: az account show --query tenantId -o tsv
tenant_id = "12345678-1234-1234-1234-123456789012"  # Your Azure AD tenant

# Optional customizations
cost_center  = "Engineering"
owner_email  = "your-email@company.com"
```

**How to find your tenant ID:**
```powershell
az account show --query tenantId -o tsv
```

### 3.3 Feature Toggles - Choose What to Deploy

This framework uses **feature toggles** to control what gets deployed. This means:
- **Dev** is simple and cheap by default
- **Staging** adds monitoring and basic security
- **Prod** has everything enabled

#### What You Can Enable/Disable

In your `dev.tfvars` file, you'll see these toggles:

```hcl
# -----------------------------------------------------------------------------
# Feature Toggles - What to deploy
# -----------------------------------------------------------------------------
enable_aks            = false  # Kubernetes cluster
enable_container_apps = false  # Serverless containers
enable_webapp         = false  # App Service web hosting
enable_cosmosdb       = false  # NoSQL database
enable_key_vault      = true   # Secrets management (recommended always on)
```

**To enable a feature**, just change `false` to `true`:

```hcl
# Want to deploy AKS? Change this:
enable_aks = true
```

#### Feature Matrix by Environment

| Feature | Dev | Staging | Prod | Why? |
|---------|:---:|:-------:|:----:|------|
| **Compute (pick what you need)** |
| AKS (Kubernetes) | Optional | Optional | Optional | Full container orchestration |
| Container Apps | Optional | Optional | Optional | Simpler serverless containers |
| Web App | Optional | Optional | Optional | Traditional web hosting |
| **Data & Security** |
| Cosmos DB | Optional | Optional | Optional | NoSQL database |
| Key Vault | ✅ On | ✅ On | ✅ On | Always need secrets |
| **Security Features** |
| NAT Gateway | ❌ Off | ❌ Off | ✅ On | Expensive, only prod needs it |
| Private Endpoints | ❌ Off | ❌ Off | ✅ On | No public access in prod |
| DDoS Protection | ❌ Off | ❌ Off | ✅ On | Very expensive, prod only |
| Purge Protection | ❌ Off | ✅ On | ✅ On | Protect secrets |
| **Monitoring** |
| Application Insights | ❌ Off | ✅ On | ✅ On | Performance monitoring |
| Log Retention | 30 days | 60 days | 90 days | Compliance needs |
| **Scaling** |
| Auto-scaling | ❌ Off | ❌ Off | ✅ On | Only prod needs it |
| Geo-redundancy | ❌ Off | ❌ Off | ✅ On | Multi-region backup |

#### Monthly Cost Estimates

| Environment | Cost | What You Get |
|-------------|------|--------------|
| **Dev** | $100-300 | Basics only, public access OK |
| **Staging** | $300-800 | + Monitoring, some security |
| **Prod** | $2,000-8,000+ | Everything, fully secured |

#### Example: Enable AKS for Development

1. Open `infra/envs/dev/dev.tfvars`
2. Find `enable_aks` and change to `true`:
   ```hcl
   enable_aks = true
   ```
3. Run:
   ```powershell
   terraform plan -var-file=dev.tfvars
   terraform apply -var-file=dev.tfvars
   ```

That's it! AKS will be created with dev-appropriate settings (1 small node, no auto-scaling).

---

## Step 4: Initialize Terraform

```powershell
# Navigate to dev environment
cd infra/envs/dev

# Initialize Terraform
terraform init
```

**What you should see:**
```
Initializing the backend...

Successfully configured the backend "azurerm"!

Initializing provider plugins...
- Finding hashicorp/azurerm versions matching "~> 3.80.0"...
- Installing hashicorp/azurerm v3.80.0...

Terraform has been successfully initialized!
```

**Common errors and fixes:**

| Error | Cause | Fix |
|-------|-------|-----|
| "Error configuring the backend" | Wrong storage account name | Check Step 1 output |
| "Access denied" | Not logged in to Azure | Run `az login` |
| "Provider not found" | Network issue | Check internet connection |

---

## Step 5: Review the Plan

Before creating anything, let's see what Terraform WILL create:

```powershell
terraform plan -var-file=dev.tfvars
```

**What you should see:**
```
Terraform will perform the following actions:

  # azurerm_resource_group.dev will be created
  + resource "azurerm_resource_group" "dev" {
      + name     = "contoso-rg-dev"
      + location = "indonesiacentral"
    }

  # azurerm_virtual_network.vnet will be created
  + resource "azurerm_virtual_network" "vnet" {
      + name          = "contoso-vnet-dev"
      + address_space = ["10.1.0.0/16"]
    }

  # ... more resources ...

Plan: 8 to add, 0 to change, 0 to destroy.
```

**What this means:**
- `+` = Will be created (green)
- `~` = Will be modified (yellow)
- `-` = Will be destroyed (red)

**Review the plan!** Make sure:
- Resource names look correct
- Location is what you expect
- No unexpected deletions

---

## Step 6: Apply the Configuration

Ready? Let's create the infrastructure!

```powershell
terraform apply -var-file=dev.tfvars
```

Terraform will show the plan again and ask:
```
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes
```

Type `yes` and press Enter.

**What happens next:**
```
azurerm_resource_group.dev: Creating...
azurerm_resource_group.dev: Creation complete after 2s [id=/subscriptions/.../resourceGroups/myproject-rg-dev]
azurerm_virtual_network.vnet: Creating...
azurerm_virtual_network.vnet: Creation complete after 5s [id=/subscriptions/.../virtualNetworks/myproject-vnet-dev]
...

Apply complete! Resources: 8 added, 0 changed, 0 destroyed.

Outputs:

resource_group_name = "myproject-rg-dev"
vnet_id = "/subscriptions/.../virtualNetworks/myproject-vnet-dev"
```

🎉 **Congratulations! You've deployed your first infrastructure!**

---

## Step 7: Verify in Azure Portal

1. Go to [Azure Portal](https://portal.azure.com)
2. Search for "Resource groups"
3. Find `myproject-rg-dev` (or whatever you named it)
4. Click on it to see your resources:
   - Virtual Network
   - Network Security Groups
   - Log Analytics Workspace

---

## Step 8: Clean Up (Optional)

If you want to delete everything you just created:

```powershell
terraform destroy -var-file=dev.tfvars
```

Type `yes` when prompted.

**Note:** This is permanent! Only do this for testing or when you're done.

---

## What's Next?

Now that you've deployed dev, you can:

### Deploy More Modules

Add AKS, Cosmos DB, or other services by editing `main.tf`:

```hcl
# Add AKS to your environment
module "aks" {
  source = "../../modules/aks"
  
  cluster_name = "contoso-aks-dev"
  location     = var.location
  
  # Use subnet from networking module
  subnet_id = module.networking.subnet_ids["aks-subnet"]
  
  tags = module.global_standards.common_tags
}
```

Then run:
```powershell
terraform plan -var-file=dev.tfvars
terraform apply -var-file=dev.tfvars
```

### Deploy to Staging

```powershell
cd ../staging
terraform init
terraform plan -var-file=staging.tfvars
terraform apply -var-file=staging.tfvars
```

### Set Up CI/CD

See [AZURE-DEVOPS-SETUP.md](AZURE-DEVOPS-SETUP.md) to automate deployments.

---

## Troubleshooting

### "Error: Provider authentication failed"

```powershell
# Re-authenticate
az logout
az login
```

### "Error: Resource group already exists"

Someone already created it. Either:
- Use a different name
- Import it: `terraform import azurerm_resource_group.dev /subscriptions/.../resourceGroups/name`

### "Error: Timeout waiting for resource"

Azure is slow. Try again:
```powershell
terraform apply -var-file=dev.tfvars
```

### "Error: Insufficient permissions"

You need at least "Contributor" role on the subscription:
```powershell
# Check your role
az role assignment list --assignee $(az ad signed-in-user show --query id -o tsv)
```

### State Lock Error

Someone else is running Terraform. Wait or force unlock:
```powershell
terraform force-unlock LOCK_ID
```

---

## Common Commands Reference

| Command | What it does |
|---------|--------------|
| `terraform init` | Download providers, set up backend |
| `terraform plan` | Show what would change |
| `terraform apply` | Create/update resources |
| `terraform destroy` | Delete all resources |
| `terraform output` | Show output values |
| `terraform state list` | List managed resources |
| `terraform fmt` | Format code nicely |
| `terraform validate` | Check for errors |

---

## Need Help?

1. **Read the error message** - Terraform error messages are usually helpful
2. **Check the docs** - See other files in `/docs/`
3. **Ask the team** - We're all learning together!

---

## Summary

You've learned how to:
- ✅ Set up Terraform backend for state storage
- ✅ Configure environment variables
- ✅ Initialize Terraform
- ✅ Review changes with `terraform plan`
- ✅ Deploy with `terraform apply`
- ✅ Verify resources in Azure Portal
- ✅ Clean up with `terraform destroy`

**You're now ready to manage infrastructure as code! 🚀**
