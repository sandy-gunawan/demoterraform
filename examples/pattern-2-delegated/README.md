# Pattern 2: Delegated Infrastructure (App Teams Manage Their Own)

## 🎓 **IMPORTANT: How Pattern 2 Works (Read This First!)**

### **You DON'T create your own VNet!**

❌ **WRONG ASSUMPTION:** "Pattern 2 means I create ALL my own infrastructure"
✅ **CORRECT:** "Platform creates networking, I create apps and read their VNet"

### **The Architecture Explained**

```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ Step 1: Platform Team deploys Pattern 1                  ┃
┃ File: infra/envs/dev/main.tf                            ┃
┃                                                          ┃
┃ Creates 3 VNets:                                         ┃
┃ ├── VNet 10.1.0.0/16 (Pattern 1 shared services)        ┃
┃ ├── VNet 10.2.0.0/16 (CRM app) 👈 For YOU!               ┃
┃ └── VNet 10.3.0.0/16 (E-commerce app) 👈 For them!      ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
                            │
                            │ Platform creates networking
                            │ with governance & standards
                            ↓
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ Step 2: Your Team deploys Pattern 2 (CRM)               ┃
┃ File: examples/pattern-2-delegated/dev-app-crm/main.tf  ┃
┃                                                          ┃
┃ Reads VNet (data source):                               ┃
┃ ├── data "azurerm_virtual_network" "crm" 👈 READ only!  ┃
┃ └── data "azurerm_subnet" "crm_app" 👈 READ only!      ┃
┃                                                          ┃
┃ Creates apps:                                            ┃
┃ ├── resource "azurerm_app_service" "crm" 👈 YOU create ┃
┃ ├── resource "azurerm_cosmosdb_account" "crm"           ┃
┃ └── resource "azurerm_key_vault" "crm"                  ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```

### **Why This Design?**

| Aspect | Explanation |
|--------|-------------|
| **Governance** | Platform enforces security rules, IP ranges, naming standards |
| **Reusability** | Same networking module used 3 times (no code duplication) |
| **Team Focus** | You focus on apps, not networking boilerplate |
| **Separation** | Separate state files = you manage apps independently |
| **Isolation** | Each app gets dedicated VNet (security boundary) |

### **Quick Summary**

- **Platform team** uses: `infra/envs/dev/main.tf` (creates ALL VNets)
- **Your team (CRM)** uses: `examples/.../dev-app-crm/main.tf` (reads VNet, creates apps)
- **E-commerce team** uses: `examples/.../dev-app-ecommerce/main.tf` (reads VNet, creates apps)

---

This folder contains examples of how to organize Terraform when each app team manages their own infrastructure.

## 📁 Folder Structure

```
environments/
├── dev-shared/              ← Platform team owns
│   ├── 1-global/
│   └── 2-landing-zone/
├── dev-app-ecommerce/       ← E-commerce team owns
│   └── 3-workloads/
├── dev-app-crm/             ← CRM team owns
│   └── 3-workloads/
├── staging-shared/          ← Platform team owns
│   ├── 1-global/
│   └── 2-landing-zone/
├── staging-app-ecommerce/   ← E-commerce team owns
│   └── 3-workloads/
└── prod-shared/             ← Platform team owns
    ├── 1-global/
    └── 2-landing-zone/
```

## 🎯 Key Principles

1. **Shared Foundation**: Platform team maintains global + landing zone
2. **Isolated Workloads**: Each app has separate state file
3. **Same Modules**: All teams use modules from `_shared/`
4. **Clear Ownership**: Each team responsible for their folder

## 🚀 Quick Start

### For Platform Team

Create shared foundation once:

```bash
# Global standards (Layer 0)
cd infra/global
terraform init
terraform apply

# Landing Zone (Layer 1 - networking foundation)
cd ../envs/dev
terraform init
terraform apply -var-file="dev.tfvars"
```

### For App Teams

Each team manages their own workload:

```bash
# E-commerce team (using example as reference)
cd examples/pattern-2-delegated/dev-app-ecommerce
terraform init
terraform apply -var-file="dev.tfvars"

# CRM team (separate state, separate example)
cd examples/pattern-2-delegated/dev-app-crm
terraform init
terraform apply -var-file="dev.tfvars"

# Note: In practice, you'd copy these examples to your own location
```

## 📚 See Also

- [dev-app-ecommerce/](dev-app-ecommerce/) - Example e-commerce app infrastructure
- [dev-app-crm/](dev-app-crm/) - Example CRM app infrastructure
- [TEAM-COLLABORATION.md](../../docs/TEAM-COLLABORATION.md) - Detailed team workflows
