# SQL Database Module - How It Works

A beginner-friendly guide to Azure SQL Database. Learn how to store, query, and protect your structured data!

---

## What is Azure SQL Database?

**Simple explanation:** Azure SQL Database is like a massive, organized filing cabinet in the cloud. Instead of folders and papers, you have tables and rows. You store data in a structured way so you can find exactly what you need, fast.

```
Without a database:                With Azure SQL Database:
───────────────────                ─────────────────────────
Data in flat files:                Data in structured tables:
  users.csv                          Users Table
  orders.csv                         ┌────┬──────────┬──────────┐
  products.csv                       │ ID │ Name     │ Email    │
                                     ├────┼──────────┼──────────┤
Problems:                            │ 1  │ Alice    │ a@co.com │
- Can't search efficiently           │ 2  │ Bob      │ b@co.com │
- No relationships                   └────┴──────────┴──────────┘
- No access control
- Data can get corrupted          Benefits:
- Hard to handle concurrency      - Lightning-fast queries
                                  - Relationships between tables
                                  - Fine-grained access control
                                  - ACID transactions
                                  - Automatic backups
```

---

## Why Do You Need It?

### The Problem with Unstructured Data

```
Scenario: E-commerce application

BAD: Data in files or blobs
─────────────────────────────
orders.json (500 MB, growing daily)
├── "Find all orders by user #1234"     → Scan entire file!  (slow)
├── "Find orders from last 24 hours"    → Scan entire file!  (slow)
├── "Update order #9999 status"         → Rewrite entire file! (risky)
└── "Two users editing at same time"    → Data corruption!    (broken)
```

```
GOOD: Data in SQL Database
────────────────────────────
Orders Table (indexed, optimized)
├── "Find all orders by user #1234"     → Index lookup   (milliseconds!)
├── "Find orders from last 24 hours"    → Index lookup   (milliseconds!)
├── "Update order #9999 status"         → Single row update (safe!)
└── "Two users editing at same time"    → Transactions   (both succeed!)
```

### When to Use SQL Database vs Cosmos DB

```
Choose SQL Database when:               Choose Cosmos DB when:
─────────────────────────                ──────────────────────
✅ Structured, relational data          ✅ Semi-structured / document data
✅ Complex queries with JOINs           ✅ Simple key-value lookups
✅ ACID transactions                    ✅ Global distribution needed
✅ Existing SQL skills / apps           ✅ Massive write throughput
✅ Reporting and analytics              ✅ Flexible / evolving schemas
✅ Legacy app migration                 ✅ Chat history, AI context

Examples:                                Examples:
- Order management system               - User profiles (flexible fields)
- Financial transactions                 - IoT telemetry data
- Inventory management                   - Product catalog (varied schemas)
- Employee/HR databases                  - Session/chat storage
- CRM systems                           - Real-time recommendations
```

**Rule of thumb:** If your data fits naturally into rows and columns with defined relationships, SQL Database is your best bet.

---

## Key Concepts (Plain English)

### 1. SQL Server (The Building)

Think of the SQL Server as the **office building**. It's the main container that holds all your databases.

```
Azure SQL Server: myapp-sql-prod-001.database.windows.net
├── It's the "address" where your databases live
├── Has its own security (firewall, Azure AD)
├── Has a system-assigned identity (like an employee badge)
└── All databases inside share the same server settings
```

### 2. Databases (The Rooms)

Each database is like a **room** inside the building, with its own data and settings.

```
SQL Server: myapp-sql-prod-001
│
├── Database: app-db (SKU: P1, 256 GB)
│   ├── Table: Users
│   ├── Table: Orders
│   └── Table: Products
│
├── Database: analytics-db (SKU: S1, 50 GB)
│   ├── Table: PageViews
│   └── Table: Events
│
└── Database: audit-db (SKU: S0, 10 GB)
    └── Table: AuditLogs
```

### 3. SKUs (Room Sizes)

The SKU determines how powerful and expensive your database is. Think of it as choosing the **size and quality of the room**.

```
SKU Tiers:
──────────

Basic         → Small closet. Cheap, limited.
                 2 GB max, 5 DTUs. ~$5/month.
                 Good for: Dev/test, tiny apps

Standard      → Regular office. Balanced.
  S0 (10 DTU) → ~$15/month.  Good for: Small apps
  S1 (20 DTU) → ~$30/month.  Good for: Medium apps
  S2 (50 DTU) → ~$75/month.  Good for: Growing apps
  S3 (100 DTU)→ ~$150/month. Good for: Busy apps

Premium       → Corner office with a view. Powerful!
  P1 (125 DTU)→ ~$465/month.  Zone redundant, read scale
  P2 (250 DTU)→ ~$930/month.  More power
  P4 (500 DTU)→ ~$1,860/month. Heavy workloads

vCore         → Custom-built room. You choose CPU & RAM.
  GP_Gen5_2   → ~$200/month.  Flexible, general purpose
  BC_Gen5_2   → ~$600/month.  Business critical, in-memory
```

**DTU** = Database Transaction Unit. A blended measure of CPU, memory, and IO. Higher DTU = faster database.

### 4. Firewall Rules (The Security Guard)

Firewall rules control **who can reach** your SQL Server over the network.

```
┌─────────────────────────────────────────────────────────────────┐
│                     SQL SERVER FIREWALL                          │
│                                                                  │
│   Rules:                                                         │
│   ✅ "dev-office"     → 203.0.113.0 - 203.0.113.255 (allowed) │
│   ✅ "ci-cd-server"   → 10.0.1.50 - 10.0.1.50       (allowed) │
│   ✅ "AllowAzureIPs"  → 0.0.0.0 - 0.0.0.0           (Azure)  │
│   ❌ Everything else   → BLOCKED                                │
│                                                                  │
│   Hacker from 185.X.X.X → DENIED!                              │
│   Developer from 203.0.113.10 → ALLOWED                        │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 5. VNet Rules (The Private Corridor)

VNet rules let specific **Azure subnets** connect to your SQL Server, like a private corridor between buildings.

```
┌──────────────────────────────────────────────────────────────────┐
│                          YOUR VNET                                │
│                                                                   │
│  ┌─────────────┐   VNet Rule   ┌────────────────────────────┐   │
│  │  AKS Subnet │ ────────────→ │     SQL Server             │   │
│  │ 10.1.1.0/24 │               │                            │   │
│  └─────────────┘               │  "Only these subnets       │   │
│                                │   can talk to me"           │   │
│  ┌─────────────┐   VNet Rule   │                            │   │
│  │  App Subnet │ ────────────→ │                            │   │
│  │ 10.1.2.0/24 │               └────────────────────────────┘   │
│  └─────────────┘                                                  │
│                                                                   │
│  ┌─────────────┐                                                 │
│  │  Web Subnet │ ──── ✗ ──── No rule = No access!               │
│  │ 10.1.3.0/24 │                                                 │
│  └─────────────┘                                                 │
│                                                                   │
└──────────────────────────────────────────────────────────────────┘
```

### 6. Private Endpoint (The Secret Tunnel)

A private endpoint gives your SQL Server a **private IP address** inside your VNet. No public internet involved!

```
WITHOUT Private Endpoint:                WITH Private Endpoint:
─────────────────────────                ──────────────────────

App ──→ Internet ──→ SQL Server          App ──→ Private IP ──→ SQL Server
         (public IP)                            (10.1.3.100)

Risk: Traffic goes over public           Benefit: Traffic stays in your
      internet, IP exposed                        private network, no
                                                  public exposure at all!

┌─────────────────────────────────────────────────────────────────┐
│                         YOUR VNET                                │
│                                                                  │
│   ┌─────────────┐          ┌────────────────────────────────┐  │
│   │   Your App  │ ───────→ │  SQL Server (Private Endpoint) │  │
│   │ 10.1.1.50   │  Port    │  10.1.3.100                    │  │
│   └─────────────┘  1433    │                                │  │
│                            │  Private IP, no public access! │  │
│                            └────────────────────────────────┘  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘

Public Internet → SQL Server = NO ROUTE EXISTS!
```

### 7. Diagnostic Logging (The Security Camera)

Diagnostic settings send audit events and metrics to Log Analytics — like security cameras recording everything.

```
SQL Server Activity:
────────────────────

  User "alice@company.com" logged in                    ──→ Log Analytics
  Query: "SELECT * FROM Users WHERE id = 5"             ──→ Log Analytics
  Failed login attempt from 185.X.X.X                   ──→ Log Analytics
  Database "app-db" CPU at 85%                           ──→ Log Analytics

                                                         ┌──────────────┐
  All events captured! You can:                          │ Log Analytics│
  • Search for suspicious activity                       │              │
  • Set up alerts (e.g., failed logins > 10)            │ KQL Queries  │
  • Monitor performance trends                           │ Dashboards   │
  • Audit who accessed what data                        │ Alerts       │
                                                         └──────────────┘
```

---

## How Data Flows Through the Module

### Complete Architecture

```
                    ┌───────────────────────────────────────────────────┐
                    │              INTERNET / USERS                      │
                    └───────────────────┬───────────────────────────────┘
                                        │
                                        ▼
                    ┌───────────────────────────────────────────────────┐
                    │             FIREWALL RULES                        │
                    │                                                   │
                    │  Check: Is this IP allowed?                       │
                    │  • Named rules (dev-office, ci-cd)               │
                    │  • Azure services (0.0.0.0)                      │
                    │  • If not allowed → REJECT                        │
                    │                                                   │
                    └───────────────────┬───────────────────────────────┘
                                        │ (if allowed)
                                        ▼
┌──────────────┐    ┌───────────────────────────────────────────────────┐
│  VNet Rule   │───→│              AZURE SQL SERVER                     │
│  (AKS/App    │    │                                                   │
│   subnets)   │    │  ┌─────────────────────────────────────────────┐ │
└──────────────┘    │  │  Azure AD Authentication                     │ │
                    │  │  Admin: sqladmin@company.com                  │ │
┌──────────────┐    │  │  System Identity: enabled                    │ │
│  Private     │───→│  │  TLS: 1.2 minimum                           │ │
│  Endpoint    │    │  └─────────────────────────────────────────────┘ │
│ (most secure)│    │                                                   │
└──────────────┘    │  ┌──────────┐ ┌──────────┐ ┌──────────┐        │
                    │  │  app-db  │ │ audit-db │ │ report-db│        │
                    │  │  P1/256G │ │ S0/10G   │ │ S1/50G   │        │
                    │  └──────────┘ └──────────┘ └──────────┘        │
                    │                                                   │
                    └─────────────────────┬─────────────────────────────┘
                                          │
                                          ▼
                    ┌───────────────────────────────────────────────────┐
                    │           LOG ANALYTICS WORKSPACE                  │
                    │                                                   │
                    │  • SQLSecurityAuditEvents                        │
                    │  • AllMetrics (CPU, IO, connections)              │
                    │                                                   │
                    └───────────────────────────────────────────────────┘
```

---

## What the Terraform Module Creates

Here's exactly what happens when you apply this module:

```
Step 1: Create SQL Server
─────────────────────────
azurerm_mssql_server.sql
├── Name: myapp-sql-prod-001
├── Version: 12.0
├── Admin login: (your SQL admin)
├── Azure AD admin: sqladmin@company.com
├── Identity: SystemAssigned (gets a principal_id)
├── TLS: 1.2 minimum
└── Tags: your tags

Step 2: Create Databases (for each entry in var.databases)
──────────────────────────────────────────────────────────
azurerm_mssql_database.db["app-db"]
├── SKU: P1
├── Max size: 256 GB
├── Zone redundant: true
├── Read scale: true
└── Read replicas: 1

azurerm_mssql_database.db["audit-db"]
├── SKU: S0
├── Max size: 10 GB
└── Zone redundant: false

Step 3: Create Firewall Rules (for each entry in var.firewall_rules)
────────────────────────────────────────────────────────────────────
azurerm_mssql_firewall_rule.rules["dev-office"]
├── Start IP: 203.0.113.0
└── End IP: 203.0.113.255

Step 4: Allow Azure Services (if allow_azure_services = true)
─────────────────────────────────────────────────────────────
azurerm_mssql_firewall_rule.allow_azure["0"]
├── Name: AllowAllWindowsAzureIps
├── Start IP: 0.0.0.0
└── End IP: 0.0.0.0

Step 5: VNet Rules (for each entry in var.virtual_network_rules)
────────────────────────────────────────────────────────────────
azurerm_mssql_virtual_network_rule.vnet_rules["aks-subnet"]
└── Subnet ID: /subscriptions/.../subnets/aks-subnet

Step 6: Diagnostic Settings (only if log_analytics_workspace_id is set)
───────────────────────────────────────────────────────────────────────
azurerm_monitor_diagnostic_setting.sql_diagnostics["0"]
├── Log category: SQLSecurityAuditEvents
└── Metric category: AllMetrics

Step 7: Private Endpoint (only if enable_private_endpoint = true)
────────────────────────────────────────────────────────────────
azurerm_private_endpoint.sql_endpoint["0"]
├── Subnet: var.private_endpoint_subnet_id
├── Connection: sqlServer subresource
└── Manual connection: false
```

---

## Environment Differences

### Development Environment

```
┌─────────────────────────────────────────────────────────────────┐
│                    DEV SQL SERVER                                 │
│                                                                  │
│  Server: myapp-sql-dev-001                                      │
│                                                                  │
│  Databases:                                                      │
│  ┌──────────────┐                                               │
│  │   app-db     │  SKU: Basic or S0   (~$5-15/month)           │
│  │   4 GB       │  Zone redundant: No                           │
│  │   No HA      │  Read scale: No                               │
│  └──────────────┘                                               │
│                                                                  │
│  Security:                                                       │
│  • Public access: ON (easy to connect from laptop)              │
│  • Firewall: Dev team IPs + Azure services                      │
│  • Private endpoint: OFF (not needed)                           │
│  • Diagnostics: Optional                                        │
│                                                                  │
│  Monthly cost: ~$5 - $15                                        │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Staging Environment

```
┌─────────────────────────────────────────────────────────────────┐
│                    STAGING SQL SERVER                             │
│                                                                  │
│  Server: myapp-sql-staging-001                                  │
│                                                                  │
│  Databases:                                                      │
│  ┌──────────────┐                                               │
│  │   app-db     │  SKU: S1 or S2      (~$30-75/month)          │
│  │   50 GB      │  Zone redundant: No                           │
│  │   Test data  │  Read scale: No                               │
│  └──────────────┘                                               │
│                                                                  │
│  Security:                                                       │
│  • Public access: ON (CI/CD needs it)                           │
│  • Firewall: CI/CD IPs + Azure services                         │
│  • Private endpoint: OFF (optional)                             │
│  • Diagnostics: ON (test monitoring)                            │
│                                                                  │
│  Monthly cost: ~$30 - $75                                       │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Production Environment

```
┌─────────────────────────────────────────────────────────────────┐
│                    PRODUCTION SQL SERVER                          │
│                                                                  │
│  Server: myapp-sql-prod-001                                     │
│                                                                  │
│  Databases:                                                      │
│  ┌──────────────┐  ┌──────────────┐                             │
│  │   app-db     │  │  audit-db    │                             │
│  │ SKU: P1+     │  │ SKU: S1      │                             │
│  │ 256 GB       │  │ 100 GB       │                             │
│  │ Zone HA: YES │  │ Zone HA: No  │                             │
│  │ Read scale ✅│  │              │                             │
│  │ Read replica │  │              │                             │
│  └──────────────┘  └──────────────┘                             │
│                                                                  │
│  Security:                                                       │
│  • Public access: OFF (no internet exposure!)                   │
│  • Firewall: None needed (private only)                         │
│  • Private endpoint: ON (all traffic via private network)       │
│  • VNet rules: AKS + App subnets                                │
│  • Diagnostics: ON (full audit logging)                         │
│  • TLS: 1.2 enforced                                            │
│                                                                  │
│  Monthly cost: ~$500 - $1,500+                                  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Cost Breakdown

Understanding what you pay for:

```
Azure SQL Database Costs:
─────────────────────────

1. DATABASE (main cost — based on SKU choice):
   ┌────────────┬──────────────────┬──────────────────────────┐
   │ SKU        │ Cost/Month       │ Notes                    │
   ├────────────┼──────────────────┼──────────────────────────┤
   │ Basic      │ ~$5              │ 2 GB, 5 DTU             │
   │ S0         │ ~$15             │ 250 GB, 10 DTU          │
   │ S1         │ ~$30             │ 250 GB, 20 DTU          │
   │ S2         │ ~$75             │ 250 GB, 50 DTU          │
   │ S3         │ ~$150            │ 250 GB, 100 DTU         │
   │ P1         │ ~$465            │ 1 TB, 125 DTU, HA       │
   │ P2         │ ~$930            │ 1 TB, 250 DTU, HA       │
   │ GP_Gen5_2  │ ~$200            │ vCore model, flexible   │
   │ BC_Gen5_2  │ ~$600            │ In-memory, HA           │
   └────────────┴──────────────────┴──────────────────────────┘

2. ADDITIONAL COSTS:
   • Private Endpoint: ~$8/month
   • Log Analytics ingestion: ~$2.76/GB
   • Read replicas: Same cost as primary
   • Geo-replication: Same cost as primary
   • Long-term backup retention: ~$0.05/GB/month

3. SAVING MONEY:
   • Azure Hybrid Benefit: Set license_type = "BasePrice"
     → Save ~55% if you have existing SQL Server licenses!
   • Use Basic/S0 for dev environments
   • Right-size: Don't use P1 for dev!
   • Reserved capacity: 1-year or 3-year commit for discounts
```

### Cost Examples by Environment

```
DEV environment:
  1x Basic database     = $5
  No private endpoint   = $0
  No diagnostics        = $0
  TOTAL                 ≈ $5/month

STAGING environment:
  1x S1 database        = $30
  No private endpoint   = $0
  Diagnostics (1 GB)    = $3
  TOTAL                 ≈ $33/month

PRODUCTION environment:
  1x P1 database        = $465
  1x S1 database        = $30
  Private endpoint      = $8
  Diagnostics (5 GB)    = $14
  TOTAL                 ≈ $517/month

PRODUCTION (with Hybrid Benefit):
  1x P1 (BasePrice)     = $210  (saved $255!)
  1x S1 (BasePrice)     = $15   (saved $15!)
  Private endpoint      = $8
  Diagnostics (5 GB)    = $14
  TOTAL                 ≈ $247/month
```

---

## Common Questions

### "Why do I need both a server and databases?"

Think of it like a building and rooms. The SQL Server is the building — it has the address, security, and shared settings. Databases are rooms inside — each with their own data, size, and performance level. You can have many databases on one server, sharing the same network and auth settings.

### "What's the difference between firewall rules and VNet rules?"

```
Firewall Rules:                      VNet Rules:
── IP-based ──                       ── Subnet-based ──

"Allow this specific IP address"     "Allow this Azure subnet"

Used for:                            Used for:
• Developer laptops                  • AKS cluster connecting
• CI/CD servers                      • App Service connecting
• On-premises servers                • Container Apps connecting
• External services                  • Any Azure service in a VNet
```

### "When should I use a private endpoint?"

Always in production! A private endpoint means your SQL Server is only accessible via a private IP inside your VNet. No one on the internet can even see it exists.

Use it when:
- You handle sensitive data (PII, financial, health)
- You need compliance (HIPAA, SOC2, PCI-DSS)
- You want zero public exposure
- Your apps are already in a VNet (AKS, Container Apps)

### "What's zone redundancy?"

Azure regions have multiple availability zones (physical data centers). Zone redundancy means your database is replicated across zones. If one data center fails, another takes over automatically.

```
Without zone redundancy:             With zone redundancy:
────────────────────────             ─────────────────────

  Zone 1: [Database] ←── Only copy     Zone 1: [Database] ←── Primary
  Zone 2: [empty]                       Zone 2: [Database] ←── Replica
  Zone 3: [empty]                       Zone 3: [Database] ←── Replica

  Zone 1 fails → DATABASE DOWN!         Zone 1 fails → Zone 2 takes over!
                                         Downtime: seconds, not hours
```

Requires Premium (P1+) or Business Critical SKU.

### "What's read scale?"

Read scale gives you a read-only replica of your database at no extra cost (included in Premium/BC SKUs). Your app can send read-heavy queries (reports, dashboards) to the replica, keeping the primary free for writes.

```
Without read scale:                  With read scale:
───────────────────                  ──────────────────

  App writes ──→ Primary DB          App writes ──→ Primary DB
  App reads  ──→ Primary DB          App reads  ──→ Read Replica (free!)
  Reports    ──→ Primary DB          Reports    ──→ Read Replica (free!)

  Primary overloaded!                 Primary handles writes only — fast!
```

### "Why does the module create a system-assigned identity?"

The system-assigned identity gives your SQL Server its own Azure AD identity. This lets it:
- Access Key Vault to retrieve secrets
- Authenticate to other Azure services
- Write to storage accounts
- All without storing any passwords!

### "What collation should I use?"

The default `SQL_Latin1_General_CP1_CI_AS` works for most English-language applications.
- `CI` = Case Insensitive (`SELECT` matches `select`)
- `AS` = Accent Sensitive (`café` differs from `cafe`)

If you need a different language or sorting behavior, check [SQL Server collation docs](https://learn.microsoft.com/en-us/sql/relational-databases/collations/collation-and-unicode-support).

---

## Connecting to Your Database

### Connection String Format

```
Server=tcp:myapp-sql-prod-001.database.windows.net,1433;
Database=app-db;
User ID=youradmin;
Password=yourpassword;
Encrypt=True;
TrustServerCertificate=False;
Connection Timeout=30;
```

### From Application Code

**C# / .NET:**
```csharp
using Microsoft.Data.SqlClient;

var connectionString = "Server=tcp:myapp-sql-prod-001.database.windows.net,1433;"
    + "Database=app-db;Authentication=Active Directory Default;";

using var connection = new SqlConnection(connectionString);
await connection.OpenAsync();

// Uses Managed Identity — no password needed!
```

**Python:**
```python
import pyodbc

conn = pyodbc.connect(
    'DRIVER={ODBC Driver 18 for SQL Server};'
    'SERVER=myapp-sql-prod-001.database.windows.net;'
    'DATABASE=app-db;'
    'UID=youradmin;'
    'PWD=yourpassword;'
    'Encrypt=yes;'
)
cursor = conn.cursor()
cursor.execute("SELECT * FROM Users WHERE id = ?", 1)
```

**Pro tip:** Store the connection string in Key Vault and retrieve it at runtime using Managed Identity. Never hard-code credentials!

---

## Troubleshooting

### "Login failed for user"

```
Checklist:
□ Is the username correct? (administrator_login from Terraform)
□ Is the password correct? (administrator_login_password)
□ Are you connecting to the right server? (check FQDN)
□ Are you connecting to the right database? (check database name)
□ For Azure AD auth: Is the user added to the database?
  → CREATE USER [user@company.com] FROM EXTERNAL PROVIDER;
  → ALTER ROLE db_datareader ADD MEMBER [user@company.com];
```

### "Cannot open server — client IP not allowed"

```
Your IP is not in the firewall rules.

Quick fix (CLI):
  az sql server firewall-rule create \
    --resource-group myapp-rg \
    --server myapp-sql-dev-001 \
    --name my-ip \
    --start-ip-address YOUR_IP \
    --end-ip-address YOUR_IP

Permanent fix (Terraform):
  firewall_rules = {
    "my-ip" = {
      start_ip_address = "YOUR_IP"
      end_ip_address   = "YOUR_IP"
    }
  }
```

### "Timeout expired / Connection timeout"

```
Checklist:
□ Is the server running? (check Azure portal)
□ Is your network allowing port 1433 outbound?
□ If using private endpoint: Is DNS resolving to private IP?
□ If using VNet rules: Is your app in an allowed subnet?
□ Is the database paused? (Basic/S0 may auto-pause)
```

### "The requested service objective is not supported"

```
Not all SKUs are available everywhere:
□ Zone redundancy → Requires Premium or Business Critical
□ Read scale → Requires Premium (P1+) or Business Critical
□ Some SKUs not available in all regions
□ Check: az sql db list-editions -l eastus -o table
```

---

## Summary

**Azure SQL Database is:**
- A fully managed relational database in the cloud
- Perfect for structured data with relationships
- Secured with firewalls, VNet rules, and private endpoints
- Monitored with diagnostic logging to Log Analytics

**This module creates:**
- SQL Server with Azure AD auth and system identity
- One or more databases with configurable SKUs
- Firewall rules and VNet rules for network security
- Optional private endpoint for full network isolation
- Optional diagnostic settings for audit logging

**Best practices:**
- Use small SKUs (Basic/S0) for dev, Premium for prod
- Enable private endpoints in production
- Disable public network access in production
- Enable diagnostic logging for audit trails
- Use Azure AD authentication when possible
- Store credentials in Key Vault, not in code
- Use Azure Hybrid Benefit to save ~55% on licensing

**Never do:**
- Put connection strings with passwords in source code
- Use the same SKU for dev and production
- Leave public network access enabled in production
- Skip diagnostic logging in production
- Use Basic SKU for production workloads
