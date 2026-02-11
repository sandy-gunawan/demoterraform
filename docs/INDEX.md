# 📖 Documentation Index

Welcome! This guide will help you find the right documentation based on what you need.

---

## 🆕 New to This Project? Start Here!

| Step | Document | What You'll Learn |
|------|----------|-------------------|
| 1️⃣ | [How Everything Connects](HOW-EVERYTHING-CONNECTS.md) | The big picture - how all pieces work together |
| 2️⃣ | [Why These Choices](WHY-THESE-CHOICES.md) | Why we built it this way |
| 3️⃣ | [Getting Started](GETTING-STARTED.md) | Step-by-step deployment guide |
| 4️⃣ | [Step-by-Step Example](STEP-BY-STEP-EXAMPLE.md) | **NEW!** Complete walkthrough from scratch |
| 5️⃣ | [Deployment Workflow](DEPLOYMENT-WORKFLOW.md) | How to add services without re-deploying everything |
| 6️⃣ | [Team Collaboration](TEAM-COLLABORATION.md) | **NEW!** How teams work together |

---

## 🎛️ Feature Toggles - Controlling What Gets Deployed

This framework uses **feature toggles** to keep dev simple and cheap while prod is fully secured.

| Topic | Where to Find It |
|-------|------------------|
| What are feature toggles? | [Getting Started - Section 3.3](GETTING-STARTED.md#33-feature-toggles---choose-what-to-deploy) |
| Why we use feature toggles? | [Why These Choices - Section 3](WHY-THESE-CHOICES.md#3-why-separate-environments) |
| Feature matrix (what's on/off) | [Getting Started - Feature Matrix](GETTING-STARTED.md#feature-matrix-by-environment) |
| Per-environment settings | See `infra/envs/*/[env].tfvars` files |

**Quick summary:**
- **Dev**: Simple, cheap, public access OK ($100-300/mo)
- **Staging**: + Monitoring, basic security ($300-800/mo)  
- **Prod**: Full security, HA, compliance-ready ($2,000-8,000/mo)

---

## 🔍 Need to Understand a Specific Component?

### Compute (Where Your Code Runs)

| Component | What It Is | Documentation |
|-----------|------------|---------------|
| **AKS** | Managed Kubernetes for containers | [How It Works](../infra/modules/aks/HOW-IT-WORKS.md) |
| **Container Apps** | Serverless containers (simpler than AKS) | [How It Works](../infra/modules/container-app/HOW-IT-WORKS.md) |
| **Web App** | Managed web hosting (PaaS) | [How It Works](../infra/modules/webapp/HOW-IT-WORKS.md) |

### Data & Security

| Component | What It Is | Documentation |
|-----------|------------|---------------|
| **Cosmos DB** | Globally distributed NoSQL database | [How It Works](../infra/modules/cosmosdb/HOW-IT-WORKS.md) |
| **SQL Database** | Managed relational database (Azure SQL) | [How It Works](../infra/modules/sql-database/HOW-IT-WORKS.md) |
| **PostgreSQL** | Managed open-source relational database | [How It Works](../infra/modules/postgresql/HOW-IT-WORKS.md) |
| **Storage** | Blob, file, table, and queue storage | [How It Works](../infra/modules/storage/HOW-IT-WORKS.md) |
| **Key Vault** | Secure secrets management | [How It Works](../infra/modules/security/HOW-IT-WORKS.md) |

### Foundation

| Component | What It Is | Documentation |
|-----------|------------|---------------|
| **Networking** | VNets, subnets, NSGs | [How It Works](../infra/modules/networking/HOW-IT-WORKS.md) |
| **Landing Zone** | Shared foundation for all resources | [How It Works](../infra/modules/landing-zone/HOW-IT-WORKS.md) |

---

## 🛠️ Setting Up CI/CD?

| Task | Documentation |
|------|---------------|
| Set up Azure DevOps pipelines | [Azure DevOps Setup Guide](AZURE-DEVOPS-SETUP.md) |
| Understand the deployment flow | [Getting Started](GETTING-STARTED.md) |

---

## 📊 Need Technical Details?

| Topic | Documentation |
|-------|---------------|
| Full architecture diagrams | [Architecture Overview](technical/README.md) |
| Quick reference card | [Architecture Quick Reference](ARCHITECTURE-QUICK-REFERENCE.md) |
| Implementation phases | [Implementation Phases](IMPLEMENTATION-PHASES.md) |

---

## 💼 Need Business/Management Documentation?

| Topic | Documentation |
|-------|---------------|
| Executive summary | [Executive Summary](executive/README.md) |
| Cost estimates | [Main README](../README.md#-cost-estimates) |

---

## 🗺️ Document Map

```
docs/
├── 📖 INDEX.md                         <-- You are here!
│
├── 🌟 Beginner Documentation
│   ├── HOW-EVERYTHING-CONNECTS.md     # Big picture overview
│   ├── WHY-THESE-CHOICES.md           # Decision rationale
│   ├── GETTING-STARTED.md             # Step-by-step deployment
│   ├── STEP-BY-STEP-EXAMPLE.md        # Complete walkthrough (NEW!)
│   ├── DEPLOYMENT-WORKFLOW.md         # Incremental deployment guide
│   └── TEAM-COLLABORATION.md          # Team workflows (NEW!)
│
├── 🛠️ Setup Guides
│   └── AZURE-DEVOPS-SETUP.md          # CI/CD pipeline setup
│
├── 📊 Technical Documentation
│   ├── technical/                      # Deep technical details
│   ├── ARCHITECTURE-QUICK-REFERENCE.md # Quick reference card
│   └── IMPLEMENTATION-PHASES.md        # Rollout phases
│
└── 💼 Executive Documentation
    └── executive/                      # Business documentation

examples/
├── aks-application/                    # AKS deployment example
├── enterprise-hub-spoke/               # Hub-spoke multi-network example
└── pattern-2-delegated/                # Team delegation examples (NEW!)
    ├── dev-app-ecommerce/              # E-commerce app example
    └── dev-app-crm/                    # CRM app example

infra/modules/
├── aks/HOW-IT-WORKS.md                 # Kubernetes explained
├── container-app/HOW-IT-WORKS.md       # Serverless containers
├── cosmosdb/HOW-IT-WORKS.md            # NoSQL database
├── landing-zone/HOW-IT-WORKS.md        # Shared foundation
├── networking/HOW-IT-WORKS.md          # VNets and networking
├── postgresql/HOW-IT-WORKS.md          # PostgreSQL database
├── security/HOW-IT-WORKS.md            # Key Vault and secrets
├── sql-database/HOW-IT-WORKS.md        # Azure SQL Database
├── storage/HOW-IT-WORKS.md             # Azure Storage Account
└── webapp/HOW-IT-WORKS.md              # App Service
```

---

## ❓ Common Questions

### "I'm completely new. Where do I start?"
→ Read [How Everything Connects](HOW-EVERYTHING-CONNECTS.md) first, then [Step-by-Step Example](STEP-BY-STEP-EXAMPLE.md).

### "I need to deploy something. How?"
→ Follow [Step-by-Step Example](STEP-BY-STEP-EXAMPLE.md) for complete walkthrough with a real use case.

### "I deployed AKS last week. Now I want to add Cosmos DB. Do I redeploy everything?"
→ No! Read [Deployment Workflow](DEPLOYMENT-WORKFLOW.md) - Terraform only creates new resources.

### "How do teams work together on this framework?"
→ See [Team Collaboration](TEAM-COLLABORATION.md) for centralized vs delegated patterns.

### "What parameters do I need to fill and where do I get them?"
→ Follow [Step-by-Step Example](STEP-BY-STEP-EXAMPLE.md) - shows exactly what to fill and where to get each value.

### "Why did we choose AKS over Container Apps?"
→ See [Why These Choices](WHY-THESE-CHOICES.md#5-aks-vs-container-apps).

### "How does the networking work?"
→ Read [Networking How It Works](../infra/modules/networking/HOW-IT-WORKS.md).

### "How do I set up the CI/CD pipeline?"
→ Follow [Azure DevOps Setup Guide](AZURE-DEVOPS-SETUP.md).

### "What will this cost?"
→ See [Cost Estimates](../README.md#-cost-estimates) in the main README.
