# Storage - How It Works

A beginner-friendly guide to Azure Storage concepts. No cloud experience required!

---

## What is Azure Storage?

**Simple explanation:** Think of Azure Storage as a **giant, secure warehouse in the cloud** where you can store any type of data — files, images, backups, logs, application data — and access it from anywhere.

```
Physical World:                    Azure Storage:
════════════════                   ═══════════════
A storage warehouse                A cloud storage account
Different rooms (sections)         Different containers
Boxes inside rooms                 Blobs (files) inside containers
Security guards at the door        Network rules + private endpoints
Inventory tracking                 Versioning + change feed
Insurance against damage           Geo-replication + soft delete
```

---

## Real-World Analogy

Imagine you run a business and need to store important documents:

```
┌─────────────────────────────────────────────────────────────────┐
│                    YOUR STORAGE WAREHOUSE                       │
│                    (= Storage Account)                          │
│                                                                 │
│   ┌──────────────┐  ┌──────────────┐  ┌──────────────┐        │
│   │   Room A      │  │   Room B      │  │   Room C      │       │
│   │  "invoices"   │  │  "backups"    │  │  "logs"       │       │
│   │  (Container)  │  │  (Container)  │  │  (Container)  │       │
│   │               │  │               │  │               │       │
│   │  📄 inv-001   │  │  💾 db-backup │  │  📋 app.log  │       │
│   │  📄 inv-002   │  │  💾 tf-state  │  │  📋 err.log  │       │
│   │  (Blobs)      │  │  (Blobs)      │  │  (Blobs)      │       │
│   └──────────────┘  └──────────────┘  └──────────────┘        │
│                                                                 │
│   🔒 Security: Locked doors (network rules)                    │
│   🔑 Access: Only approved keys (managed identity)             │
│   📸 Versioning: Photos of every change (blob versioning)      │
│   🗑️ Recycling: Items kept 7 days before truly deleted         │
└─────────────────────────────────────────────────────────────────┘
```

---

## Why Do You Need Azure Storage?

### Common Use Cases

```
┌────────────────────┬──────────────────────────────────────────┐
│  Use Case          │  What Gets Stored                        │
├────────────────────┼──────────────────────────────────────────┤
│  Terraform State   │  .tfstate files that track your infra    │
│  Application Data  │  User uploads, images, documents         │
│  Logs & Metrics    │  Application logs, audit trails          │
│  Backups           │  Database backups, disaster recovery     │
│  Static Website    │  HTML, CSS, JS for a static site         │
│  Data Lake         │  Big data files for analytics            │
└────────────────────┴──────────────────────────────────────────┘
```

### In This Framework

This Terraform framework uses storage for:

1. **Terraform state backend** — Stores `.tfstate` files so your team shares the same infrastructure state
2. **Application blob storage** — Your apps can store and retrieve files
3. **Log archives** — Long-term storage for diagnostic logs
4. **Backup storage** — Database and configuration backups

---

## Types of Azure Storage

Azure Storage accounts support several data services. This module focuses on **Blob Storage**, but here's the full picture:

```
Azure Storage Account
├── 📦 Blob Storage     ◄── This module focuses here
│   └── Store any file (images, videos, logs, backups)
│
├── 📁 File Storage
│   └── SMB/NFS file shares (like a network drive)
│
├── 📊 Table Storage
│   └── NoSQL key-value store (simple structured data)
│
├── 📨 Queue Storage
│   └── Message queues (async communication between apps)
│
└── 💿 Disk Storage
    └── Managed disks for VMs (handled separately in Azure)
```

### Blob Storage Concepts

```
Storage Account (the warehouse)
│
├── Container: "data"        (a folder/room)
│   ├── Blob: report.pdf     (a file)
│   ├── Blob: image.png      (a file)
│   └── Blob: data.csv       (a file)
│
├── Container: "logs"
│   ├── Blob: app-2026-01.log
│   └── Blob: app-2026-02.log
│
└── Container: "backups"
    └── Blob: db-backup-2026-02-11.bak
```

---

## Key Concepts Explained

### 1. Account Tiers

**What:** The performance level of your storage account.

```
Standard                          Premium
════════                          ═══════
Hard disk drives (HDD)            Solid state drives (SSD)
Lower cost                        Higher cost
Great for most workloads          Ultra-low latency needed
Backups, logs, general files      Real-time analytics, hot data

Recommendation: Use Standard for 99% of cases.
                Premium only for performance-critical workloads.
```

### 2. Replication Types

**What:** How many copies of your data Azure keeps, and where.

Think of it like making photocopies of important documents:

```
LRS (Locally Redundant)
════════════════════════
3 copies in ONE building (datacenter)

  ┌──────────────────────────┐
  │  Datacenter A            │
  │  ┌─────┐ ┌─────┐ ┌─────┐│
  │  │Copy1│ │Copy2│ │Copy3││
  │  └─────┘ └─────┘ └─────┘│
  └──────────────────────────┘

  ✅ Cheapest option
  ⚠️  If the building burns down, all copies lost
  👉 Use for: Dev/test environments


ZRS (Zone-Redundant)
════════════════════
3 copies across 3 DIFFERENT buildings (availability zones)

  ┌────────┐  ┌────────┐  ┌────────┐
  │ Zone 1 │  │ Zone 2 │  │ Zone 3 │
  │┌─────┐ │  │┌─────┐ │  │┌─────┐ │
  ││Copy1│ │  ││Copy2│ │  ││Copy3│ │
  │└─────┘ │  │└─────┘ │  │└─────┘ │
  └────────┘  └────────┘  └────────┘

  ✅ Survives a single building failure
  💰 Slightly more expensive than LRS
  👉 Use for: Staging, important data


GRS (Geo-Redundant)
═══════════════════
6 copies: 3 in Region A + 3 in Region B (hundreds of miles apart)

  Region A (Primary)             Region B (Secondary)
  ┌──────────────────┐           ┌──────────────────┐
  │ ┌───┐┌───┐┌───┐ │  ──────▶  │ ┌───┐┌───┐┌───┐ │
  │ │ 1 ││ 2 ││ 3 │ │  replicate│ │ 4 ││ 5 ││ 6 │ │
  │ └───┘└───┘└───┘ │           │ └───┘└───┘└───┘ │
  └──────────────────┘           └──────────────────┘

  ✅ Survives an entire region going down
  💰 More expensive
  👉 Use for: Production, critical business data


GZRS (Geo-Zone-Redundant)
═════════════════════════
Best of both: ZRS in primary region + GRS to secondary region

  Region A (3 zones)             Region B
  ┌──────┐┌──────┐┌──────┐      ┌──────────────────┐
  │Zone 1││Zone 2││Zone 3│ ───▶ │ ┌───┐┌───┐┌───┐ │
  │┌───┐ ││┌───┐ ││┌───┐ │      │ │ 4 ││ 5 ││ 6 │ │
  ││ 1 │ │││ 2 │ │││ 3 │ │      │ └───┘└───┘└───┘ │
  │└───┘ ││└───┘ ││└───┘ │      └──────────────────┘
  └──────┘└──────┘└──────┘

  ✅ Maximum durability and availability
  💰 Most expensive
  👉 Use for: Mission-critical, regulatory compliance
```

### 3. Network Rules (Firewall)

**What:** Controls WHO can access your storage account.

**Analogy:** Like a bouncer at a club with a guest list.

```
WITHOUT Network Rules:              WITH Network Rules:
═════════════════════               ══════════════════

  Internet ──────▶ Storage           Internet ───X──▶ Storage
  (anyone!)                          (blocked!)

  Your App ──────▶ Storage           Your App ──────▶ Storage
                                     (IP allowlisted)

  Hacker ────────▶ Storage           Hacker ────X──▶ Storage
  (also gets in!)                    (blocked!)

                                     Azure ─────────▶ Storage
                                     Services         (bypass)
```

**How it works in this module:**

```hcl
# Set default_action to "Deny" to block everything first
network_rules_default_action = "Deny"

# Then allow specific access:
network_rules_bypass     = ["AzureServices"]     # Azure services can still reach it
network_rules_ip_rules   = ["203.0.113.50"]      # Your office IP
network_rules_subnet_ids = [subnet_id]           # Your VNet subnet
```

When `network_rules_default_action` is left as `null` (the default), no firewall rules are created at all — the storage account is open to the internet. **Always set to `"Deny"` for production.**

### 4. Private Endpoints

**What:** A private IP address for your storage account inside your VNet. Traffic never leaves Microsoft's network backbone.

**Analogy:** Instead of sending mail through a public mailbox, you have a direct tunnel from your office to the warehouse.

```
WITHOUT Private Endpoint:
═════════════════════════
  Your App ──▶ [Public Internet] ──▶ mystorageaccount.blob.core.windows.net
                    ↑
             (travels over internet, even between Azure resources)


WITH Private Endpoint:
══════════════════════
  Your App ──▶ [Private Link / Microsoft Backbone] ──▶ 10.1.3.10
                    ↑                                     ↑
             (never leaves Azure network)         (private IP in your VNet)
```

**When to use:** Always in production. The storage account gets a private IP inside your subnet, and you can block all public access.

### 5. Blob Versioning

**What:** Azure automatically keeps a copy of every version of a blob when it's modified or deleted.

**Analogy:** Like Google Docs version history — you can always go back to any previous version.

```
File: report.pdf

  Version 1 (Jan 1) ──▶ Original upload
  Version 2 (Jan 15) ──▶ Updated charts
  Version 3 (Feb 1) ──▶ Final version
  Version 4 (Feb 10) ──▶ Oops, accidentally overwrote!

  ✅ You can restore Version 3 anytime!
```

### 6. Soft Delete

**What:** Deleted blobs and containers are kept for a retention period before being permanently removed.

**Analogy:** Like a recycling bin — you can recover items within the retention window.

```
Without Soft Delete:                With Soft Delete (7 days):
════════════════════                ══════════════════════════

  DELETE blob ──▶ Gone forever!     DELETE blob ──▶ Moved to "recycle bin"
                                                    │
                                    Day 1-7:        │ ◄── Can restore!
                                    Day 8+:         └──▶ Permanently deleted
```

### 7. Containers

**What:** Logical groupings inside a storage account. Like folders (but flat — no nested containers).

**Access types:**

```
┌──────────┬─────────────────────────────────────────────────┐
│ Type     │ Who Can Access                                  │
├──────────┼─────────────────────────────────────────────────┤
│ private  │ Only authenticated requests (DEFAULT — use this)│
│ blob     │ Anonymous read for blobs only                   │
│ container│ Anonymous read for containers and blobs         │
└──────────┴─────────────────────────────────────────────────┘

⚠️  Almost always use "private". Public access is rare and risky.
```

---

## How Storage Fits in the Framework

```
┌────────────────────────────────────────────────────────────────────────┐
│                        Your Azure Environment                         │
│                                                                        │
│   ┌───────────────────────────────────────────────────────────────┐    │
│   │  Landing Zone (Resource Group + Base Config)                  │    │
│   │                                                               │    │
│   │   ┌─────────┐    ┌─────────┐    ┌──────────────────────┐    │    │
│   │   │ Networking│    │ Security │    │ Storage Module       │    │    │
│   │   │ Module   │    │ Module   │    │ ═══════════════      │    │    │
│   │   │          │    │          │    │                      │    │    │
│   │   │ • VNet   │    │ • Key    │    │ • Storage Account    │    │    │
│   │   │ • Subnets│──▶ │   Vault  │    │ • Containers         │    │    │
│   │   │ • NSGs   │    │ • Log    │──▶ │ • Diagnostics        │    │    │
│   │   │          │    │   Analytics    │ • Private Endpoint   │    │    │
│   │   └─────────┘    └─────────┘    └──────────────────────┘    │    │
│   │        │                                    │                │    │
│   │        │           ┌────────────────┐       │                │    │
│   │        └──────────▶│ Private Endpoint│◀──────┘               │    │
│   │                    │ (blob access    │                        │    │
│   │                    │  via VNet)      │                        │    │
│   │                    └────────────────┘                        │    │
│   │                                                               │    │
│   │   ┌─────────────┐    ┌──────────────┐                        │    │
│   │   │ AKS / Apps  │──▶ │ Storage      │  (apps read/write     │    │
│   │   │             │    │ Containers   │   blobs via private    │    │
│   │   └─────────────┘    └──────────────┘   endpoint)            │    │
│   └───────────────────────────────────────────────────────────────┘    │
└────────────────────────────────────────────────────────────────────────┘
```

**Data flow:**

```
1. Networking module creates VNet + subnets
2. Security module creates Log Analytics + Key Vault
3. Storage module creates:
   a. Storage account (in resource group)
   b. Containers (for organizing blobs)
   c. Private endpoint (connects to subnet from networking module)
   d. Diagnostics (sends metrics to Log Analytics from security module)
4. Apps (AKS, Container Apps) access storage via private endpoint
```

---

## Environment Comparison

```
┌───────────────────────┬──────────────┬──────────────┬──────────────┐
│ Setting               │ Dev          │ Staging      │ Production   │
├───────────────────────┼──────────────┼──────────────┼──────────────┤
│ Replication           │ LRS          │ ZRS          │ GRS / GZRS   │
│ Network Firewall      │ Off (null)   │ Deny         │ Deny         │
│ Private Endpoint      │ No           │ Yes          │ Yes          │
│ Blob Versioning       │ No           │ Yes          │ Yes          │
│ Change Feed           │ No           │ No           │ Yes          │
│ Soft Delete (days)    │ 7            │ 14           │ 90           │
│ Diagnostics           │ Optional     │ Yes          │ Yes          │
│ Public Blob Access    │ No           │ No           │ No           │
└───────────────────────┴──────────────┴──────────────┴──────────────┘
```

---

## Cost Estimates

> Estimates for **East US** region, Standard tier, 100 GB stored. Actual costs vary by usage patterns.

```
┌──────────────────────┬──────────────┬──────────────┬──────────────┐
│ Component            │ Dev (LRS)    │ Staging (ZRS)│ Prod (GRS)   │
├──────────────────────┼──────────────┼──────────────┼──────────────┤
│ Storage (100 GB)     │ ~$1.80/mo    │ ~$2.50/mo    │ ~$4.10/mo    │
│ Transactions (10k)   │ ~$0.05/mo    │ ~$0.05/mo    │ ~$0.10/mo    │
│ Private Endpoint     │ —            │ ~$7.30/mo    │ ~$7.30/mo    │
│ Diagnostics          │ —            │ minimal      │ minimal      │
├──────────────────────┼──────────────┼──────────────┼──────────────┤
│ Estimated Total      │ ~$2/mo       │ ~$10/mo      │ ~$12/mo      │
└──────────────────────┴──────────────┴──────────────┴──────────────┘

💡 Storage is one of the cheapest Azure services. Even production-grade
   storage with geo-redundancy and private endpoints is very affordable.
```

---

## What This Module Creates (Step by Step)

Here's exactly what happens when Terraform applies this module:

```
Step 1: Create Storage Account
───────────────────────────────
  → azurerm_storage_account.storage
  → Sets tier, replication, TLS 1.2, HTTPS-only
  → Creates system-assigned managed identity
  → Applies network rules (if configured)
  → Configures blob properties (versioning, soft delete)

Step 2: Create Containers (if any defined)
──────────────────────────────────────────
  → azurerm_storage_container.containers["data"]
  → azurerm_storage_container.containers["logs"]
  → Each with its own access_type (default: "private")

Step 3: Create Diagnostics (if log_analytics_workspace_id provided)
──────────────────────────────────────────────────────────────────
  → azurerm_monitor_diagnostic_setting.storage_diagnostics
  → Sends Transaction metrics to Log Analytics

Step 4: Create Private Endpoint (if enable_private_endpoint = true)
─────────────────────────────────────────────────────────────────
  → azurerm_private_endpoint.storage_endpoint
  → Connects to blob subresource
  → Places endpoint in specified subnet
  → Storage account gets a private IP in your VNet
```

---

## Common Questions

### "Do I really need a storage account?"

**Yes, almost certainly.** Even if your app doesn't store files directly, you likely need storage for:
- Terraform state files (the backend for this framework)
- Application logs
- Database backups
- Temporary data processing

### "What's the difference between a container and a blob?"

A **container** is like a folder. A **blob** is a file inside that folder. You can't nest containers (no sub-folders), but blob names can include `/` to simulate a folder structure (e.g., `2026/02/report.pdf`).

### "Should I use access keys or managed identity?"

**Managed identity** whenever possible. This module creates a system-assigned identity automatically. Use Azure RBAC roles like `Storage Blob Data Contributor` instead of passing access keys around. Keys are exported as outputs for backward compatibility but prefer RBAC.

### "What if I accidentally delete a blob?"

If **soft delete** is enabled (default: 7 days), you can recover it within the retention window. If **versioning** is enabled, previous versions are preserved even after overwrite. These features are your safety net.

### "Why is my storage account name rejected?"

Storage account names must be:
- **3-24 characters long**
- **Lowercase letters and numbers only** (no hyphens, underscores, or uppercase)
- **Globally unique** across ALL of Azure

This is an Azure limitation, not a module restriction. The module validates this pattern: `^[a-z0-9]{3,24}$`

### "LRS, GRS, ZRS — which one do I pick?"

```
Just learning / dev?     → LRS  (cheapest, single datacenter)
Staging / important?     → ZRS  (3 availability zones, same region)
Production / critical?   → GRS  (replicated to a second region)
Maximum protection?      → GZRS (zones + geo-replication)
```

### "What does 'bypass AzureServices' mean?"

When you set network rules to `Deny`, you block ALL traffic — including other Azure services like Azure Monitor, Azure Backup, etc. Setting `bypass = ["AzureServices"]` creates an exception so trusted Azure services can still reach your storage account.

### "Can I change replication type later?"

Yes! You can change between most replication types without recreating the storage account. However, changing from LRS/GRS to ZRS/GZRS requires a **live migration** or a manual data copy. Plan your replication strategy early.

### "How do containers relate to Terraform state?"

This framework stores Terraform state in a separate storage account (configured in `backend.tf`). The storage module documented here creates storage for your **application workloads**, not for the Terraform backend itself. They are separate concerns.

---

## Quick Reference

```
Module Path:    infra/modules/storage/
Main Resource:  azurerm_storage_account
Provider:       azurerm (hashicorp/azurerm)

Key Files:
  main.tf       → Resource definitions (account, containers, endpoint, diagnostics)
  variables.tf  → Input variables with validation and defaults
  outputs.tf    → Output values (IDs, keys, endpoints, identity)
  README.md     → Technical reference and usage examples
  HOW-IT-WORKS.md → This file (beginner guide)
```

---

## Next Steps

1. **Read the README** — For exact variable names, outputs, and usage examples
2. **Check the networking module** — Storage private endpoints need a subnet
3. **Check the security module** — Diagnostics need a Log Analytics workspace
4. **Look at environment configs** — See `infra/envs/dev/`, `staging/`, `prod/` for real usage
5. **Review naming conventions** — See `infra/modules/_shared/naming.tf` for the naming standard
