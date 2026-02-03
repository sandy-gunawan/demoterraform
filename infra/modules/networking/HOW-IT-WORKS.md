# Networking - How It Works

A beginner-friendly guide to Azure networking concepts. No networking experience required!

---

## What is Azure Networking?

**Simple explanation:** Think of Azure networking like designing roads and neighborhoods for a city.

```
Without planning:              With good planning:
─────────────────              ──────────────────
Houses everywhere              Organized neighborhoods
No roads between them          Clear roads connecting areas
Anyone can go anywhere         Security checkpoints
Chaos!                         Safe and organized
```

---

## Key Concepts (Plain English)

### 1. Virtual Network (VNet)

**What:** Your private network in Azure. Like owning your own neighborhood.

**Why:** Keeps your resources isolated. Only things inside can talk to each other by default.

```
PUBLIC INTERNET                    YOUR VNET
═══════════════                    ═════════
Billions of devices                Only your resources
Anyone can try to connect          Private and isolated
Dangerous if exposed               Safe by default

                ┌──────────────────────────────────┐
Internet ──X────│  VNet (10.1.0.0/16)              │
   (blocked!)   │                                  │
                │    [AKS]  ←────→  [Cosmos DB]   │
                │                                  │
                │    Resources can talk to each    │
                │    other inside the VNet         │
                └──────────────────────────────────┘
```

### 2. Subnets

**What:** Smaller sections within your VNet. Like different streets in a neighborhood.

**Why:** Organize resources and apply different rules to each section.

```
VNet (The Neighborhood)
┌────────────────────────────────────────────────────────────────┐
│                                                                 │
│   ┌─────────────────┐  ┌─────────────────┐  ┌───────────────┐ │
│   │   AKS Street    │  │   App Street    │  │  Data Street  │ │
│   │  (aks-subnet)   │  │ (app-subnet)    │  │ (data-subnet) │ │
│   │                 │  │                 │  │               │ │
│   │  10.1.1.0/24    │  │  10.1.2.0/24    │  │ 10.1.3.0/24   │ │
│   │                 │  │                 │  │               │ │
│   │  For:           │  │  For:           │  │ For:          │ │
│   │  - AKS nodes    │  │  - Container    │  │ - Cosmos DB   │ │
│   │  - Kubernetes   │  │    Apps         │  │ - Key Vault   │ │
│   │    pods         │  │  - Web apps     │  │ - SQL DB      │ │
│   │                 │  │                 │  │               │ │
│   └─────────────────┘  └─────────────────┘  └───────────────┘ │
│                                                                 │
└────────────────────────────────────────────────────────────────┘
```

### 3. IP Addresses

**What:** The "home address" of each resource.

**Why:** So resources can find and talk to each other.

```
IP Address Format: 10.1.2.50
                   ── ─ ─ ──
                   │  │ │  │
                   │  │ │  └── Host (specific resource)
                   │  │ └───── Subnet
                   │  └─────── Still VNet
                   └────────── VNet

CIDR Notation: 10.1.0.0/16
               ─────────  ──
               Network    Size

/16 = 65,536 addresses (10.1.0.0 to 10.1.255.255)
/24 = 256 addresses    (10.1.2.0 to 10.1.2.255)
```

### 4. Network Security Groups (NSGs)

**What:** Firewalls that control traffic in and out of subnets. Like security guards with a checklist.

**Why:** Decide exactly what traffic is allowed.

```
NSG = Security Guard with a Checklist
──────────────────────────────────────

Request arrives: "I want to connect to port 443"

Guard checks rules in order:
┌────────────────────────────────────────────────────────┐
│ Priority 100: Allow HTTPS (443) from anywhere    → ✅ │
│ Priority 200: Allow SSH (22) from office IP only → ❓ │
│ Priority 4096: Deny everything else              → ❌ │
└────────────────────────────────────────────────────────┘

First matching rule wins!

Port 443 → Matches rule 100 → ALLOWED
Port 22 from home → Doesn't match 200 → Matches 4096 → DENIED
```

### 5. Service Endpoints

**What:** A "VIP entrance" from your subnet directly to Azure services.

**Why:** Traffic stays on Azure's private network, never goes to public internet.

```
Without Service Endpoint:           With Service Endpoint:
──────────────────────────          ──────────────────────
VNet → Internet → Storage           VNet ───────→ Storage
      (public, slow, less secure)        (private, fast, secure)

      ┌─────────────┐                     ┌─────────────┐
      │   Storage   │                     │   Storage   │
      │   Account   │                     │   Account   │
      └──────▲──────┘                     └──────▲──────┘
             │                                    │
      Public Internet                      Service Endpoint
             │                              (Private path)
             │                                    │
      ┌──────┴──────┐                     ┌──────┴──────┐
      │   Your VM   │                     │   Your VM   │
      └─────────────┘                     └─────────────┘
```

### 6. Private Endpoints

**What:** Gives an Azure service a private IP address INSIDE your VNet.

**Why:** The service becomes part of your network. No public access at all!

```
Public Endpoint (Default):           Private Endpoint:
──────────────────────────           ─────────────────
Cosmos DB: cosmosdb.documents.azure.com  Cosmos DB: 10.1.3.50
           (public IP, accessible from   (private IP, only your
            anywhere on internet)         VNet can reach it)

┌────────────────────────────────────────────────────────────────┐
│                         YOUR VNET                               │
│                                                                 │
│   ┌─────────────┐                    ┌──────────────────────┐  │
│   │   Your App  │ ────────────────→  │ Cosmos DB            │  │
│   │             │   Private IP       │ (Private Endpoint)   │  │
│   └─────────────┘   10.1.3.50        │ 10.1.3.50            │  │
│                                      └──────────────────────┘  │
│                                                                 │
└────────────────────────────────────────────────────────────────┘

Outside VNet ────X───→ Cosmos DB
              BLOCKED!
```

### 7. NAT Gateway

**What:** A shared "exit door" for outbound internet traffic.

**Why:** All resources get ONE consistent public IP for outbound connections.

```
Without NAT Gateway:                 With NAT Gateway:
────────────────────                 ─────────────────
VM1 → Internet (IP: 40.1.2.3)        VM1 ─┐
VM2 → Internet (IP: 40.4.5.6)        VM2 ─┼──→ NAT Gateway ──→ Internet
VM3 → Internet (IP: 40.7.8.9)        VM3 ─┘    (IP: 52.1.2.3)

Random, unpredictable IPs            Consistent, static IP

Partner: "What IPs will call us?"    Partner: "Whitelist 52.1.2.3"
You: "Umm... could be anything?"     You: "Done! Always same IP"
```

---

## How Traffic Flows: Step by Step

### Scenario: User → Your App → Database

```
Step 1: User types yourapp.com
                │
                ▼
Step 2: DNS resolves to Azure Load Balancer
                │
                ▼
Step 3: Load Balancer forwards to Ingress (in AKS)
                │
        ┌───────┴───────┐
        │   AKS SUBNET  │
        │               │
        │   Ingress     │
        │   Controller  │
        │       │       │
        │       ▼       │
        │   Your Pod    │──────────────────────────────┐
        │  (10.1.1.50)  │                              │
        └───────────────┘                              │
                                                       │
                                    NSG Check: "Is this allowed?"
                                    Rule 100: Allow from AKS subnet → ✅
                                                       │
                                              ┌────────┴────────┐
                                              │   DATA SUBNET   │
                                              │                 │
                                              │   Cosmos DB     │
                                              │  (10.1.3.10)    │
                                              │                 │
                                              │  "Query from    │
                                              │   10.1.1.50?"   │
                                              │  "VNet allowed" │
                                              │  "Here's data!" │
                                              │                 │
                                              └─────────────────┘
```

### Scenario: App → External API

```
Your Pod (10.1.1.50) wants to call api.stripe.com

Step 1: Pod sends request
                │
        ┌───────┴───────┐
        │   AKS SUBNET  │
        │               │
        │   Your Pod    │
        │  "Call Stripe"│
        │       │       │
        └───────┼───────┘
                │
        NSG Check: "Outbound allowed?"
        Default: Allow all outbound → ✅
                │
                ▼
        ┌───────────────┐
        │  NAT Gateway  │  (if configured)
        │               │
        │ "I'll make    │
        │  this call    │
        │  using my IP" │
        │               │
        │  52.1.2.3     │
        └───────┬───────┘
                │
                ▼
           INTERNET
                │
                ▼
         api.stripe.com
        "Request from 52.1.2.3"
```

---

## Security: NSG Rules Explained

### How Rules Work

```
Each rule has:
- Priority (100-4096, lower = checked first)
- Direction (Inbound or Outbound)
- Action (Allow or Deny)
- Protocol (TCP, UDP, or Any)
- Ports (443, 80, 22, etc.)
- Source (Where traffic comes from)
- Destination (Where traffic goes to)
```

### Example NSG Configuration

```hcl
network_security_groups = {
  "web-nsg" = {
    security_rules = {
      # Rule 1: Allow HTTPS from internet
      "allow-https" = {
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "*"         # Anywhere
        destination_address_prefix = "*"
      }
      
      # Rule 2: Allow HTTP for redirect
      "allow-http" = {
        priority                   = 110
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "80"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
      }
      
      # Rule 3: Block everything else
      "deny-all" = {
        priority                   = 4096
        direction                  = "Inbound"
        access                     = "Deny"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_range     = "*"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
      }
    }
  }
}
```

### Result

```
Incoming traffic to web-nsg:

Port 443 (HTTPS) → Check rule 100 → ALLOWED ✅
Port 80 (HTTP)   → Check rule 110 → ALLOWED ✅
Port 22 (SSH)    → Skip 100, skip 110 → Check 4096 → DENIED ❌
Port 3389 (RDP)  → Skip 100, skip 110 → Check 4096 → DENIED ❌
```

---

## Service Endpoints vs Private Endpoints

### Quick Comparison

| Feature | Service Endpoint | Private Endpoint |
|---------|------------------|------------------|
| Access path | Through Azure backbone | Private IP in your VNet |
| Public endpoint | Still exists | Can be disabled |
| DNS resolution | Public DNS | Private DNS |
| Cost | Free | ~$7/month |
| Setup complexity | Simple | More complex |

### When to Use What

```
Use SERVICE ENDPOINT when:
├── You want traffic to stay on Azure backbone
├── Don't need to completely disable public access
├── Want simple setup
└── Cost-sensitive

Use PRIVATE ENDPOINT when:
├── Zero public access required (most secure)
├── Need private IP for compliance
├── Connecting from on-premises
└── Full network isolation required
```

---

## Using the Networking Module

### Basic Example

```hcl
module "networking" {
  source = "../../modules/networking"

  network_name  = "myapp-vnet-dev"
  location      = "eastus"
  address_space = ["10.1.0.0/16"]

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

  tags = module.global_standards.common_tags
}
```

### With NSGs and NAT Gateway

```hcl
module "networking" {
  source = "../../modules/networking"

  network_name  = "myapp-vnet-prod"
  location      = "eastus"
  address_space = ["10.3.0.0/16"]

  subnets = {
    "aks-subnet" = {
      address_prefixes = ["10.3.1.0/23"]  # Larger for production
      service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
    }
  }

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
        "deny-all" = {
          priority                   = 4096
          direction                  = "Inbound"
          access                     = "Deny"
          protocol                   = "*"
          destination_port_range     = "*"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        }
      }
    }
  }

  subnet_nsg_associations = {
    "aks-subnet" = "aks-nsg"
  }

  create_nat_gateway = true  # For static outbound IP

  tags = module.global_standards.common_tags
}
```

---

## Troubleshooting

### "Can't connect to Azure service"

```
Checklist:
□ Is there an NSG blocking traffic?
  → Check: az network nsg show -g RG -n NSG-NAME

□ Is Service Endpoint enabled on the subnet?
  → Check: az network vnet subnet show -g RG --vnet-name VNET -n SUBNET

□ Is the service firewall configured to allow your VNet?
  → Check: Cosmos DB/Storage/etc firewall settings
```

### "Can't reach the internet"

```
Checklist:
□ Is there an NSG blocking outbound traffic?
  → Check outbound rules, default is allow

□ Is NAT Gateway associated with the subnet?
  → Check: az network nat gateway show -g RG -n NAT-NAME

□ Is there a route table forcing traffic elsewhere?
  → Check: az network route-table show -g RG -n ROUTE-TABLE
```

### "Resources in same VNet can't communicate"

```
Checklist:
□ Are they in the same VNet or peered VNets?
  → Same VNet should work by default

□ Is there an NSG blocking the traffic?
  → Check both source and destination NSGs

□ Is the application listening on the right IP/port?
  → Check: kubectl exec POD -- netstat -tlnp
```

---

## Summary

**Azure Networking is:**
- How your resources communicate
- How you secure traffic
- How you connect to Azure services and internet

**Key components:**
- **VNet** = Your private network
- **Subnet** = Sections of your VNet
- **NSG** = Firewall rules
- **Service Endpoint** = Fast path to Azure services
- **Private Endpoint** = Azure service with private IP
- **NAT Gateway** = Static outbound IP

**Best practices:**
- Plan IP addresses before deployment
- Use NSGs to restrict traffic
- Use Service/Private Endpoints for Azure services
- Use NAT Gateway for consistent outbound IPs
- Separate workloads into different subnets
