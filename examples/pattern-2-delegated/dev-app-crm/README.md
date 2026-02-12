# CRM Application Infrastructure

This folder contains Terraform configuration for the CRM application in dev environment.

**Team:** CRM Team  
**Tech Lead:** bob.smith@company.com  
**Application:** Customer relationship management system

---

## 🏗️ Infrastructure Components

**Networking (CRM's Own):**
- **VNet**: 10.2.0.0/16 (isolated from other apps)
- **Subnets**: app-subnet, db-subnet
- **NSGs**: Security rules for app tier

**Application Resources:**
- **App Service**: Web application hosting
- **Cosmos DB**: Customer data storage
- **Key Vault**: Secrets management
- **Managed Identity**: For secure authentication

---

## 📋 Prerequisites

**Platform team must deploy Pattern 1 FIRST!** CRM reads its VNet from Platform.

Required:
- ✅ Azure subscription access
- ✅ Terraform >= 1.5.0
- ✅ Azure CLI logged in (`az login`)
- ✅ Backend storage account (`stcontosotfstate001` in `contoso-tfstate-rg`)
- ✅ Pattern 1 deployed (creates VNet `vnet-contoso-dev-crm-001`)

Check your access:
```bash
# Verify Azure login
az account show

# Verify subscription
az account list --output table
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
