# CRM Application Infrastructure

This folder contains Terraform configuration for the CRM application in dev environment.

**Team:** CRM Team  
**Tech Lead:** bob.smith@company.com  
**Application:** Customer relationship management system

---

## 🏗️ Infrastructure Components

- **App Service**: Web application hosting
- **Cosmos DB**: Customer data storage
- **Key Vault**: Secrets management
- **Managed Identity**: For secure authentication

---

## 📋 Prerequisites

Ensure platform team has deployed:
- ✅ Global standards (`infra/global/`)
- ✅ Landing zone with networking (`infra/envs/dev/`)

Verify:
```bash
az network vnet show --resource-group rg-contoso-dev-network-001 --name vnet-contoso-dev-001
```

---

## 🚀 Deployment

```bash
# Initialize
terraform init

# Plan
terraform plan -var-file="dev.tfvars"

# Apply
terraform apply -var-file="dev.tfvars"
```

---

## 📦 Outputs

After deployment, you'll get:
- App Service URL
- Cosmos DB endpoint
- Key Vault name
- Managed identity client ID

Use these to configure your application!
