# 📖 Documentation Index

Welcome! This guide will help you find the right documentation based on what you need.

---

## 🆕 New to This Project? Start Here!

| Step | Document | What You'll Learn |
|------|----------|-------------------|
| 1️⃣ | [How Everything Connects](HOW-EVERYTHING-CONNECTS.md) | The big picture - how all pieces work together |
| 2️⃣ | [Why These Choices](WHY-THESE-CHOICES.md) | Why we built it this way |
| 3️⃣ | [Getting Started](GETTING-STARTED.md) | Step-by-step deployment guide |

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
│   └── GETTING-STARTED.md             # Step-by-step deployment
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

infra/modules/
├── aks/HOW-IT-WORKS.md                 # Kubernetes explained
├── container-app/HOW-IT-WORKS.md       # Serverless containers
├── cosmosdb/HOW-IT-WORKS.md            # NoSQL database
├── landing-zone/HOW-IT-WORKS.md        # Shared foundation
├── networking/HOW-IT-WORKS.md          # VNets and networking
├── security/HOW-IT-WORKS.md            # Key Vault and secrets
└── webapp/HOW-IT-WORKS.md              # App Service
```

---

## ❓ Common Questions

### "I'm completely new. Where do I start?"
→ Read [How Everything Connects](HOW-EVERYTHING-CONNECTS.md) first, then [Getting Started](GETTING-STARTED.md).

### "I need to deploy something. How?"
→ Follow [Getting Started](GETTING-STARTED.md) for step-by-step instructions.

### "Why did we choose AKS over Container Apps?"
→ See [Why These Choices](WHY-THESE-CHOICES.md#5-aks-vs-container-apps).

### "How does the networking work?"
→ Read [Networking How It Works](../infra/modules/networking/HOW-IT-WORKS.md).

### "How do I set up the CI/CD pipeline?"
→ Follow [Azure DevOps Setup Guide](AZURE-DEVOPS-SETUP.md).

### "What will this cost?"
→ See [Cost Estimates](../README.md#-cost-estimates) in the main README.
