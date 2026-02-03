# E-Commerce Application Infrastructure

This folder contains Terraform configuration for the e-commerce application in dev environment.

**Team:** E-commerce Team  
**Tech Lead:** jane.doe@company.com  
**Application:** Product catalog and shopping cart API

---

## 🏗️ Infrastructure Components

- **AKS Cluster**: Shared cluster, dedicated namespace `ecommerce`
- **Cosmos DB**: NoSQL database for products, orders, inventory
- **Key Vault**: Secrets management
- **Managed Identity**: For secure authentication

---

## 📋 Prerequisites

Ensure platform team has deployed:
- ✅ Global standards (`dev-shared/1-global`)
- ✅ Landing zone (`dev-shared/2-landing-zone`)

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
