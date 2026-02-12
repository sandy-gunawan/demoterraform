# Document 02: Terraform Basics for Beginners

## How Terraform Works - The Simple Version

```
You write .tf files  →  Terraform reads them  →  Azure creates resources
     (code)              (the tool)                (the result)
```

### The 4 Commands You Need to Know

| Command | What It Does | When You Use It |
|---------|-------------|-----------------|
| `terraform init` | Downloads required plugins and sets up state storage | First time only (or when you add new modules) |
| `terraform plan` | Shows what will be created/changed/destroyed (preview) | Every time before apply |
| `terraform apply` | Actually creates/changes/destroys resources in Azure | When you're happy with the plan |
| `terraform destroy` | Removes all resources managed by this Terraform | When you want to clean up |

### The Lifecycle

```
terraform init    →  "I'm downloading Azure provider plugin and connecting to state storage"
        ↓
terraform plan    →  "Here's what I will create: 1 resource group, 1 AKS cluster, 1 CosmosDB"
        ↓
terraform apply   →  "Creating... Done! All 3 resources created successfully"
        ↓
(Later, if needed)
terraform destroy →  "Removing... Done! All 3 resources destroyed"
```

---

## What Each File Type Does

In Terraform, you'll see these file types over and over. Here's what each one does:

### `main.tf` - The Main Configuration

**What it is**: The primary file where you define WHAT resources to create.

**Analogy**: The architectural blueprint of your house.

```hcl
# main.tf - This is where you say "I want these things created"

# "I want a resource group"
resource "azurerm_resource_group" "main" {
  name     = "myapp-rg-dev"
  location = "southeastasia"
}

# "I want an AKS cluster" (using the module)
module "aks" {
  source = "../../modules/aks"
  
  cluster_name = "myapp-aks-dev"
  location     = "southeastasia"
  # ... more configuration
}
```

### `variables.tf` - Input Definitions

**What it is**: Declares what inputs (parameters) are accepted. Like function parameters in programming.

**Analogy**: The form you fill out when ordering a house - "How many bedrooms? What color?"

```hcl
# variables.tf - "These are the questions I need answered"

variable "project_name" {
  description = "Name of the project"    # What this variable is for
  type        = string                    # Must be text (not a number)
  default     = "myapp"                   # If no one specifies, use this
}

variable "enable_aks" {
  description = "Deploy AKS cluster?"
  type        = bool                      # Must be true or false
  default     = false                     # Default: don't deploy AKS
}

variable "aks_node_count" {
  description = "Number of AKS nodes"
  type        = number                    # Must be a number
  default     = 1
}
```

### `terraform.tfvars` or `dev.tfvars` - Actual Values

**What it is**: The file where you provide actual values for the variables.

**Analogy**: The filled-out order form - "3 bedrooms, blue color"

```hcl
# dev.tfvars - "Here are my answers for development environment"

project_name      = "myapp"
location          = "southeastasia"
enable_aks        = true       # Yes, I want AKS
enable_cosmosdb   = true       # Yes, I want database
aks_node_count    = 1          # Just 1 node for dev
```

### `outputs.tf` - What to Show After Creating

**What it is**: Defines what information to display after Terraform creates resources.

**Analogy**: The receipt you get after the house is built - "Here's your address, here's your key"

```hcl
# outputs.tf - "After creating, tell me these things"

output "resource_group_name" {
  description = "The name of the resource group we created"
  value       = azurerm_resource_group.main.name
}

output "aks_cluster_name" {
  description = "The AKS cluster name (needed for kubectl)"
  value       = module.aks[0].cluster_name
}
```

### `backend.tf` - Where to Store State

**What it is**: Tells Terraform where to save its state file (record of what it created).

**Analogy**: The filing cabinet where you keep the house documents.

```hcl
# backend.tf - "Save my records in this Azure Storage Account"

terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstatemycompany"
    container_name       = "tfstate"
    key                  = "dev.terraform.tfstate"  # Unique name per environment!
  }
}
```

### `locals.tf` - Internal Calculations

**What it is**: Variables that are computed internally (not from user input).

**Analogy**: The builder's internal calculations - "If 3 bedrooms, then I need X square meters"

```hcl
# locals.tf - "Let me calculate some things internally"

locals {
  # Build a resource name from inputs
  resource_prefix = "${var.organization}-${var.project}-${var.environment}"
  
  # Standard tags every resource should have
  common_tags = {
    ManagedBy   = "Terraform"
    Environment = var.environment
    Project     = var.project_name
  }
}
```

---

## How the Data Flows Between Files

This is the most important thing to understand. Here's how data flows:

```
┌─────────────────────────────────────────────────────────┐
│                    DATA FLOW                             │
│                                                          │
│  dev.tfvars          variables.tf         main.tf        │
│  ┌──────────┐       ┌──────────┐       ┌──────────┐     │
│  │ Values   │──────▶│ Declares │──────▶│ Uses     │     │
│  │          │       │ variables │       │ variables│     │
│  │project=  │       │          │       │ to create│     │
│  │ "myapp"  │       │variable  │       │ resources│     │
│  │          │       │"project" │       │          │     │
│  │enable_aks│       │{         │       │module    │     │
│  │ = true   │       │  type=   │       │ "aks" {  │     │
│  │          │       │  string  │       │  ...     │     │
│  │          │       │}         │       │ }        │     │
│  └──────────┘       └──────────┘       └──────────┘     │
│                                              │           │
│                                              ▼           │
│                                        outputs.tf        │
│                                       ┌──────────┐      │
│                                       │ Shows    │      │
│                                       │ results  │      │
│                                       │          │      │
│                                       │ "AKS     │      │
│                                       │  created │      │
│                                       │  name=X" │      │
│                                       └──────────┘      │
└─────────────────────────────────────────────────────────┘
```

### Step by Step:

1. **You edit `dev.tfvars`**: "I want AKS enabled, project name is myapp"
2. **`variables.tf` validates**: "OK, `enable_aks` must be bool ✓, `project_name` must be string ✓"
3. **`main.tf` uses the values**: "OK, `enable_aks` is true, so I'll create an AKS module"
4. **`main.tf` calls a module**: "I'm calling `modules/aks/` with these parameters"
5. **The module creates resources**: "Creating AKS cluster in Azure..."
6. **`outputs.tf` shows results**: "Done! Here's the cluster name: myapp-aks-dev"

---

## Understanding `module` Blocks

A module call in Terraform is like **calling a function** in programming:

```hcl
# This is like calling a function:
# result = createAKS(name="myapp-aks-dev", nodeCount=1, location="sea")

module "aks" {
  source = "../../modules/aks"        # Where the function code lives
  
  # Parameters (inputs) to the function:
  cluster_name = "myapp-aks-dev"
  node_count   = 1
  location     = "southeastasia"
}

# Access the results (return values):
# module.aks.cluster_name
# module.aks.cluster_id
```

### How `source` Works

The `source` tells Terraform WHERE to find the module code:

```
infra/
├── envs/
│   └── dev/
│       └── main.tf          ← You are here
│                                source = "../../modules/aks"
│                                         ↑ Go up 2 folders, then into modules/aks
│
└── modules/
    └── aks/
        ├── main.tf           ← The actual AKS creation code
        ├── variables.tf      ← What inputs the module accepts
        └── outputs.tf        ← What the module returns
```

Path explanation:
```
From: infra/envs/dev/main.tf
  ../../           → Go up to infra/envs/ then to infra/
  modules/aks      → Go into modules/aks/

Result: infra/modules/aks/
```

---

## Understanding `count` and Feature Toggles

The `count` parameter controls whether a resource is created or not:

```hcl
# If enable_aks is true:  count = 1 → Create 1 AKS cluster
# If enable_aks is false: count = 0 → Create 0 AKS clusters (skip it!)

module "aks" {
  count  = var.enable_aks ? 1 : 0        # ← This is the toggle!
  source = "../../modules/aks"
  # ...
}
```

This is how **the same `main.tf`** can create different resources in different environments:

```
Dev:     enable_aks=true,  enable_cosmosdb=true   → AKS + CosmosDB
Staging: enable_aks=true,  enable_cosmosdb=true,  enable_container_apps=true → AKS + CosmosDB + ContainerApps
Prod:    Everything=true                           → All services
```

---

## Understanding `data` Sources

`data` blocks **read existing resources** (they don't create anything):

```hcl
# "I know a VNet already exists. Let me get its details."
data "azurerm_virtual_network" "landing_zone" {
  name                = "vnet-contoso-dev-001"
  resource_group_name = "rg-contoso-dev-network-001"
}

# Now I can use it:
# data.azurerm_virtual_network.landing_zone.id
# data.azurerm_virtual_network.landing_zone.address_space
```

**Why is this important?**
- Pattern 2 (delegated) uses `data` to reference shared infrastructure
- App teams don't create the VNet; they just reference it

---

## Understanding Terraform State

### What is State?

State is Terraform's **memory**. It's a JSON file that records:
- What resources were created
- Their IDs in Azure
- Their current configuration

### Why Remote State?

```
❌ Local State (state file on your laptop):
   - Only you can run Terraform
   - If laptop dies, state is lost
   - Team member might accidentally overwrite

✅ Remote State (state file in Azure Storage):
   - Any team member can run Terraform
   - State is backed up automatically
   - State locking prevents conflicts
```

### State Locking

When someone runs `terraform apply`, Terraform **locks** the state file. This prevents two people from modifying infrastructure at the same time:

```
Person A: terraform apply → Lock acquired ✓ → Making changes...
Person B: terraform apply → ✗ Error: State is locked by Person A!
Person A: → Changes complete → Lock released ✓
Person B: terraform apply → Lock acquired ✓ → Now I can make changes
```

### Separate State Per Environment

Each environment has its own state file:

```
Azure Storage Account: tfstatemycompany
└── Container: tfstate
    ├── dev.terraform.tfstate          ← Dev environment state
    ├── staging.terraform.tfstate      ← Staging environment state
    ├── prod.terraform.tfstate         ← Production environment state
    ├── dev-app-crm.tfstate            ← CRM team's state (Pattern 2)
    └── dev-app-ecommerce.tfstate      ← E-commerce team's state (Pattern 2)
```

**Why separate?** So that:
- Destroying dev doesn't affect prod
- CRM team's changes don't affect e-commerce team
- Each team can work independently

---

## Summary: File Cheat Sheet

| File | Purpose | Who Edits It | How Often |
|------|---------|-------------|-----------|
| `main.tf` | Define what resources to create | DevOps/Platform team | When adding new services |
| `variables.tf` | Declare input parameters | DevOps/Platform team | When adding new toggles |
| `dev.tfvars` | Set values for dev environment | Any authorized developer | Frequently |
| `outputs.tf` | Define what to show after creation | DevOps/Platform team | When adding new outputs |
| `backend.tf` | Configure state storage | DevOps/Platform team (once) | Rarely |
| `locals.tf` | Internal computed values | DevOps/Platform team | Rarely |
| `versions.tf` | Terraform version requirements | DevOps/Platform team | On upgrades only |
| `providers.tf` | Azure provider configuration | DevOps/Platform team | Rarely |

---

*Previous: [01 - Framework Overview](01-FRAMEWORK-OVERVIEW.md)* | *Next: [03 - How Files Connect →](03-HOW-FILES-CONNECT.md)*
