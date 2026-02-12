# Document 01: Framework Overview

## The Problem We Are Solving

### Current Situation (Before This Framework)

Imagine you have 5 teams in your company. Each team manages their infrastructure using Terraform:

```
Team A: Uses their own style, their own folder structure
Team B: Completely different style, different naming
Team C: Copy-pasted from Stack Overflow, no standards
Team D: Uses Terraform but no one knows how it works
Team E: Just started, has no idea where to begin
```

**What goes wrong?**

| Problem | Impact |
|---------|--------|
| Different naming conventions | Cannot find resources in Azure portal |
| No shared modules | Every team writes the same code from scratch |
| No standard tags | Cannot track costs per team or project |
| No CI/CD pipeline | Teams deploy manually, prone to human error |
| No security scanning | Vulnerabilities deployed to production |
| No approval process | Anyone can make changes to production |
| No state management strategy | Teams overwrite each other's infrastructure |

### The Solution: Enterprise Terraform Framework

This framework gives **all teams** a single, consistent way to:

1. **Name resources** → Everyone follows the same pattern
2. **Reuse modules** → Don't reinvent the wheel for AKS, databases, etc.
3. **Separate environments** → Dev, Staging, Prod are isolated
4. **Deploy safely** → CI/CD pipeline with approvals
5. **Stay secure** → Security scanning built into the pipeline
6. **Work together** → Multiple teams, same structure, no conflicts

---

## What Is This Framework?

Think of this framework as a **"Terraform Starter Kit"** for your entire organization.

### Analogy: Building a House

| Concept | House Analogy | Terraform Framework |
|---------|---------------|---------------------|
| **Global Standards** | Building codes (all houses must follow) | `infra/global/` - naming, tagging rules |
| **Modules** | Pre-built components (door, window, wall) | `infra/modules/` - AKS, CosmosDB, etc. |
| **Environments** | Different houses (small cottage, big mansion) | `infra/envs/` - dev, staging, prod |
| **Pipelines** | Construction inspectors | `pipelines/` - CI/CD with checks |
| **Scripts** | Construction tools | `scripts/` - helper utilities |

---

## Framework Structure Explained

```
terraform-infrastructure/
│
├── infra/                          ← All infrastructure code lives here
│   │
│   ├── global/                     ← LAYER 0: Standards (everyone inherits)
│   │   ├── locals.tf              ← Naming rules: "org-project-resource-env"
│   │   ├── versions.tf            ← Terraform version: ">= 1.5.0"
│   │   ├── providers.tf           ← Azure provider documentation
│   │   └── outputs.tf             ← Exports standards for other modules
│   │
│   ├── modules/                    ← BUILDING BLOCKS (reusable by all teams)
│   │   ├── _shared/               ← Shared naming conventions
│   │   ├── aks/                   ← Azure Kubernetes Service module
│   │   ├── container-app/         ← Azure Container Apps module
│   │   ├── cosmosdb/              ← Azure Cosmos DB module
│   │   ├── networking/            ← Virtual Network module
│   │   ├── postgresql/            ← PostgreSQL module
│   │   ├── security/              ← Key Vault module
│   │   ├── sql-database/          ← SQL Database module
│   │   ├── storage/               ← Storage Account module
│   │   ├── webapp/                ← App Service module
│   │   └── landing-zone/          ← Foundation (VNet + Logs + NSGs)
│   │
│   └── envs/                       ← PATTERN 1: Centralized Environments
│       ├── dev/                    ← Development (cheap, simple)
│       ├── staging/                ← Staging (production-like)
│       └── prod/                   ← Production (full security)
│
├── examples/                       ← PATTERN 2: Delegated Per-Team
│   ├── pattern-2-delegated/
│   │   ├── dev-app-crm/           ← CRM team's own infrastructure
│   │   └── dev-app-ecommerce/     ← E-commerce team's own infrastructure
│   ├── aks-application/           ← Example: Complete AKS deployment
│   └── enterprise-hub-spoke/      ← Example: Hub-spoke architecture
│
├── pipelines/                      ← Azure DevOps CI/CD
│   ├── ci-terraform-plan.yml      ← Runs on Pull Request (plan only)
│   ├── cd-terraform-apply.yml     ← Runs on merge (apply with approval)
│   └── templates/                 ← Reusable pipeline templates
│
├── scripts/                        ← Helper scripts
│   ├── init-backend.ps1           ← Setup state storage (Windows)
│   ├── init-backend.sh            ← Setup state storage (Linux/Mac)
│   ├── validate-all.ps1/.sh       ← Validate all Terraform files
│   └── format-all.ps1/.sh         ← Format all Terraform files
│
└── docs/                           ← Documentation (you are here!)
```

---

## Key Concepts for Beginners

### 1. What is Terraform?

Terraform is a tool that lets you **describe your infrastructure in code** (files), and then automatically creates it in Azure.

**Without Terraform:**
```
1. Open Azure Portal
2. Click "Create Resource"
3. Fill in 20 fields manually
4. Repeat for every resource
5. Forget what you configured
6. Can't reproduce it
```

**With Terraform:**
```hcl
# Write this once:
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "myapp-aks-dev"
  location            = "southeastasia"
  resource_group_name = "myapp-rg-dev"
  # ... configuration
}

# Run: terraform apply
# Result: AKS cluster created automatically!
# Bonus: You can recreate it anytime
```

### 2. What is a Module?

A module is a **reusable package** of Terraform code. Instead of writing 100 lines of AKS configuration every time, you write it once in a module and reuse it:

```hcl
# Without module: 100+ lines of AKS code every time
# With module: Just 10 lines!
module "aks" {
  source = "../../modules/aks"
  
  cluster_name        = "myapp-aks-dev"
  location            = "southeastasia"
  resource_group_name = "myapp-rg-dev"
  node_count          = 1
  vm_size             = "Standard_D8ds_v5"
}
```

### 3. What is State?

Terraform keeps a **record of what it created** in a "state file". This is stored in Azure Storage Account so:

- Multiple team members can work together
- Terraform knows what already exists
- Terraform can update or delete resources safely

```
State file: "I created AKS cluster X, CosmosDB Y, VNet Z"
Next time: "AKS X already exists, no changes needed"
```

### 4. What are Environments?

Environments are **separate copies** of your infrastructure for different purposes:

| Environment | Purpose | Cost | Security |
|-------------|---------|------|----------|
| **Dev** | Developers test new features | Low ($100-300/mo) | Minimal |
| **Staging** | Final testing before production | Medium ($300-800/mo) | Moderate |
| **Prod** | Real users, real data | High ($500-2000+/mo) | Maximum |

Each environment:
- Has its own state file (they don't interfere)
- Has its own configuration (dev is cheap, prod is robust)
- Uses the same modules (consistency!)

---

## Feature Toggles: The Secret Weapon

This framework uses **feature toggles** (boolean switches) to control what gets deployed. This means:

- Dev environment: Deploy only what you need (save money)
- Prod environment: Deploy everything with full security

```hcl
# dev.tfvars - Keep it simple
enable_aks            = true    # We need Kubernetes
enable_cosmosdb       = true    # We need database
enable_container_apps = false   # Don't need this yet
enable_nat_gateway    = false   # Not needed for dev
enable_ddos_protection = false  # Too expensive for dev

# prod.tfvars - Full security
enable_aks            = true
enable_cosmosdb       = true
enable_container_apps = true
enable_nat_gateway    = true    # Secure outbound traffic
enable_ddos_protection = true   # Protect against attacks
```

---

## Indonesia Region Considerations

All services in this framework are configured to work in Azure regions available in Indonesia:

| Service | Region | Notes |
|---------|--------|-------|
| AKS | `southeastasia` (Singapore) | Closest region with full AKS support |
| Cosmos DB | `southeastasia` | Full support, use `Local` backup redundancy |
| PostgreSQL | `southeastasia` | Flexible Server supported |
| Container Apps | `southeastasia` | Fully supported |
| Key Vault | `southeastasia` | Fully supported |
| Storage Account | `southeastasia` | Use `LRS` or `ZRS` redundancy |
| App Service | `southeastasia` | Fully supported |

> **Note**: `indonesiacentral` (Jakarta) is available but has limited services. For a production framework, `southeastasia` (Singapore) provides the most complete service availability while still being close to Indonesia.

---

## What Happens Next?

Now that you understand the framework:

1. **Read [Document 02](02-TERRAFORM-BASICS.md)** to understand what each file does
2. **Read [Document 03](03-HOW-FILES-CONNECT.md)** to see how files connect
3. **Read [Document 04](04-PATTERN1-VS-PATTERN2.md)** to understand deployment patterns
4. **Follow [Document 05](05-DEMO-SCENARIO-STEP-BY-STEP.md)** for the live demo

---

*Next: [02 - Terraform Basics for Beginners →](02-TERRAFORM-BASICS.md)*
