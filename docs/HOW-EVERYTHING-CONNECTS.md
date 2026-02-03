# How Everything Connects

This guide explains how all the pieces of our infrastructure fit together. Written for beginners - no prior Azure knowledge needed!

---

## The Big Picture

Think of our infrastructure like building a **secure office building**:

```
┌─────────────────────────────────────────────────────────────────┐
│                        THE INTERNET                              │
│                     (Outside World)                              │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     LANDING ZONE                                 │
│              (The Building Foundation)                           │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │  AKS Subnet  │  │  App Subnet  │  │ Data Subnet  │          │
│  │  (Floor 1)   │  │  (Floor 2)   │  │  (Floor 3)   │          │
│  │              │  │              │  │              │          │
│  │  Kubernetes  │  │ Container    │  │  Cosmos DB   │          │
│  │  Clusters    │  │ Apps         │  │  Key Vault   │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │              LOG ANALYTICS (Security Cameras)             │   │
│  │              Watches everything that happens              │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

---

## What Each Part Does

### 1. Landing Zone = The Building Foundation

**What is it?**
The Landing Zone is the shared foundation that ALL your applications use. Just like a building has one foundation, electrical system, and plumbing that all floors share.

**What's included:**
- **Virtual Network (VNet)** = The building itself (walls, floors)
- **Subnets** = Different floors/sections of the building
- **Network Security Groups (NSGs)** = Security guards checking who can go where
- **Log Analytics** = Security cameras recording everything

**Why do we need it?**
Without a Landing Zone, each team would build their own "building" - leading to chaos:
- IP address conflicts (two buildings at the same address!)
- No unified security (some doors locked, some wide open)
- Higher costs (building 10 foundations vs 1)

---

### 2. How a User Request Flows Through the System

Let's follow a user clicking a button on your website:

```
Step 1: User clicks "Submit Order"
         │
         ▼
Step 2: Request travels through the INTERNET
         │
         ▼
Step 3: Hits AZURE LOAD BALANCER (the front door)
         │
         ▼
Step 4: Goes to AKS CLUSTER (your application code)
         │
         ├──────────────────────────────────┐
         ▼                                  ▼
Step 5a: App needs a secret?          Step 5b: App needs to save data?
         │                                  │
         ▼                                  ▼
    KEY VAULT                          COSMOS DB
    (Password safe)                    (Database)
         │                                  │
         └──────────────────────────────────┘
                         │
                         ▼
Step 6: Response goes back to user: "Order confirmed!"
```

**In plain English:**
1. User does something (clicks, submits form)
2. Request travels over the internet to Azure
3. Load Balancer receives it and decides where to send it
4. Your application (running in AKS) processes the request
5. Application might need to:
   - Get a password from Key Vault (like database connection string)
   - Save/read data from Cosmos DB
6. Response goes back to user

---

### 3. How Services Talk to Each Other (Securely)

The key question: **How does your app in AKS connect to Cosmos DB without exposing passwords?**

```
┌─────────────────────────────────────────────────────────────────┐
│                         AKS CLUSTER                              │
│                                                                  │
│   ┌─────────────┐                                               │
│   │  Your App   │                                               │
│   │  (Pod)      │                                               │
│   └──────┬──────┘                                               │
│          │                                                       │
│          │ "I need the database password"                        │
│          │                                                       │
│          ▼                                                       │
│   ┌─────────────────┐                                           │
│   │ Managed Identity │  ← This is like a digital ID card        │
│   │ (No passwords!) │    Azure trusts it automatically          │
│   └────────┬────────┘                                           │
│            │                                                     │
└────────────┼─────────────────────────────────────────────────────┘
             │
             │ "Hey Key Vault, it's me (verified by Azure AD)"
             │
             ▼
┌─────────────────────────────────────────────────────────────────┐
│                         KEY VAULT                                │
│                                                                  │
│   "Let me check... yes, this app is allowed to read secrets"     │
│                                                                  │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │  cosmos-db-connection = "AccountEndpoint=https://..."    │   │
│   │  api-key = "secret-value-here"                           │   │
│   │  storage-key = "another-secret"                          │   │
│   └─────────────────────────────────────────────────────────┘   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

**The Magic: Managed Identity**

Instead of storing passwords in your code (dangerous!), we use **Managed Identity**:
- Azure automatically gives your app a digital "ID card"
- When your app needs a secret, it shows this ID card to Key Vault
- Key Vault checks: "Is this ID allowed?" → Yes → "Here's the secret"
- **No passwords stored anywhere in your code!**

---

### 4. Network Security: Who Can Talk to Who?

Think of Network Security Groups (NSGs) as **security guards with a checklist**:

```
┌─────────────────────────────────────────────────────────────────┐
│                      AKS SUBNET (10.1.1.0/24)                    │
│                                                                  │
│   NSG Rules (Security Guard Checklist):                          │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │ ✅ Allow HTTPS (port 443) from Internet                  │   │
│   │ ✅ Allow traffic from App Subnet                         │   │
│   │ ❌ Block everything else                                 │   │
│   └─────────────────────────────────────────────────────────┘   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ "Is this allowed?"
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     DATA SUBNET (10.1.3.0/24)                    │
│                                                                  │
│   NSG Rules:                                                     │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │ ✅ Allow traffic from AKS Subnet only                    │   │
│   │ ✅ Allow traffic from App Subnet only                    │   │
│   │ ❌ Block traffic from Internet (no public access!)       │   │
│   │ ❌ Block everything else                                 │   │
│   └─────────────────────────────────────────────────────────┘   │
│                                                                  │
│   Contains: Cosmos DB, Key Vault (via Private Endpoints)         │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

**Why This Matters:**
- Cosmos DB is **never exposed to the internet**
- Only apps running in your VNet can reach it
- Even if someone hacks the internet-facing part, they can't reach your data

---

### 5. The Three Environments: Dev → Staging → Prod

We have three separate "buildings" (environments):

```
┌─────────────────────────────────────────────────────────────────┐
│                        DEVELOPMENT                               │
│                    IP Range: 10.1.0.0/16                         │
│                                                                  │
│   Purpose: Engineers experiment here                             │
│   Security: Basic (OK if things break)                           │
│   Cost: Low (small VMs, short log retention)                     │
│   Access: Developers can deploy freely                           │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ Code tested? Promote to staging
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                         STAGING                                  │
│                    IP Range: 10.2.0.0/16                         │
│                                                                  │
│   Purpose: Final testing before production                       │
│   Security: Medium (mimics production)                           │
│   Cost: Medium                                                   │
│   Access: Requires approval to deploy                            │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ QA approved? Promote to production
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                        PRODUCTION                                │
│                    IP Range: 10.3.0.0/16                         │
│                                                                  │
│   Purpose: Real users use this!                                  │
│   Security: Maximum (strictest rules)                            │
│   Cost: Higher (larger VMs, longer log retention)                │
│   Access: Requires manager approval to deploy                    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

**Why Separate IP Ranges?**
- They CANNOT accidentally talk to each other
- A bug in dev cannot affect production
- Clear separation for security audits

---

### 6. What Happens When You Run `terraform apply`

```
You type: terraform apply
              │
              ▼
┌─────────────────────────────────────────────────────────────────┐
│ Step 1: Terraform reads your .tf files                          │
│         "What infrastructure do you want?"                       │
└─────────────────────────────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────────────────────────┐
│ Step 2: Terraform checks current state                          │
│         "What already exists in Azure?"                          │
└─────────────────────────────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────────────────────────┐
│ Step 3: Terraform calculates the difference                     │
│         "What needs to be created/changed/deleted?"              │
│                                                                  │
│         + azurerm_resource_group.main (CREATE)                   │
│         ~ azurerm_virtual_network.vnet (MODIFY)                  │
│         - azurerm_subnet.old (DELETE)                            │
└─────────────────────────────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────────────────────────┐
│ Step 4: You review and confirm                                  │
│         "Do you want to perform these actions?"                  │
│         Type 'yes' to confirm                                    │
└─────────────────────────────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────────────────────────┐
│ Step 5: Terraform calls Azure APIs                              │
│         Creates resources in the right order                     │
│         (VNet before Subnet, Subnet before AKS, etc.)           │
└─────────────────────────────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────────────────────────┐
│ Step 6: Terraform saves the state                               │
│         Records what was created (for next time)                 │
│         Stored in Azure Storage Account (shared with team)       │
└─────────────────────────────────────────────────────────────────┘
```

---

### 7. The CI/CD Pipeline: From Code to Cloud

When you push code, here's what happens automatically:

```
Developer pushes code
         │
         ▼
┌─────────────────────────────────────────────────────────────────┐
│              PULL REQUEST CREATED                                │
│                                                                  │
│   Automatic checks run:                                          │
│   ├── terraform fmt (Is code formatted correctly?)               │
│   ├── terraform validate (Is code valid?)                        │
│   └── terraform plan (What would change?)                        │
│                                                                  │
│   Result: Comment on PR showing planned changes                  │
└─────────────────────────────────────────────────────────────────┘
         │
         │ Teammate reviews and approves PR
         ▼
┌─────────────────────────────────────────────────────────────────┐
│              PR MERGED TO MAIN BRANCH                            │
│                                                                  │
│   Deployment pipeline triggered:                                 │
│   ├── terraform plan (Calculate changes again)                   │
│   ├── ⏸️  WAIT FOR APPROVAL (Human must click "Approve")         │
│   └── terraform apply (Actually create resources)                │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
         │
         ▼
    Infrastructure deployed! 🎉
```

**Why the approval step?**
- Prevents accidental deletions
- Someone else reviews what will change
- Creates audit trail (who approved what, when)

---

## Summary: The Complete Picture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                                                                          │
│    LAYER 0: GLOBAL STANDARDS                                             │
│    ├── Terraform versions (everyone uses same version)                   │
│    ├── Azure provider config (how to connect to Azure)                   │
│    └── Tags (who owns this, what environment, cost center)               │
│                                                                          │
│    ─────────────────────────────────────────────────────────────────     │
│                                                                          │
│    LAYER 1: LANDING ZONE                                                 │
│    ├── Virtual Network (the "building")                                  │
│    ├── Subnets (floors in the building)                                  │
│    ├── NSGs (security guards)                                            │
│    └── Log Analytics (security cameras)                                  │
│                                                                          │
│    ─────────────────────────────────────────────────────────────────     │
│                                                                          │
│    LAYER 2: PLATFORMS (where your apps run)                              │
│    ├── AKS = Kubernetes clusters (complex apps, microservices)           │
│    ├── Container Apps = Serverless containers (simpler apps)             │
│    └── App Service = Traditional web apps (.NET, Node.js, Python)        │
│                                                                          │
│    ─────────────────────────────────────────────────────────────────     │
│                                                                          │
│    LAYER 3: SERVICES (supporting services)                               │
│    ├── Cosmos DB = Database (stores your data)                           │
│    ├── Key Vault = Secrets (stores passwords safely)                     │
│    └── Storage = Files and blobs                                         │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

**The Rule:** Each layer builds on the one below it. You can't have AKS without a Landing Zone, and you can't have a Landing Zone without Global Standards.

---

## Next Steps

Now that you understand how everything connects:

1. **[Getting Started Guide](GETTING-STARTED.md)** - Deploy your first environment
2. **[Why These Choices](WHY-THESE-CHOICES.md)** - Understand our design decisions
3. **Module-specific guides** - Deep dive into each service

---

## Common Questions

**Q: Why not just put everything in one big network?**
A: Separation of concerns. If an attacker compromises one area, they can't easily reach others. Also makes it easier to manage permissions.

**Q: Why use Terraform instead of clicking in Azure Portal?**
A: 
- Repeatable: Same code = same infrastructure every time
- Reviewable: Changes go through code review
- Reversible: Easy to roll back
- Documented: Code IS the documentation

**Q: What if something goes wrong?**
A: Terraform state shows exactly what exists. You can run `terraform destroy` to clean up, or fix the code and `terraform apply` again.

**Q: Can I deploy just one module?**
A: Yes! Each module is independent. But some modules depend on others (e.g., AKS needs a subnet from Landing Zone first).
