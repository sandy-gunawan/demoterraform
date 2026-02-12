# E-Commerce Application Infrastructure

This folder contains Terraform configuration for the e-commerce application in dev environment.

**Team:** E-commerce Team  
**Tech Lead:** jane.doe@company.com  
**Application:** Product catalog and shopping cart API

---

## 🏗️ Infrastructure Components

**Networking (E-commerce's Own):**
- **VNet**: 10.3.0.0/16 (isolated from other apps)
- **Subnets**: aks-subnet, db-subnet
- **NSGs**: Security rules for AKS and database tiers

**Application Resources:**
- **AKS Cluster**: Dedicated Kubernetes cluster for e-commerce
- **Cosmos DB**: NoSQL database for products, orders, inventory
- **Key Vault**: Secrets management
- **Managed Identity**: For secure authentication

---

## 📋 Prerequisites

**Platform team must deploy Pattern 1 FIRST!** E-commerce reads its VNet from Platform.

Required:
- ✅ Azure subscription access
- ✅ Terraform >= 1.5.0
- ✅ Azure CLI logged in (`az login`)
- ✅ Backend storage account (`stcontosotfstate001` in `contoso-tfstate-rg`)
- ✅ Pattern 1 deployed (creates VNet `vnet-contoso-dev-ecommerce-001`)
- ✅ kubectl installed (for AKS access)

Check your access:
```bash
# Verify Azure login
az account show

# Verify subscription
az account list --output table

# Verify kubectl
kubectl version --client
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
- AKS cluster name
- Cosmos DB endpoint
- Key Vault name
- Managed identity client ID

Use these to deploy your application!
