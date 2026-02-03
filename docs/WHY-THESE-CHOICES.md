# Why We Made These Choices

This document explains the "why" behind every major decision in our framework. Written in plain English - no jargon!

---

## Table of Contents

1. [Why Terraform?](#1-why-terraform)
2. [Why This Folder Structure?](#2-why-this-folder-structure)
3. [Why Separate Environments?](#3-why-separate-environments)
4. [Why AKS vs Container Apps vs App Service?](#4-why-aks-vs-container-apps-vs-app-service)
5. [Why Landing Zone Pattern?](#5-why-landing-zone-pattern)
6. [Why Key Vault for Secrets?](#6-why-key-vault-for-secrets)
7. [Why Cosmos DB?](#7-why-cosmos-db)
8. [Why These IP Ranges?](#8-why-these-ip-ranges)
9. [Why NAT Gateway Only in Production?](#9-why-nat-gateway-only-in-production)
10. [Why RBAC Instead of Access Policies?](#10-why-rbac-instead-of-access-policies)
11. [Why Managed Identity?](#11-why-managed-identity)
12. [Why Azure DevOps Pipelines?](#12-why-azure-devops-pipelines)

---

## 1. Why Terraform?

### The Problem
Imagine building infrastructure by clicking buttons in Azure Portal:
- Monday: You create a VNet with certain settings
- Friday: Your colleague creates another VNet, but slightly different
- Next month: No one remembers exactly what was configured

### The Solution: Infrastructure as Code

```
Without Terraform:              With Terraform:
─────────────────               ───────────────
Click, click, click...          Write code once
"What settings did I use?"      Code IS the documentation
"Who changed this?"             Git shows all changes
"Make another one like it"      Copy the code, done!
```

### Why Terraform Specifically?

| Option | Pros | Cons | Our Choice |
|--------|------|------|------------|
| **Azure Portal** | Easy to learn | Not repeatable, no history | ❌ |
| **ARM Templates** | Azure-native | JSON is hard to read | ❌ |
| **Bicep** | Better than ARM | Azure-only | ❌ |
| **Terraform** | Multi-cloud, readable, huge community | Learning curve | ✅ |

**Our decision:** Terraform because:
- HCL (HashiCorp Configuration Language) is readable
- Works with Azure, AWS, GCP (future flexibility)
- Massive community = lots of examples and help
- State management = knows what exists vs what should exist

---

## 2. Why This Folder Structure?

### The Problem
Without structure, you get chaos:
```
my-terraform/
├── main.tf           (1000 lines, everything mixed together)
├── variables.tf      (200 variables, hard to find anything)
└── prod.tf          (copy-pasted from main.tf, now out of sync)
```

### Our Solution: Organized by Purpose

```
infra/
├── global/           ← Standards that NEVER change
│   ├── versions.tf   (Terraform version)
│   ├── providers.tf  (Azure connection)
│   └── locals.tf     (Shared values)
│
├── modules/          ← Reusable building blocks
│   ├── aks/          (Kubernetes)
│   ├── cosmosdb/     (Database)
│   └── ...
│
└── envs/             ← Environment-specific configs
    ├── dev/          (Development settings)
    ├── staging/      (Staging settings)
    └── prod/         (Production settings)
```

### Why This Works

| Benefit | How It Helps |
|---------|--------------|
| **Separation** | Change dev without affecting prod |
| **Reusability** | Use same module in all environments |
| **Clarity** | Know exactly where to look |
| **Safety** | Can't accidentally mix environments |

---

## 3. Why Separate Environments?

### The Problem
If dev and prod share infrastructure:
- Developer tests something → breaks production
- Security settings get relaxed for testing → production now vulnerable
- Costs are mixed → can't tell what's dev vs prod spending

### Our Solution: Complete Isolation + Feature Toggles

```
DEV (10.1.0.0/16)          STAGING (10.2.0.0/16)        PROD (10.3.0.0/16)
┌─────────────────┐        ┌─────────────────┐        ┌─────────────────┐
│  Simple & Cheap │   →    │  Add Monitoring │   →    │  Full Security  │
│  Break things   │        │  Test properly  │        │  Real users!    │
│  Experiment     │        │  Final check    │        │  Maximum care   │
└─────────────────┘        └─────────────────┘        └─────────────────┘
     $100-300/mo               $300-800/mo               $2,000-8,000/mo
```

**Key insight:** Different IP ranges (10.1, 10.2, 10.3) mean they CANNOT accidentally communicate.

### Feature Toggles: Control Complexity Per Environment

Instead of copy-pasting different configurations, we use **feature toggles**:

```hcl
# dev.tfvars - Keep it simple!
enable_nat_gateway         = false   # Don't need it
enable_private_endpoints   = false   # Public access is fine
enable_application_insights = false  # Save money
aks_node_count             = 1       # Just one small node

# prod.tfvars - Everything on!
enable_nat_gateway         = true    # Control outbound traffic
enable_private_endpoints   = true    # No public access to data
enable_application_insights = true   # Need monitoring
aks_node_count             = 3       # Minimum for HA
```

### Why Feature Toggles Work Better

| Without Toggles | With Toggles |
|-----------------|--------------|
| Copy entire main.tf per environment | Same main.tf, different values |
| Changes need updating in 3 places | Changes in one place |
| Easy to forget to update prod | Prod automatically gets more security |
| Hard to see differences | Compare tfvars files to see differences |

### Environment Philosophy Summary

| Environment | Philosophy | Key Settings |
|-------------|------------|--------------|
| **Dev** | "Make it work" | Cheap, simple, public access OK |
| **Staging** | "Make it right" | Add monitoring, test with real settings |
| **Prod** | "Make it secure" | Full security, HA, compliance-ready |

---

## 4. Why AKS vs Container Apps vs App Service?

This is one of the most common questions. Here's a simple decision guide:

### The Three Options Explained

**AKS (Azure Kubernetes Service)**
```
Think of it as: A shipping port where you control every crane, truck, and warehouse
Best for: Complex applications with many moving parts
Complexity: High (but we provide templates!)
```

**Container Apps**
```
Think of it as: A shipping service - you give them containers, they handle delivery
Best for: Simpler containerized apps, event-driven workloads
Complexity: Medium
```

**App Service**
```
Think of it as: A hotel for your code - just bring your bags (code), they handle the room
Best for: Traditional web apps, APIs
Complexity: Low
```

### Decision Flowchart

```
Do you need Kubernetes-specific features?
(Custom operators, service mesh, complex networking)
        │
        ├── YES → Use AKS
        │
        └── NO → Does your app need to scale to zero when idle?
                        │
                        ├── YES → Use Container Apps
                        │
                        └── NO → Is it a traditional web app?
                                        │
                                        ├── YES → Use App Service
                                        │
                                        └── NO → Use Container Apps
```

### Why We Include All Three

Different teams have different needs:
- **Team A** building microservices platform → **AKS**
- **Team B** building event processors → **Container Apps**
- **Team C** building internal website → **App Service**

One framework serves all!

---

## 5. Why Landing Zone Pattern?

### The Problem Without Landing Zone

```
Team A creates:                    Team B creates:
├── VNet: 10.0.0.0/16             ├── VNet: 10.0.0.0/16  ← CONFLICT!
├── Log Analytics: team-a-logs    ├── Log Analytics: team-b-logs  ← DUPLICATE
└── NSG: allow-all                └── NSG: different-rules  ← INCONSISTENT
```

**Result:** Chaos. IP conflicts. No unified logging. Inconsistent security.

### The Solution: Shared Foundation

```
LANDING ZONE (Created ONCE)
├── VNet: 10.1.0.0/16
├── Subnets: aks-subnet, app-subnet, data-subnet
├── Log Analytics: unified-logs (ONE place for all logs)
└── NSGs: consistent-security-rules

Team A uses:                      Team B uses:
└── aks-subnet                    └── app-subnet
    (from Landing Zone)               (from Landing Zone)
```

**Result:** 
- No IP conflicts (centrally managed)
- Unified logging (see everything in one dashboard)
- Consistent security (one set of rules for everyone)
- Lower costs (share infrastructure instead of duplicate)

### Real-World Analogy

**Without Landing Zone:** Each tenant builds their own building
**With Landing Zone:** One building, each tenant gets a floor

---

## 6. Why Key Vault for Secrets?

### The Problem

Where do you put passwords, API keys, and connection strings?

**Bad options:**
```
❌ In code:              password = "MySecretPassword123"
                         (Anyone who sees code sees password!)

❌ In environment vars:  Easy to leak in logs, process lists

❌ In config files:      Often committed to Git by mistake
```

### The Solution: Azure Key Vault

```
Your Code                          Key Vault
─────────                          ─────────
password = ???                     ┌─────────────────────────┐
                                   │ database-password       │
"Hey Key Vault,         ────────→  │ = "actual-secret-here" │
 I need database-password"         │                         │
                                   │ api-key                 │
"Here you go"           ←────────  │ = "another-secret"     │
                                   └─────────────────────────┘
```

**Benefits:**
| Feature | Benefit |
|---------|---------|
| Centralized | All secrets in one place |
| Audited | Know who accessed what, when |
| Rotatable | Change password without redeploying app |
| Encrypted | Secrets encrypted at rest |
| RBAC | Fine-grained access control |

---

## 7. Why Cosmos DB?

### When to Use Cosmos DB

We recommend Cosmos DB when you need:

| Need | Why Cosmos DB |
|------|---------------|
| **Global distribution** | Data replicated worldwide automatically |
| **Flexible schema** | Don't know exact data structure yet |
| **High throughput** | Millions of reads/writes per second |
| **Low latency** | Single-digit millisecond response times |

### When NOT to Use Cosmos DB

| Need | Better Choice |
|------|---------------|
| Complex SQL queries | Azure SQL Database |
| Strict schema enforcement | Azure SQL Database |
| Cost-sensitive, low throughput | Azure SQL Database |
| Relational data with joins | Azure SQL Database |

### Why It's in Our Framework

Cosmos DB fits perfectly with:
- Microservices (each service owns its data)
- IoT workloads (high ingestion rates)
- Globally distributed apps (data follows users)

---

## 8. Why These IP Ranges?

### The Numbers

```
Dev:     10.1.0.0/16  →  10.1.0.0 to 10.1.255.255  (65,536 addresses)
Staging: 10.2.0.0/16  →  10.2.0.0 to 10.2.255.255  (65,536 addresses)
Prod:    10.3.0.0/16  →  10.3.0.0 to 10.3.255.255  (65,536 addresses)
```

### Why 10.x.x.x?

These are "private" IP addresses (RFC 1918). They:
- Can't be routed on the public internet (safe)
- Won't conflict with real internet addresses
- Are industry standard for internal networks

### Why Different Second Number (10.1, 10.2, 10.3)?

**Prevents accidents:**
```
Dev (10.1.x.x) trying to reach Prod (10.3.x.x)?
→ No route exists
→ Connection fails
→ Problem avoided!
```

### Why /16?

Gives us 65,536 IP addresses per environment. That's plenty for:
- Thousands of AKS pods
- Hundreds of VMs
- Room to grow

---

## 9. Why NAT Gateway Only in Production?

### What NAT Gateway Does

```
Without NAT Gateway:                With NAT Gateway:
───────────────────                 ─────────────────
Each VM gets random                 All VMs share ONE
outbound IP                         static outbound IP

IP: 40.1.2.3  ─┐                    ┌─ VM1 ─┐
IP: 40.4.5.6  ─┼──→ Internet        │ VM2   ├──→ NAT ──→ Internet
IP: 40.7.8.9  ─┘                    └─ VM3 ─┘    (52.1.2.3)
```

### Why Production Only?

| Environment | NAT Gateway? | Reason |
|-------------|--------------|--------|
| **Dev** | ❌ No | Save money, don't need static IP |
| **Staging** | ❌ No | Save money, not customer-facing |
| **Prod** | ✅ Yes | Need static IP for firewall rules, partner integrations |

### The Cost Factor

NAT Gateway costs ~$32/month + data transfer fees. In dev, that adds up across multiple developers' environments.

---

## 10. Why RBAC Instead of Access Policies?

### The Two Ways to Control Key Vault Access

**Access Policies (Old Way)**
```
Key Vault settings:
├── Policy 1: User A can read secrets
├── Policy 2: User B can read/write secrets
├── Policy 3: App C can read secrets
└── (Policies stored IN Key Vault)
```

**RBAC (New Way - Our Choice)**
```
Azure Role Assignments:
├── User A → "Key Vault Secrets User" role
├── User B → "Key Vault Secrets Officer" role
└── App C → "Key Vault Secrets User" role
    (Permissions managed centrally in Azure AD)
```

### Why We Chose RBAC

| Feature | Access Policies | RBAC |
|---------|-----------------|------|
| Manage in one place | ❌ Per Key Vault | ✅ Azure AD |
| Consistent with other Azure resources | ❌ Different system | ✅ Same as everything |
| Fine-grained control | ⚠️ Limited | ✅ Very granular |
| Audit trail | ⚠️ Basic | ✅ Full Azure AD logs |
| Microsoft recommendation | ❌ Legacy | ✅ Recommended |

---

## 11. Why Managed Identity?

### The Problem with Service Accounts

Old way: Create a "service account" with username/password:
```
App config:
  AZURE_CLIENT_ID: "abc-123"
  AZURE_CLIENT_SECRET: "SuperSecretPassword123"  ← Must store somewhere!
```

**Risks:**
- Password can leak
- Password expires, app breaks
- Password in logs, source control, etc.

### The Solution: Managed Identity

Azure automatically gives your app an identity:
```
┌──────────────────────────────────────────────────────────────┐
│  Azure: "Hey AKS cluster, here's your identity certificate"  │
│                                                              │
│  AKS: "Thanks! I'll use this to prove who I am"             │
│                                                              │
│  AKS → Key Vault: "It's me, verified by Azure AD"           │
│                                                              │
│  Key Vault: "Let me check Azure AD... yes, you're allowed"  │
│             "Here's the secret you requested"                │
└──────────────────────────────────────────────────────────────┘
```

**No passwords anywhere!**

### Benefits

| Benefit | Description |
|---------|-------------|
| **No secrets to manage** | Azure handles the identity |
| **Automatic rotation** | Certificates rotate automatically |
| **Can't be leaked** | Nothing to leak! |
| **Easy auditing** | Azure AD logs all access |

---

## 12. Why Azure DevOps Pipelines?

### The Problem with Manual Deployments

```
Developer: "I'll just run terraform apply on my laptop"

What could go wrong:
├── Different Terraform version than teammates
├── Forgot to pull latest changes
├── Applied to wrong environment
├── No record of who changed what
└── Laptop dies mid-apply → corrupt state
```

### The Solution: Automated Pipelines

```
Code Change → Pull Request → Automatic Plan → Review → Merge → Automatic Apply
     │              │              │            │         │            │
     │              │              │            │         │            │
   Human          Human         Robot        Human     Human        Robot
   writes         creates       runs         reviews   approves     deploys
   code           PR            terraform    changes   PR           safely
```

### Why Azure DevOps Specifically?

| Option | Pros | Cons | Our Choice |
|--------|------|------|------------|
| **GitHub Actions** | Popular, free for public repos | Less Azure integration | Maybe later |
| **Azure DevOps** | Deep Azure integration, enterprise features | Learning curve | ✅ |
| **Jenkins** | Very flexible | Self-hosted, maintenance burden | ❌ |
| **GitLab CI** | All-in-one platform | Less common in Azure shops | ❌ |

**Our decision:** Azure DevOps because:
- Native Azure integration
- Built-in approval gates
- Secure variable management
- Enterprise-grade audit logging

---

## Summary: Our Design Principles

1. **Simplicity over complexity** - Use the simplest solution that works
2. **Security by default** - Secure settings out of the box
3. **Separation of concerns** - Each component has one job
4. **Repeatability** - Same code = same result, every time
5. **Flexibility** - Choose the right tool for each job
6. **Cost awareness** - Right-size for each environment

---

## Still Have Questions?

If something isn't clear, that's our fault, not yours! Please ask, and we'll:
1. Answer your question
2. Update this document so others benefit too
