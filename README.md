# Enterprise Terraform Framework for Azure

## 🎯 Overview

This is a **production-ready, enterprise-grade Terraform framework** for Azure that provides:

- ✅ **Standardized structure** for all teams
- ✅ **Reusable modules** for common Azure services
- ✅ **Environment separation** (dev/staging/prod)
- ✅ **CI/CD integration** with Azure DevOps
- ✅ **Security-first approach** with OIDC authentication
- ✅ **DevSecOps pipeline** with secret scanning, IaC security, and cost estimation
- ✅ **Governance and compliance** built-in
- ✅ **Hardened state storage** with GRS, versioning, soft delete, and firewall
- ✅ **Complete documentation** for technical and non-technical audiences

## 📁 Repository Structure

```
terraform-infrastructure/
├── infra/                          # Infrastructure as Code
│   ├── global/                     # Global standards (versions, naming, tags)
│   │   ├── versions.tf            # Terraform version requirements
│   │   ├── providers.tf           # Provider configuration (OIDC)
│   │   └── locals.tf              # Naming and tagging standards
│   ├── platform/                   # Platform layer (VNets, Security, Monitoring)
│   │   ├── dev/                   # Platform infra for dev
│   │   ├── staging/               # Platform infra for staging
│   │   └── prod/                  # Platform infra for prod
│   ├── envs/                      # Application layer (AKS, CosmosDB, etc.)
│   │   ├── dev/                   # Development apps
│   │   ├── staging/               # Staging apps
│   │   └── prod/                  # Production apps
│   └── modules/                   # Reusable Terraform modules
│       ├── _shared/               # Shared naming conventions
│       ├── aks/                   # Azure Kubernetes Service
│       ├── container-app/         # Azure Container Apps
│       ├── cosmosdb/              # Azure Cosmos DB
│       ├── landing-zone/          # Landing Zone foundation
│       ├── networking/            # Virtual Networks & Subnets
│       ├── postgresql/            # PostgreSQL Flexible Server
│       ├── security/              # Azure Key Vault
│       ├── sql-database/          # Azure SQL Database
│       ├── storage/               # Azure Storage Account
│       └── webapp/                # Azure App Service
├── pipelines/                     # Azure DevOps CI/CD pipelines
│   ├── ci-terraform-plan.yml     # CI: Plan on Pull Request
│   ├── cd-terraform-apply.yml    # CD: Apply with approvals
│   └── templates/                # Reusable pipeline templates
├── scripts/                       # Helper scripts
├── docs/                          # Documentation
│   ├── AZURE-DEVOPS-SETUP.md     # ⭐ Complete setup guide
│   ├── technical/                 # Technical documentation
│   └── executive/                 # Management documentation
├── examples/                      # Working examples
│   ├── aks-application/          # Complete AKS deployment
│   ├── enterprise-hub-spoke/     # Enterprise hub-spoke architecture
│   └── pattern-2-delegated/      # Multi-team delegation (Pattern 2)
└── README.md                      # This file
```

## 🚀 Quick Start

### For Beginners - Complete Setup

📖 **[Azure DevOps Setup Guide](docs/AZURE-DEVOPS-SETUP.md)** ⭐ **Start Here!**

This comprehensive guide covers:
- ✅ Azure DevOps organization setup
- ✅ OIDC configuration (no secrets!)
- ✅ Service connections
- ✅ Environment setup with approval gates
- ✅ Pipeline creation
- ✅ First deployment walkthrough

### For Experienced Users

```bash
# 1. Clone and setup backend
git clone <your-repo-url>
cd terraform-infrastructure
./scripts/init-backend.sh  # or .ps1 for Windows

# 2. Configure environment
cd infra/envs/dev
# Edit dev.tfvars with your values

# 3. Test locally
terraform init
terraform plan -var-file="dev.tfvars"

# 4. Push to Azure DevOps
git checkout -b feature/my-infrastructure
git add .
git commit -m "Add infrastructure"
git push origin feature/my-infrastructure
# Create PR → CI pipeline runs automatically
```

## 🔄 CI/CD Workflow

```
Developer → Create PR → CI: Terraform Plan
                              ↓
                         Review Plan
                              ↓
                         Merge to Main
                              ↓
                    CD: Terraform Apply (Manual Trigger)
                              ↓
                      Approval Gate ⛔
                              ↓
                      Deploy to Azure ✅
```

**Key Features:**
- 🔒 No deployment without approval
- 👁️ Terraform plan visible in PR
- 🔐 OIDC authentication (no secrets)
- 📝 Audit trail for all changes

## 📚 Documentation

### 🌟 Start Here (For Beginners)
1. **[Getting Started Guide](docs/GETTING-STARTED.md)** ⭐ Step-by-step deployment
2. **[How Everything Connects](docs/HOW-EVERYTHING-CONNECTS.md)** - Big picture overview
3. **[Why These Choices](docs/WHY-THESE-CHOICES.md)** - Understanding our decisions

### 📘 Technical Documentation
- **[Azure DevOps Setup Guide](docs/AZURE-DEVOPS-SETUP.md)** - CI/CD pipeline setup
- **[Architecture Quick Reference](docs/ARCHITECTURE-QUICK-REFERENCE.md)** - Technical architecture details
- **[Technical Documentation](docs/technical/README.md)** - Module details and usage
- **[DevSecOps Plan](docs/AZURE-DEVSECOPS-IMPLEMENTATION-PLAN.md)** - Security in CI/CD

### 🏗️ Module Documentation (How It Works)
Each module has its own "How It Works" guide:
- **[AKS (Kubernetes)](infra/modules/aks/HOW-IT-WORKS.md)** - Containers, pods, networking
- **[Container Apps](infra/modules/container-app/HOW-IT-WORKS.md)** - Serverless containers
- **[Cosmos DB](infra/modules/cosmosdb/HOW-IT-WORKS.md)** - NoSQL database, partitions
- **[Landing Zone](infra/modules/landing-zone/HOW-IT-WORKS.md)** - Shared foundation infrastructure
- **[Networking](infra/modules/networking/HOW-IT-WORKS.md)** - VNets, subnets, NSGs
- **[PostgreSQL](infra/modules/postgresql/HOW-IT-WORKS.md)** - Relational database (open source)
- **[Security](infra/modules/security/HOW-IT-WORKS.md)** - Key Vault, secrets
- **[SQL Database](infra/modules/sql-database/HOW-IT-WORKS.md)** - Azure SQL, relational data
- **[Storage](infra/modules/storage/HOW-IT-WORKS.md)** - Blob, file, and queue storage
- **[Web App](infra/modules/webapp/HOW-IT-WORKS.md)** - App Service, slots

### 📊 Executive Summary
- **[Executive Summary](docs/executive/README.md)** - Business value and governance

### Examples
- **[AKS Application](examples/aks-application/README.md)** - Full Kubernetes deployment
- **[Enterprise Hub-Spoke](examples/enterprise-hub-spoke/README.md)** - Multi-subscription architecture
- **[Pattern 2: Delegated](examples/pattern-2-delegated/README.md)** - Multi-team deployment

## 💰 Cost Estimates

| Environment | Monthly Cost | Use Case |
|-------------|-------------|----------|
| Development | $100-300 | Dev/testing |
| Staging | $800-1,500 | UAT, performance testing |
| Production | $3,000-8,000 | Live workloads, HA |

## 🛡️ DevSecOps Pipeline

The CI pipeline automatically runs **5 stages** on every Pull Request:

| Stage | Tool | Purpose |
|-------|------|-------|
| 1. Secret Scan | GitLeaks | Detects leaked credentials in code |
| 2. Validate | Terraform | Format check + configuration validation |
| 3. Plan | Terraform | Preview infrastructure changes |
| 4. Security Scan | Checkov | IaC security and compliance scanning |
| 5. Cost Estimate | Infracost | Monthly cost impact of changes |

The CD pipeline adds **real post-deployment validation** — verifying that deployed resources (RG, VNet, Key Vault, AKS) actually exist in Azure.

## 🆘 Support

- 📖 Documentation: Start with [Azure DevOps Setup Guide](docs/AZURE-DEVOPS-SETUP.md)
- 🐛 Issues: Create ticket in Azure DevOps
- 📧 Email: devops@yourcompany.com
