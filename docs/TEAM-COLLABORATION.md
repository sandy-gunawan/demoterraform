# 🤝 Team Collaboration Guide

This guide explains how different teams work together using this Terraform framework.

---

## 🎭 Team Roles

### Platform/Infrastructure Team
**Responsibilities:**
- Maintain global standards (`infra/global/`)
- Manage Landing Zones (Layer 1: Networking in `infra/envs/{env}/main.tf`)
  - VNet, subnets, NSGs, Log Analytics Workspace
- Create and update shared modules (`infra/modules/`)
- Review and approve infrastructure changes
- Monitor costs and compliance

**Skills needed:**
- Terraform expertise
- Azure networking knowledge
- Security best practices
- CI/CD pipeline management

---

### Application Teams
**Responsibilities:**
- Define application requirements
- Deploy applications to provisioned infrastructure
- Monitor application metrics
- Request infrastructure changes (Pattern 1) or deploy directly (Pattern 2)

**Skills needed:**
- Basic Terraform knowledge (Pattern 2)
- Application deployment (Kubernetes, App Service)
- Understanding of cloud architecture

---

## 📋 How to Request Infrastructure (Pattern 1 - Centralized)

If your organization uses centralized management, follow this process:

### Step 1: Submit Infrastructure Request

Create a ticket/form with:

```yaml
Application Name: ecommerce-api
Environment: dev
Team: E-commerce Team
Tech Lead: jane.doe@company.com

Infrastructure Needs:
  ☑️ AKS (Kubernetes)
  ☐ App Service
  ☑️ Cosmos DB
  ☑️ Key Vault
  ☐ Container Apps
  ☐ Web App

Cosmos DB Requirements:
  - Database Name: ecommerce-db
  - Containers:
    1. products (partition: /categoryId)
    2. orders (partition: /userId)
    3. inventory (partition: /warehouseId)
  - Throughput: 400 RU/s per container

Networking:
  - Will connect to on-premises? No
  - Needs public access? Yes (with APIM)
  - Estimated traffic: 100 req/sec

Timeline:
  - Needed by: 2026-02-15
  - Priority: High
```

---

### Step 2: Platform Team Reviews

Platform team checks:
- ✅ Cost estimate within budget?
- ✅ Security requirements met?
- ✅ Naming convention followed?
- ✅ Compliance requirements?

---

### Step 3: Platform Team Deploys

1. **Enable toggles** in `dev.tfvars`:
   ```hcl
   # Feature Toggles
   enable_aks              = true
   enable_cosmosdb        = true
   enable_key_vault        = true
   ```

2. **Configure Cosmos DB** in `variables.tf` or `cosmos-config.tf`:
   ```hcl
   cosmos_databases = {
     ecommerce = {
       name = "ecommerce-db"
       containers = {
         products = {
           partition_key = "/categoryId"
           throughput    = 400
         }
         orders = {
           partition_key = "/userId"
           throughput    = 400
         }
         inventory = {
           partition_key = "/warehouseId"
           throughput    = 400
         }
       }
     }
   }
   ```

3. **Run deployment**:
   ```bash
   cd infra/envs/dev
   terraform init
   terraform plan -var-file="dev.tfvars"
   terraform apply -var-file="dev.tfvars"
   ```

4. **Share outputs** with app team:
   ```
   aks_cluster_name: aks-contoso-dev-001
   aks_resource_group: rg-contoso-dev-aks-001
   cosmos_endpoint: https://cosmos-contoso-dev-001.documents.azure.com
   key_vault_name: kv-contoso-dev-001
   ```

---

### Step 4: App Team Deploys Application

```bash
# Connect to AKS
az aks get-credentials \
  --resource-group rg-contoso-dev-aks-001 \
  --name aks-contoso-dev-001

# Create namespace
kubectl create namespace ecommerce

# Deploy app
kubectl apply -f k8s/deployment.yaml -n ecommerce
```

---

## 🚀 Self-Service Infrastructure (Pattern 2 - Delegated)

If your organization uses delegated management, app teams manage their own Terraform.

### Prerequisites

App teams must complete:
1. ✅ Terraform fundamentals training (2 days)
2. ✅ Azure networking basics (1 day)
3. ✅ Security and compliance training (1 day)
4. ✅ Git workflow for infrastructure (1 day)

---

### Folder Structure (Each App Team)

```
environments/
├── dev-app-ecommerce/        ← E-commerce team owns
│   ├── main.tf               ← App team edits
│   ├── dev.tfvars             ← App team edits
│   ├── variables.tf
│   └── backend.tf
├── dev-app-crm/              ← CRM team owns
│   ├── main.tf               ← CRM team edits
│   └── dev.tfvars             ← CRM team edits
└── dev-shared/               ← Platform team owns
    └── main.tf               ← Landing Zone
```
```

---

### Deployment Process (Self-Service)

**Step 1: Clone the repository**
```bash
git clone https://github.com/your-org/terraform-framework.git
cd terraform-framework
```

**Step 2: Use examples as templates**
```bash
# Reference the pattern-2-delegated examples
cd examples/pattern-2-delegated/dev-app-ecommerce

# Review the example configuration
cat main.tf
cat dev.tfvars
```

**Step 3: Copy and customize for your app**
```bash
# Copy the example that fits your needs
cp -r examples/pattern-2-delegated/dev-app-ecommerce my-app/

# Customize the configuration
cd my-app/
# Edit main.tf and dev.tfvars for your needs
```

**Step 4: Fill in parameters** (see [STEP-BY-STEP-EXAMPLE.md](STEP-BY-STEP-EXAMPLE.md))

**Step 5: Create Pull Request**
```bash
git checkout -b feature/ecommerce-infrastructure
git add .
git commit -m "feat: add e-commerce infrastructure"
git push origin feature/ecommerce-infrastructure
```

**Step 6: Platform team reviews**
- ✅ Security check (no hardcoded secrets)
- ✅ Naming convention followed
- ✅ Cost estimate acceptable
- ✅ Terraform plan successful

**Step 7: Merge and deploy**
```bash
# After approval, deploy from your customized location:
cd my-app/
terraform init
terraform apply -var-file="dev.tfvars" -auto-approve
```

---

## 🔒 Governance and Guard Rails

### Pre-deployment Checks (Automated)

Platform team sets up CI/CD with:

1. **Cost estimation** (via Infracost)
   ```
   ❌ FAIL: Estimated cost $5,000/month exceeds limit $3,000/month
   ✅ PASS: Estimated cost $2,500/month within budget
   ```

2. **Security scanning** (via Checkov, tfsec)
   ```
   ❌ FAIL: Storage account allows public access
   ✅ PASS: All resources use private endpoints
   ```

3. **Policy validation** (via Azure Policy)
   ```
   ❌ FAIL: Resource missing required tags
   ✅ PASS: All resources properly tagged
   ```

4. **Naming convention check** (custom script)
   ```
   ❌ FAIL: Resource name doesn't follow pattern
   ✅ PASS: All names follow convention
   ```

---

### Manual Review Process

For high-risk changes, platform team reviews:

**Triggers manual review:**
- Production environment changes
- Networking changes (VNet, subnet, NSG)
- IAM role assignments
- Estimated cost > $1,000/month
- Public endpoint exposure

**Review checklist:**
```
☐ Does this follow our security standards?
☐ Is this the most cost-effective solution?
☐ Does this create technical debt?
☐ Is disaster recovery considered?
☐ Are monitoring and alerts configured?
☐ Is documentation updated?
```

---

## 📞 Communication Channels

### Platform Team
- **Slack:** #platform-team
- **Email:** platform@company.com
- **Office Hours:** Tuesday & Thursday 2-4pm
- **On-call:** PagerDuty rotation

### Infrastructure Requests
- **Ticket System:** Jira board "Infrastructure Requests"
- **SLA:** 
  - Dev: 2 business days
  - Staging: 1 business day
  - Prod: 4 hours (urgent), 1 business day (normal)

### Knowledge Base
- **Wiki:** https://wiki.company.com/infrastructure
- **Runbooks:** https://runbooks.company.com
- **Training:** https://learning.company.com/terraform

---

## 🎓 Training Path

### For App Teams (Pattern 2)

**Week 1: Terraform Fundamentals**
- ☐ What is Infrastructure as Code?
- ☐ Terraform basic syntax
- ☐ State management concepts
- ☐ Modules and reusability

**Week 2: Azure Networking Basics**
- ☐ VNet, subnets, NSGs
- ☐ Private endpoints vs public endpoints
- ☐ Azure Load Balancer, Application Gateway
- ☐ DNS and name resolution

**Week 3: Security and Compliance**
- ☐ Managed identities
- ☐ Key Vault usage
- ☐ RBAC best practices
- ☐ Compliance requirements (SOC2, HIPAA)

**Week 4: Hands-on Workshop**
- ☐ Deploy sample application
- ☐ Modify existing infrastructure
- ☐ Debug Terraform issues
- ☐ Create Pull Request

**Week 5: Production Readiness**
- ☐ Disaster recovery planning
- ☐ Monitoring and alerting
- ☐ Cost optimization
- ☐ Incident response

---

## 🆘 Troubleshooting Common Issues

### Issue 1: "Error acquiring state lock"

**Problem:** Someone else is running Terraform

**Solution:**
```bash
# Check who has the lock
az storage blob list --account-name stcontosodevtfstate001 \
  --container-name tfstate

# If lock is stuck (rare), force unlock
terraform force-unlock <LOCK_ID>
```

---

### Issue 2: "Provider registry.terraform.io/hashicorp/azurerm version constraint not met"

**Problem:** Wrong Terraform or provider version

**Solution:**
```bash
# Check version
terraform version

# Required versions in versions.tf:
# Terraform: >= 1.5.0
# AzureRM: ~> 3.80

# Upgrade Terraform
choco upgrade terraform  # Windows
brew upgrade terraform   # macOS
```

---

### Issue 3: "Insufficient permissions to create resource"

**Problem:** Your Azure identity lacks permissions

**Solution:**
```bash
# Check your current identity
az account show

# Required roles:
# - Contributor (for resources)
# - User Access Administrator (for IAM)

# Contact platform team to grant permissions
```

---

### Issue 4: "Naming convention violation"

**Problem:** Resource name doesn't follow pattern

**Solution:**
```hcl
# ❌ BAD
resource "azurerm_resource_group" "example" {
  name = "my-rg"  # Too generic
}

# ✅ GOOD
resource "azurerm_resource_group" "example" {
  name = "rg-contoso-dev-ecommerce-001"
  #      ^^ ^^^^^^^ ^^^ ^^^^^^^^^ ^^^
  #      |    |     |      |       └─ Instance number
  #      |    |     |      └───────── App/workload
  #      |    |     └──────────────── Environment
  #      |    └────────────────────── Company/org
  #      └─────────────────────────── Resource type
}

# Use naming module (recommended)
module "naming" {
  source = "../../_shared/naming"
  
  company_name = "contoso"
  environment  = "dev"
  workload     = "ecommerce"
}

resource "azurerm_resource_group" "example" {
  name = module.naming.resource_group_name  # Generates: rg-contoso-dev-ecommerce-001
}
```

---

## 📊 Success Metrics

Track these KPIs to measure team effectiveness:

| Metric | Target | Current |
|--------|--------|---------|
| **Infrastructure Request Lead Time** | < 2 days | ? |
| **Self-Service Adoption Rate** | > 70% | ? |
| **Failed Deployments** | < 5% | ? |
| **Time to Deploy New App** | < 1 week | ? |
| **Cost Overruns** | < 10% | ? |
| **Security Incidents** | 0 | ? |

---

## 🎯 Evolution Roadmap

### Phase 1: Foundation (Month 1-3)
- ✅ Platform team builds global + landing zone
- ✅ Deploy first 2-3 applications (learn patterns)
- ✅ Document processes and create runbooks
- ✅ Set up CI/CD pipelines

### Phase 2: Enablement (Month 4-6)
- 🔄 Train first app team (pilot)
- 🔄 Pilot team deploys their own infrastructure (Pattern 2)
- 🔄 Gather feedback, refine processes
- 🔄 Create guard rails and policy enforcement

### Phase 3: Scale (Month 7-12)
- ⏳ Train all app teams
- ⏳ Migrate to Pattern 2 (delegated)
- ⏳ Platform team maintains foundation only
- ⏳ Continuous improvement based on metrics

### Phase 4: Optimization (Month 13+)
- ⏳ FinOps practices (cost optimization)
- ⏳ Advanced patterns (multi-region, DR)
- ⏳ Infrastructure as Product mindset
- ⏳ Community of practice for Terraform

---

## 📚 Additional Resources

- [Getting Started Guide](GETTING-STARTED.md) - First-time deployment
- [Deployment Workflow](DEPLOYMENT-WORKFLOW.md) - Understand incremental deployment
- [Step-by-Step Example](STEP-BY-STEP-EXAMPLE.md) - Complete walkthrough
- [Why These Choices](WHY-THESE-CHOICES.md) - Architecture decisions

---

## 🤝 Contributing

Have suggestions for improving team collaboration?

1. Create an issue in GitHub
2. Share in #platform-team Slack
3. Bring up in weekly platform sync
4. Submit a PR with improvements

**We're all in this together!** 🚀
