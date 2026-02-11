# PostgreSQL Flexible Server - How It Works

A beginner-friendly guide to Azure Database for PostgreSQL Flexible Server. No database experience required!

---

## What is PostgreSQL?

**Simple explanation:** PostgreSQL (often called "Postgres") is like a super-organized filing system for your application's data. It stores information in tables (like spreadsheets) and lets you ask complex questions about that data instantly.

**Azure Database for PostgreSQL Flexible Server** is Microsoft's fully managed version — Azure handles the backups, patching, security updates, and hardware so you can focus on your application.

```
Self-Managed PostgreSQL:          Azure Flexible Server:
─────────────────────────         ─────────────────────────
You install PostgreSQL            Azure installs it for you
You patch & update it             Azure patches automatically
You manage backups                Azure backs up automatically
You handle failover               Azure handles HA failover
You buy/rent servers              Azure scales compute for you
You configure firewalls           Azure integrates with VNet
```

### Real-World Analogy

Think of PostgreSQL Flexible Server like renting a safety deposit box at a bank:

| Concept | Safety Deposit Box | PostgreSQL Flexible Server |
|---------|-------------------|---------------------------|
| **The service** | The bank vault | Azure's managed PostgreSQL service |
| **Your data** | Your valuables in the box | Your tables, rows, and columns |
| **Server name** | Your box number | Globally unique server identifier |
| **Admin credentials** | Your vault key | Username + password to connect |
| **Backups** | Bank's insurance policy | Automatic daily backups (7-35 days) |
| **HA (failover)** | Backup vault at another branch | Standby server in another zone |
| **VNet integration** | Private entrance to the vault | Only apps on your network can connect |

---

## Why PostgreSQL vs SQL Server vs Cosmos DB?

This is one of the most common questions. Here's when to use each:

```
┌──────────────────────────────────────────────────────────────────────┐
│                    WHICH DATABASE SHOULD I USE?                       │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  PostgreSQL Flexible Server        Azure SQL Database                │
│  ─────────────────────────         ──────────────────                │
│  ✓ Open source (no license $)     ✓ Microsoft ecosystem             │
│  ✓ JSON + relational hybrid       ✓ .NET / C# apps                  │
│  ✓ Complex queries, analytics     ✓ Enterprise features             │
│  ✓ GIS/geospatial (PostGIS)       ✓ SSRS, SSIS integration         │
│  ✓ Extensions ecosystem           ✓ Easy migration from on-prem SQL │
│  ✓ Linux-native workloads         ✓ Windows-native workloads        │
│                                                                      │
│  Cosmos DB                                                           │
│  ─────────                                                           │
│  ✓ Global distribution (multi-region writes)                         │
│  ✓ Millisecond reads at any scale                                    │
│  ✓ Schema-free / document store                                      │
│  ✓ IoT, real-time, chat, catalogs                                    │
│  ✓ Multiple APIs (SQL, MongoDB, Cassandra, Gremlin)                  │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

**Rule of thumb:**
- **PostgreSQL** → Structured relational data, complex queries, analytics, open-source preference
- **Azure SQL** → Microsoft/.NET shop, migrating from SQL Server
- **Cosmos DB** → Global scale, document data, sub-10ms reads, IoT/chat/real-time

---

## Key Concepts (Plain English)

### 1. Flexible Server

The actual PostgreSQL instance running in Azure. "Flexible" means you choose the compute tier, storage, HA mode, and maintenance window — Azure manages everything else.

```
┌──────────────────────────────────────────────────────────────────────┐
│                     FLEXIBLE SERVER                                   │
│                                                                      │
│   Server Name: myproject-pg-prod                                     │
│   FQDN:        myproject-pg-prod.postgres.database.azure.com         │
│   Version:     PostgreSQL 16                                         │
│   Region:      East US                                               │
│                                                                      │
│   ┌──────────────┐  ┌──────────────┐  ┌──────────────┐              │
│   │  Database:    │  │  Database:    │  │  Database:    │              │
│   │  app-db       │  │  analytics   │  │  audit-db     │              │
│   │              │  │              │  │              │              │
│   │  Tables:     │  │  Tables:     │  │  Tables:     │              │
│   │  - users     │  │  - events    │  │  - log_entry │              │
│   │  - orders    │  │  - metrics   │  │  - changes   │              │
│   │  - products  │  │  - reports   │  │              │              │
│   └──────────────┘  └──────────────┘  └──────────────┘              │
│                                                                      │
│   Config: shared_buffers=524288, work_mem=32768                      │
│   Auth:   Azure AD + Password                                        │
│   HA:     ZoneRedundant (Zone 1 → Zone 2)                            │
└──────────────────────────────────────────────────────────────────────┘
```

### 2. SKU Tiers — Choosing the Right Size

SKU (Stock Keeping Unit) is Azure's way of describing the server size. Think of it like choosing a car:

```
┌─────────────────────────────────────────────────────────────────────┐
│                        SKU TIERS                                     │
│                                                                      │
│   BURSTABLE (B_)              Like a city scooter                    │
│   ─────────────               ───────────────────                    │
│   B_Standard_B1ms  1 vCPU, 2GB    Great for dev/test                │
│   B_Standard_B2s   2 vCPU, 4GB    Light production workloads        │
│                                                                      │
│   Pros: Cheapest option, can burst above baseline                    │
│   Cons: No HA support, limited sustained performance                 │
│   Best for: Development, testing, personal projects                  │
│                                                                      │
│   ─────────────────────────────────────────────────────────────────  │
│                                                                      │
│   GENERAL PURPOSE (GP_)       Like a family sedan                    │
│   ─────────────────────       ───────────────────                    │
│   GP_Standard_D2s_v3   2 vCPU,  8GB    Standard production          │
│   GP_Standard_D4s_v3   4 vCPU, 16GB    Medium production            │
│   GP_Standard_D8s_v3   8 vCPU, 32GB    Large production             │
│                                                                      │
│   Pros: Balanced performance, supports HA, predictable               │
│   Cons: More expensive than Burstable                                │
│   Best for: Most production workloads                                │
│                                                                      │
│   ─────────────────────────────────────────────────────────────────  │
│                                                                      │
│   MEMORY OPTIMIZED (MO_)      Like a heavy-duty truck               │
│   ──────────────────────      ──────────────────────                 │
│   MO_Standard_E4s_v3   4 vCPU, 32GB    Memory-heavy queries         │
│   MO_Standard_E8s_v3   8 vCPU, 64GB    Large caches, analytics      │
│                                                                      │
│   Pros: Massive memory, great for caching and analytics              │
│   Cons: Most expensive tier                                          │
│   Best for: Analytics, large datasets, in-memory caching             │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### 3. High Availability (HA) Modes

HA ensures your database keeps running even when hardware fails. Think of it like having a backup generator for your house.

```
NO HA (high_availability_mode = null)
─────────────────────────────────────
   ┌──────────────┐
   │   PRIMARY     │     If this server goes down,
   │   Zone 1      │     you wait for Azure to repair it.
   │   (your DB)   │     Downtime: minutes to hours.
   └──────────────┘


SAME ZONE HA (high_availability_mode = "SameZone")
──────────────────────────────────────────────────
   ┌──────────────┐     ┌──────────────┐
   │   PRIMARY     │ ──► │   STANDBY     │     Both in same zone.
   │   Zone 1      │     │   Zone 1      │     If primary fails,
   │   (active)    │     │   (passive)   │     standby takes over.
   └──────────────┘     └──────────────┘     Failover: ~60-120s
                                              Protects: server failure
                                              Doesn't protect: zone failure


ZONE REDUNDANT HA (high_availability_mode = "ZoneRedundant")
────────────────────────────────────────────────────────────
   ┌──────────────┐     ┌──────────────┐
   │   PRIMARY     │ ──► │   STANDBY     │     Different zones!
   │   Zone 1      │     │   Zone 2      │     If entire Zone 1
   │   (active)    │     │   (passive)   │     goes down, Zone 2
   └──────────────┘     └──────────────┘     standby takes over.
                                              Failover: ~60-120s
                                              Protects: server + zone failure
                                              RECOMMENDED for production
```

**HA Failover — What Actually Happens:**

```
Normal Operation:
   App ──► DNS (myapp-pg.postgres.database.azure.com) ──► Primary (Zone 1)

Primary Fails:
   1. Azure detects failure
   2. Standby promoted to primary
   3. DNS updated to point to new primary
   4. App reconnects automatically (same FQDN!)

After Failover:
   App ──► DNS (same address!) ──► Former Standby (Zone 2, now primary)
   
   Meanwhile: Azure provisions a new standby
```

### 4. VNet Integration via Delegated Subnet

This is how you make your database private — only accessible from your Virtual Network. No public internet access.

```
WITHOUT VNet Integration (public access):
──────────────────────────────────────────

   Internet ──► Firewall Rules ──► PostgreSQL Server
   
   Anyone with the right IP can attempt to connect.
   Protected by: firewall rules + username/password.
   Used for: development, quick testing.


WITH VNet Integration (private access):
───────────────────────────────────────

   ┌─────────────────────────────────────────────────────┐
   │                    Virtual Network                    │
   │                    10.0.0.0/16                        │
   │                                                       │
   │   ┌──────────────────┐    ┌────────────────────────┐ │
   │   │  App Subnet       │    │  Delegated PG Subnet   │ │
   │   │  10.0.1.0/24      │    │  10.0.4.0/24           │ │
   │   │                   │    │                         │ │
   │   │  ┌─────────┐     │    │  ┌──────────────────┐  │ │
   │   │  │ Your App │─────┼────┼─►│ PostgreSQL Server │  │ │
   │   │  └─────────┘     │    │  └──────────────────┘  │ │
   │   └──────────────────┘    └────────────────────────┘ │
   │                                                       │
   │   ┌──────────────────────────────────────────────┐   │
   │   │  Private DNS Zone                              │   │
   │   │  *.postgres.database.azure.com                 │   │
   │   │  Resolves server FQDN to private IP            │   │
   │   └──────────────────────────────────────────────┘   │
   └─────────────────────────────────────────────────────┘
   
   ✗ Internet CANNOT reach PostgreSQL
   ✓ Only apps inside the VNet (or peered VNets) can connect
   Used for: staging, production — ALWAYS recommended.
```

**What is a "delegated subnet"?**
A delegated subnet is a subnet you hand over to a specific Azure service. You're saying: "Only PostgreSQL Flexible Servers can use IP addresses in this subnet." This is required for VNet integration.

**What is a "private DNS zone"?**
When your app connects to `myapp-pg.postgres.database.azure.com`, DNS needs to resolve that to a private IP (like `10.0.4.5`) instead of a public IP. The private DNS zone handles this translation inside your VNet.

### 5. Server Configurations

PostgreSQL has hundreds of tunable parameters. This module lets you set them via the `server_configurations` map. Think of these like settings on a car's dashboard:

```
┌─────────────────────────────────────────────────────────────────┐
│                PostgreSQL Tuning Parameters                      │
│                                                                  │
│   shared_buffers                                                 │
│   ─────────────                                                  │
│   How much memory PostgreSQL uses for caching data.              │
│   Like: How big is the engine's turbo cache.                     │
│   Rule: Set to ~25% of total server RAM.                         │
│                                                                  │
│   work_mem                                                       │
│   ────────                                                       │
│   Memory for each sort/hash operation in a query.                │
│   Like: Size of the workspace for each mechanic.                 │
│   Warning: Multiplied by concurrent queries! Don't set too high. │
│                                                                  │
│   effective_cache_size                                            │
│   ────────────────────                                           │
│   Tells the query planner how much cache is available.           │
│   Like: Telling the GPS how much fuel you have.                  │
│   Rule: Set to ~75% of total server RAM.                         │
│                                                                  │
│   log_min_duration_statement                                     │
│   ──────────────────────────                                     │
│   Log any query that takes longer than N milliseconds.           │
│   Like: A speed camera for slow queries.                         │
│   Tip: Set to 1000ms (1 second) to catch slow queries.          │
│                                                                  │
│   idle_in_transaction_session_timeout                             │
│   ─────────────────────────────────────                          │
│   Kill connections that sit idle inside an open transaction.     │
│   Like: Auto-closing a door someone left open.                   │
│   Tip: Set to 60000ms (60 seconds) in production.               │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 6. Firewall Rules

Firewall rules only apply when `public_network_access_enabled = true`. They control which IP addresses can connect to your server from the internet.

```
Firewall rules are like a guest list at a party:
    
   ┌──────────────────────────────┐
   │        Firewall Rules         │
   │                               │
   │  "allow-office"               │
   │   203.0.113.0 → 203.0.113.255│   ← Office IP range: ALLOWED
   │                               │   
   │  "allow-vpn"                  │
   │   198.51.100.10 → same        │   ← VPN exit IP: ALLOWED
   │                               │
   │  Everything else              │   ← BLOCKED
   └──────────────────────────────┘
   
   NOTE: When using VNet integration, you don't need firewall rules
         because there's no public endpoint to protect.
```

### 7. Authentication

This module supports two authentication methods that can be used together or separately:

```
PASSWORD AUTHENTICATION (traditional):
   App ──► username + password ──► PostgreSQL Server
   
   Simple, works with every PostgreSQL client.
   Default: enabled (password_auth_enabled = true)

AZURE AD AUTHENTICATION:
   App ──► Azure AD token ──► PostgreSQL Server
   
   Uses Microsoft Entra ID (formerly Azure AD) identities.
   No passwords to manage or rotate.
   Supports managed identities for apps.
   Default: disabled (aad_auth_enabled = false)
   Requires: tenant_id to be set

RECOMMENDED COMBINATIONS:
   Dev:     password only (simple)
   Staging: password + AAD (testing both)
   Prod:    AAD only (most secure, no passwords)
```

---

## What This Module Creates — Step by Step

Here's what happens when Terraform runs this module:

```
Step 1: Create Flexible Server
         ↓
         azurerm_postgresql_flexible_server
         - Sets version, SKU, storage, backup settings
         - Configures VNet integration (if delegated_subnet_id set)
         - Configures HA mode (if high_availability_mode set)
         - Sets authentication mode (password, AAD, or both)

Step 2: Create Databases (for each entry in var.databases)
         ↓
         azurerm_postgresql_flexible_server_database
         - Creates database with specified charset and collation
         - Default: UTF8 / en_US.utf8

Step 3: Apply Server Configurations (for each entry in var.server_configurations)
         ↓
         azurerm_postgresql_flexible_server_configuration
         - Sets PostgreSQL parameters (shared_buffers, work_mem, etc.)

Step 4: Create Firewall Rules (only if public_network_access_enabled = true)
         ↓
         azurerm_postgresql_flexible_server_firewall_rule
         - Adds IP-based access rules
         - Skipped entirely when using VNet integration

Step 5: Enable Diagnostics (only if log_analytics_workspace_id is set)
         ↓
         azurerm_monitor_diagnostic_setting
         - Sends PostgreSQLLogs to Log Analytics
         - Sends AllMetrics to Log Analytics
```

---

## Environment Comparison

Here's how the same module is configured differently across environments:

```
┌───────────────┬──────────────────┬──────────────────┬──────────────────────┐
│   Setting      │   Development    │    Staging        │    Production        │
├───────────────┼──────────────────┼──────────────────┼──────────────────────┤
│ SKU           │ B_Standard_B1ms  │ GP_Standard_D2s  │ GP_Standard_D4s+     │
│ vCPU / RAM    │ 1 vCPU / 2 GB   │ 2 vCPU / 8 GB   │ 4+ vCPU / 16+ GB    │
│ Storage       │ 32 GB           │ 64 GB            │ 128 GB+              │
│ HA Mode       │ None            │ SameZone         │ ZoneRedundant        │
│ Backup Days   │ 7               │ 14               │ 35                   │
│ Geo Backup    │ No              │ No               │ Yes                  │
│ Network       │ Public + FW     │ VNet (private)   │ VNet (private)       │
│ Auth          │ Password        │ Password + AAD   │ AAD only             │
│ Diagnostics   │ Optional        │ Yes              │ Yes                  │
│ Databases     │ 1               │ 1-2              │ Multiple             │
│ Tuning        │ Defaults        │ Some tuning      │ Full tuning          │
└───────────────┴──────────────────┴──────────────────┴──────────────────────┘
```

---

## Cost Estimates

Approximate monthly costs for East US (prices vary by region and change over time):

```
┌─────────────────────────────────────────────────────────────────────┐
│                    ESTIMATED MONTHLY COSTS                            │
│                    (East US, pay-as-you-go)                           │
│                                                                      │
│   DEVELOPMENT                                                        │
│   B_Standard_B1ms + 32GB storage                                     │
│   Compute: ~$12/month                                                │
│   Storage:  ~$4/month                                                │
│   Total:   ~$16/month                                                │
│                                                                      │
│   ─────────────────────────────────────────────────────────────────  │
│                                                                      │
│   STAGING                                                            │
│   GP_Standard_D2s_v3 + 64GB + SameZone HA                           │
│   Compute: ~$125/month (×2 for HA = ~$250)                          │
│   Storage:  ~$8/month                                                │
│   Total:   ~$258/month                                               │
│                                                                      │
│   ─────────────────────────────────────────────────────────────────  │
│                                                                      │
│   PRODUCTION                                                         │
│   GP_Standard_D4s_v3 + 128GB + ZoneRedundant HA + Geo Backup        │
│   Compute: ~$250/month (×2 for HA = ~$500)                          │
│   Storage:  ~$15/month + geo-backup ~$8/month                        │
│   Total:   ~$523/month                                               │
│                                                                      │
│   NOTE: These are estimates. Use the Azure Pricing Calculator        │
│   for exact numbers: https://azure.microsoft.com/pricing/calculator  │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## How Backups Work

```
AUTOMATIC BACKUPS:
   Azure takes daily full backups automatically.
   You choose retention: 7 to 35 days.

   Day 1   Day 2   Day 3   ...   Day 35
   [Full]  [Full]  [Full]  ...   [Full]
    └───────────────────────────────┘
           Point-in-time restore
           to ANY second within window

GEO-REDUNDANT BACKUPS (geo_redundant_backup_enabled = true):
   Copies backups to a paired Azure region.
   
   East US (primary)          West US (paired region)
   ┌──────────────┐           ┌──────────────┐
   │  Daily Backup │ ────────► │  Backup Copy  │
   └──────────────┘           └──────────────┘
   
   If entire East US region goes down, you can
   restore from the West US backup copy.
   
   IMPORTANT: Can only be set at server creation time!
              Cannot be changed later.
```

---

## Common Questions

### Q: Can I connect to this from my local machine?

**If public access is enabled:** Yes, add your IP to the firewall rules.

**If VNet integrated:** Not directly. Options:
1. Use a VPN Gateway to connect your machine to the VNet
2. Use Azure Bastion to jump into a VM on the VNet
3. Use Azure Cloud Shell with VNet integration

### Q: How do I connect from my application?

Use the `server_fqdn` output as the hostname:
```
Host:     <server_name>.postgres.database.azure.com
Port:     5432
Database: <your-database-name>
SSL:      Required (Azure enforces this)
```

### Q: Can I change the SKU later?

Yes! You can scale up or down at any time. There will be a brief restart (~30 seconds to a few minutes). Plan for a maintenance window.

### Q: Can I increase storage later?

Yes, but you **cannot decrease it**. Storage is grow-only. Start with a reasonable amount and scale up as needed.

### Q: What happens during an HA failover?

Existing connections are dropped. Your app needs to reconnect (most connection pools handle this automatically). The FQDN stays the same — it simply resolves to the new primary. Expect ~60-120 seconds of downtime.

### Q: Should I use Burstable for production?

Generally no. Burstable SKUs:
- Don't support high availability
- Have variable performance (they "burst" above baseline but throttle after)
- Are designed for intermittent workloads

Use General Purpose (`GP_`) for production.

### Q: How many databases can I create on one server?

Technically many, but the recommended practice is to keep related databases on the same server and separate unrelated workloads onto different servers. The module supports creating multiple databases via the `databases` map.

### Q: What PostgreSQL extensions are available?

Azure PostgreSQL Flexible Server supports many popular extensions including:
- `pg_stat_statements` — Query performance tracking
- `postgis` — Geospatial data
- `pg_trgm` — Text search
- `uuid-ossp` — UUID generation
- `pgcrypto` — Cryptographic functions

Enable them by adding them to `server_configurations` or running `CREATE EXTENSION` in your database.

### Q: Why can't I delete and recreate with different geo-backup settings?

The `geo_redundant_backup_enabled` flag is set at creation time and cannot be changed. If you need to change it, you must:
1. Export your data (pg_dump)
2. Destroy the server (`terraform destroy -target=...`)
3. Recreate with the new setting
4. Import your data (pg_restore)

---

## Related Modules

| Module | Relationship |
|--------|-------------|
| [`networking`](../networking/README.md) | Creates VNet and delegated subnets for private access |
| [`security`](../security/README.md) | Key Vault for storing admin credentials |
| [`landing-zone`](../landing-zone/README.md) | Resource group and base infrastructure |
| [`cosmosdb`](../cosmosdb/README.md) | Alternative database for document/global workloads |
| [`sql-database`](../sql-database/README.md) | Alternative database for Microsoft SQL workloads |

---

## Further Reading

- [Azure PostgreSQL Flexible Server Overview](https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/overview)
- [Choosing Between Database Services](https://learn.microsoft.com/en-us/azure/architecture/guide/technology-choices/data-store-overview)
- [PostgreSQL Flexible Server Pricing](https://azure.microsoft.com/en-us/pricing/details/postgresql/flexible-server/)
- [High Availability Architecture](https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/concepts-high-availability)
