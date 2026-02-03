# Pattern 2: Delegated Infrastructure (App Teams Manage Their Own)

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
# Global standards
cd environments/dev-shared/1-global
terraform init
terraform apply -var-file="dev.tfvars"

# Landing zone
cd ../2-landing-zone
terraform init
terraform apply -var-file="dev.tfvars"
```

### For App Teams

Each team manages their own workload:

```bash
# E-commerce team
cd environments/dev-app-ecommerce/3-workloads
terraform init
terraform apply -var-file="dev.tfvars"

# CRM team (separate state)
cd environments/dev-app-crm/3-workloads
terraform init
terraform apply -var-file="dev.tfvars"
```

## 📚 See Also

- [dev-app-ecommerce/](dev-app-ecommerce/) - Example e-commerce app infrastructure
- [dev-app-crm/](dev-app-crm/) - Example CRM app infrastructure
- [TEAM-COLLABORATION.md](../../docs/TEAM-COLLABORATION.md) - Detailed team workflows
