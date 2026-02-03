# Landing Zone - How It Works

A beginner-friendly guide to understanding the Landing Zone pattern. This is the foundation everything else builds on!

---

## What is a Landing Zone?

**Simple explanation:** A Landing Zone is like preparing a construction site before building houses. You install utilities (water, electricity, sewage) ONCE, and then all houses connect to them.

```
Without Landing Zone:              With Landing Zone:
──────────────────────             ──────────────────
Each house installs own            One shared utility system
  water well                         for all houses
  septic tank                      
  power generator                  Less expensive
                                   Easier to maintain
Expensive!                         Consistent quality
Hard to maintain
Inconsistent
```

### Real-World Analogy

Think of a Landing Zone like a **neighborhood's infrastructure**:

| Component | Neighborhood | Azure |
|-----------|--------------|-------|
| Streets | How houses connect | Virtual Network (VNet) |
| Blocks | Organized areas | Subnets |
| Security gates | Who can enter where | Network Security Groups |
| Utility meters | Track usage | Log Analytics |
| Water main | Shared water supply | Shared services |

---

## Why Do We Need This?

### The Problem Without a Landing Zone

Imagine three teams deploying their own applications:

```
Team A creates:                 Team B creates:              Team C creates:
─────────────────               ─────────────────            ─────────────────
VNet: 10.0.0.0/16              VNet: 10.0.0.0/16           VNet: 10.0.0.0/16
       ↑                              ↑                            ↑
       └──────────────────────────────┴────────────────────────────┘
                        IP CONFLICT! 💥
                  All three use same IP range!
```

```
Team A: Security Group allows port 443 only
Team B: Security Group allows everything (oops!)
Team C: No security group at all

Result: Inconsistent security, some apps are vulnerable
```

### The Solution: Shared Foundation

```
Landing Zone (Created ONCE by Platform Team):
───────────────────────────────────────────────
VNet: 10.1.0.0/16 with planned subnets
Security Groups: Consistent baseline rules
Log Analytics: ONE place for all logs
NAT Gateway: Shared outbound connectivity

Team A uses: aks-subnet (10.1.1.0/24)
Team B uses: app-subnet (10.1.2.0/24)  
Team C uses: data-subnet (10.1.3.0/24)

✅ No IP conflicts
✅ Consistent security
✅ Unified logging
✅ Lower costs
```

---

## What's Inside a Landing Zone?

```
┌─────────────────────────────────────────────────────────────────┐
│                    LANDING ZONE                                  │
│            (Shared Foundation for ALL Apps)                      │
│                                                                  │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │              RESOURCE GROUP                              │   │
│   │         (Container for all resources)                    │   │
│   │                                                          │   │
│   │   ┌───────────────────────────────────────────────────┐ │   │
│   │   │           VIRTUAL NETWORK (VNet)                   │ │   │
│   │   │              10.1.0.0/16                           │ │   │
│   │   │                                                    │ │   │
│   │   │   ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ │ │   │
│   │   │   │ AKS Subnet  │ │ App Subnet  │ │Data Subnet  │ │ │   │
│   │   │   │10.1.1.0/24  │ │10.1.2.0/24  │ │10.1.3.0/24  │ │ │   │
│   │   │   │             │ │             │ │             │ │ │   │
│   │   │   │ For:        │ │ For:        │ │ For:        │ │ │   │
│   │   │   │ Kubernetes  │ │ Container   │ │ Databases   │ │ │   │
│   │   │   │ nodes       │ │ Apps        │ │ Key Vault   │ │ │   │
│   │   │   └─────────────┘ └─────────────┘ └─────────────┘ │ │   │
│   │   │                                                    │ │   │
│   │   └────────────────────────────────────────────────────┘ │   │
│   │                                                          │   │
│   │   ┌────────────────────┐  ┌─────────────────────────┐   │   │
│   │   │ NETWORK SECURITY   │  │ LOG ANALYTICS           │   │   │
│   │   │ GROUPS (NSGs)      │  │ WORKSPACE               │   │   │
│   │   │                    │  │                         │   │   │
│   │   │ • aks-nsg          │  │ Collects ALL logs from: │   │   │
│   │   │ • app-nsg          │  │ • AKS clusters         │   │   │
│   │   │ • data-nsg         │  │ • Container Apps       │   │   │
│   │   │                    │  │ • Cosmos DB            │   │   │
│   │   │ (Security rules)   │  │ • Key Vault            │   │   │
│   │   └────────────────────┘  └─────────────────────────┘   │   │
│   │                                                          │   │
│   │   ┌────────────────────────────────────────────────────┐│   │
│   │   │ NAT GATEWAY (Optional - Production only)           ││   │
│   │   │                                                    ││   │
│   │   │ Provides static outbound IP for all resources     ││   │
│   │   └────────────────────────────────────────────────────┘│   │
│   │                                                          │   │
│   └──────────────────────────────────────────────────────────┘   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Understanding Each Component

### 1. Virtual Network (VNet)

**What:** A private network in Azure, like your own private internet.

**Why:** Keeps your resources isolated and secure. Resources inside can talk to each other; outside cannot.

```
Public Internet ──────────X──────────→ VNet (blocked by default!)

Inside VNet:
┌─────────────┐         ┌─────────────┐
│   AKS Pod   │ ◄─────► │  Cosmos DB  │   ✅ Can communicate
└─────────────┘         └─────────────┘
```

### 2. Subnets

**What:** Smaller sections within your VNet, like neighborhoods in a city.

**Why:** Organize and isolate different types of workloads.

```
VNet (10.1.0.0/16) = 65,536 IP addresses

Split into subnets:
├── aks-subnet (10.1.1.0/24) = 256 IPs for Kubernetes
├── app-subnet (10.1.2.0/24) = 256 IPs for Container Apps
└── data-subnet (10.1.3.0/24) = 256 IPs for databases

Why separate?
- Different security rules per subnet
- Easier to manage and audit
- Can't accidentally affect other workloads
```

### 3. Network Security Groups (NSGs)

**What:** Firewalls for your subnets. Lists of "allow" and "deny" rules.

**Why:** Control exactly what traffic can flow where.

```
NSG for data-subnet:
┌─────────────────────────────────────────────────────────────────┐
│  Rule 100: ALLOW traffic from aks-subnet to port 443     ✅    │
│  Rule 101: ALLOW traffic from app-subnet to port 443     ✅    │
│  Rule 4096: DENY everything else                         ❌    │
└─────────────────────────────────────────────────────────────────┘

Result: Only your apps can reach databases. Hackers can't!
```

### 4. Log Analytics Workspace

**What:** A central place where all your logs are collected.

**Why:** One dashboard to see everything. Find problems faster.

```
Without centralized logging:           With Log Analytics:
───────────────────────────           ──────────────────────
AKS logs in place A                   ┌─────────────────────┐
Container App logs in place B   →     │   LOG ANALYTICS     │
Cosmos DB logs in place C             │                     │
Key Vault logs in place D             │  ALL logs here!     │
                                      │  Search, alert,     │
Hard to correlate!                    │  analyze together   │
                                      └─────────────────────┘
```

### 5. NAT Gateway (Optional)

**What:** A shared "exit door" for outbound internet traffic.

**Why:** Gives all your resources one static public IP for outbound connections.

```
Without NAT Gateway:                With NAT Gateway:
────────────────────                ─────────────────
Pod A → Internet (IP: random1)      Pod A ─┐
Pod B → Internet (IP: random2)      Pod B ─┼─→ NAT Gateway → Internet
Pod C → Internet (IP: random3)      Pod C ─┘     (IP: 40.1.2.3)

Hard to whitelist IPs               Partner: "Whitelist 40.1.2.3"
                                    Done! All pods use same IP
```

---

## How Landing Zone Connects to Your Apps

```
DEPLOYMENT ORDER:
─────────────────

Step 1: Deploy Landing Zone (ONCE)
        │
        │ Creates: VNet, Subnets, NSGs, Log Analytics
        │
        │ Outputs:
        │ ├── subnet_ids = { "aks-subnet": "/subs/.../aks-subnet", ... }
        │ ├── vnet_id = "/subscriptions/.../vnet"
        │ └── log_analytics_workspace_id = "/subs/.../workspace"
        │
        ▼
Step 2: Deploy Applications (Uses Landing Zone outputs)

        ┌─────────────────────────────────────────────────────────┐
        │                         AKS                              │
        │                                                          │
        │  module "aks" {                                          │
        │    subnet_id = module.landing_zone.subnet_ids["aks-..."] │
        │    log_analytics_workspace_id = module.landing_zone...   │
        │  }                                                       │
        │                                                          │
        │  "Put me in the aks-subnet and send logs to the shared  │
        │   Log Analytics workspace"                               │
        └─────────────────────────────────────────────────────────┘

        ┌─────────────────────────────────────────────────────────┐
        │                      COSMOS DB                           │
        │                                                          │
        │  module "cosmosdb" {                                     │
        │    virtual_network_rules = [                             │
        │      module.landing_zone.subnet_ids["app-subnet"]        │
        │    ]                                                     │
        │  }                                                       │
        │                                                          │
        │  "Only allow access from the app-subnet"                │
        └─────────────────────────────────────────────────────────┘
```

---

## Using the Module

### Basic Example

```hcl
module "landing_zone" {
  source = "../../modules/landing-zone"

  resource_group_name = "myapp-foundation-dev"
  location            = "eastus"
  vnet_name           = "myapp-vnet-dev"
  address_space       = ["10.1.0.0/16"]

  # Create subnets
  subnets = {
    "aks-subnet" = {
      address_prefixes  = ["10.1.1.0/24"]
      service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
    }
    "app-subnet" = {
      address_prefixes  = ["10.1.2.0/24"]
      service_endpoints = ["Microsoft.AzureCosmosDB"]
    }
    "data-subnet" = {
      address_prefixes = ["10.1.3.0/24"]
    }
  }

  # Create NSGs
  network_security_groups = {
    "aks-nsg" = {
      security_rules = {
        "allow-https" = {
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          destination_port_range     = "443"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        }
      }
    }
  }

  # Link subnets to NSGs
  subnet_nsg_associations = {
    "aks-subnet" = "aks-nsg"
  }

  # Logging
  log_analytics_name           = "myapp-logs-dev"
  log_analytics_retention_days = 30

  tags = {
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
```

### Using Landing Zone Outputs

```hcl
# Now deploy AKS using the Landing Zone
module "aks" {
  source = "../../modules/aks"

  cluster_name = "myapp-aks-dev"
  location     = module.landing_zone.resource_group_location

  # Connect to Landing Zone subnet
  subnet_id = module.landing_zone.subnet_ids["aks-subnet"]

  # Send logs to Landing Zone's Log Analytics
  log_analytics_workspace_id = module.landing_zone.log_analytics_workspace_id

  tags = module.landing_zone.tags
}
```

---

## IP Address Planning

### Why It Matters

Every resource needs an IP address. If you run out or have conflicts, things break.

### Our Strategy

```
ENVIRONMENT     IP RANGE        PURPOSE
───────────     ────────        ───────
Development     10.1.0.0/16     Developer testing, experiments
Staging         10.2.0.0/16     Pre-production testing
Production      10.3.0.0/16     Live customer traffic

Each /16 = 65,536 addresses (plenty of room!)
```

### Subnet Sizing Guide

```
/24 = 256 addresses (251 usable after Azure reserves 5)
/23 = 512 addresses
/22 = 1,024 addresses

Recommendation:
├── Small workload (dev): /24 per subnet
├── Medium workload (staging): /24 per subnet
└── Large workload (prod): /23 or /22 for busy subnets
```

---

## One Per Environment

You create ONE Landing Zone per environment:

```
┌─────────────────────────────────────────────────────────────────┐
│                     DEVELOPMENT                                  │
│                                                                  │
│  Landing Zone (10.1.0.0/16)                                     │
│  ├── All dev apps share this                                    │
│  ├── 30-day log retention (save costs)                          │
│  └── No NAT Gateway (save costs)                                │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                       STAGING                                    │
│                                                                  │
│  Landing Zone (10.2.0.0/16)                                     │
│  ├── Mimics production                                          │
│  ├── 60-day log retention                                       │
│  └── Optional NAT Gateway                                       │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                      PRODUCTION                                  │
│                                                                  │
│  Landing Zone (10.3.0.0/16)                                     │
│  ├── Maximum security                                           │
│  ├── 90-day log retention (compliance)                          │
│  └── NAT Gateway enabled (static IP)                            │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Common Questions

### "Why can't each team create their own VNet?"

**Problems:**
1. IP conflicts (everyone picks 10.0.0.0/16)
2. No unified logging (hard to troubleshoot)
3. Inconsistent security (some teams forget NSGs)
4. Higher costs (duplicate Log Analytics, NAT Gateways)

### "What if I need more subnets later?"

No problem! Just add to the `subnets` variable and run `terraform apply`:

```hcl
subnets = {
  "aks-subnet" = { ... }
  "app-subnet" = { ... }
  "data-subnet" = { ... }
  "new-subnet" = {            # ← Add new subnet
    address_prefixes = ["10.1.4.0/24"]
  }
}
```

### "Can different teams access each other's subnets?"

By default, yes (within the same VNet). To restrict, use NSG rules:

```hcl
# Only allow traffic from aks-subnet to data-subnet
"allow-aks-to-data" = {
  priority                   = 100
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "*"
  source_address_prefix      = "10.1.1.0/24"  # aks-subnet
  destination_address_prefix = "10.1.3.0/24"  # data-subnet
}

# Block everything else
"deny-all" = {
  priority                   = 4096
  direction                  = "Inbound"
  access                     = "Deny"
  protocol                   = "*"
  source_address_prefix      = "*"
  destination_address_prefix = "*"
}
```

---

## Summary

**Landing Zone is:**
- The shared foundation for ALL applications
- Deployed ONCE per environment
- Provides VNet, subnets, security, and logging

**Why we need it:**
- No IP conflicts
- Consistent security baseline
- Unified logging and monitoring
- Lower costs (shared infrastructure)

**What it creates:**
- Resource Group (container)
- Virtual Network (private network)
- Subnets (organized sections)
- Network Security Groups (firewalls)
- Log Analytics Workspace (central logging)
- NAT Gateway (optional, for static outbound IP)

**Key rule:** Applications BUILD ON TOP of the Landing Zone. They don't create their own networks!
