# AKS (Azure Kubernetes Service) - How It Works

A beginner-friendly guide to understanding AKS. No Kubernetes experience required!

---

## What is AKS?

**Simple explanation:** AKS is like a smart apartment building for your applications.

```
Traditional Server:              AKS:
─────────────────               ────
One building, one tenant        One building, many apartments (pods)
If building breaks, tenant      If one apartment breaks, others
  has nowhere to go               are fine
Hard to add more space          Easy to add more apartments
```

### Real-World Analogy

Imagine you run a food delivery company:

| Without Kubernetes | With AKS |
|-------------------|----------|
| One big kitchen | Many small kitchens (pods) |
| If kitchen breaks, no food | One breaks, others keep cooking |
| Busy night? Can't scale | Busy night? Add more kitchens automatically |
| One chef does everything | Specialized chefs (microservices) |

---

## Key Concepts (Plain English)

### 1. Cluster
The entire AKS setup. Think of it as the **whole apartment building**.

### 2. Node
A virtual machine (VM) in your cluster. Think of it as a **floor in the building**.

### 3. Pod
The smallest unit - contains your application. Think of it as an **apartment**.

### 4. Service
A stable way to reach your pods. Think of it as the **reception desk** that knows where everyone lives.

### 5. Ingress
The front door that handles incoming traffic. Think of it as the **building entrance with a doorman**.

```
┌─────────────────────────────────────────────────────────────────┐
│                         AKS CLUSTER                              │
│                    (The Apartment Building)                      │
│                                                                  │
│   ┌───────────────────────────────────────────────────────────┐ │
│   │                      INGRESS                               │ │
│   │              (Front Door + Doorman)                        │ │
│   │              "Which apartment do you need?"                │ │
│   └───────────────────────┬───────────────────────────────────┘ │
│                           │                                      │
│   ┌───────────────────────┴───────────────────────────────────┐ │
│   │                      SERVICE                               │ │
│   │                 (Reception Desk)                           │ │
│   │        "API requests? Go to pods 1, 2, or 3"              │ │
│   └───────────────────────┬───────────────────────────────────┘ │
│                           │                                      │
│   ┌─────────────┬─────────┴─────────┬─────────────┐            │
│   │             │                   │             │            │
│   │   NODE 1    │       NODE 2      │   NODE 3    │  (Floors)  │
│   │  (Floor 1)  │     (Floor 2)     │  (Floor 3)  │            │
│   │             │                   │             │            │
│   │  ┌──────┐   │   ┌──────┐       │  ┌──────┐   │            │
│   │  │ Pod  │   │   │ Pod  │       │  │ Pod  │   │ (Apartments)│
│   │  │ API  │   │   │ API  │       │  │ API  │   │            │
│   │  └──────┘   │   └──────┘       │  └──────┘   │            │
│   │             │   ┌──────┐       │             │            │
│   │             │   │ Pod  │       │             │            │
│   │             │   │ Web  │       │             │            │
│   │             │   └──────┘       │             │            │
│   └─────────────┴───────────────────┴─────────────┘            │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## How Traffic Flows Through AKS

Let's follow a user request step by step:

```
Step 1: User types yourapp.com in browser
                    │
                    ▼
Step 2: DNS resolves to Azure Load Balancer IP
                    │
                    ▼
Step 3: Load Balancer sends to Ingress Controller
        (The doorman checks: "Is this allowed?")
                    │
                    ▼
Step 4: Ingress routes to correct Service
        (Reception: "API calls go to API pods")
                    │
                    ▼
Step 5: Service picks a healthy Pod
        (Load balanced across multiple pods)
                    │
                    ▼
Step 6: Pod processes the request
        (Your code runs here!)
                    │
                    ▼
Step 7: Response goes back the same way
                    │
                    ▼
Step 8: User sees the result!
```

---

## Networking in AKS: How Pods Communicate

### The Challenge

Each pod needs:
- Its own IP address (to be reachable)
- Ability to talk to other pods (microservices communicate)
- Ability to talk to Azure services (like Cosmos DB)

### Our Solution: Azure CNI

**What is Azure CNI?**

CNI = Container Network Interface. It's how pods get their IP addresses.

```
Azure CNI gives each pod a REAL Azure IP:

┌─────────────────────────────────────────────────────────────────┐
│                      YOUR VNET (10.1.0.0/16)                     │
│                                                                  │
│   AKS Subnet (10.1.1.0/24)                                      │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │                                                          │   │
│   │   Node 1 (10.1.1.4)                                     │   │
│   │   ├── Pod A (10.1.1.5)  ← Real IP, can talk to anything │   │
│   │   └── Pod B (10.1.1.6)  ← Real IP, can talk to anything │   │
│   │                                                          │   │
│   │   Node 2 (10.1.1.7)                                     │   │
│   │   ├── Pod C (10.1.1.8)                                  │   │
│   │   └── Pod D (10.1.1.9)                                  │   │
│   │                                                          │   │
│   └─────────────────────────────────────────────────────────┘   │
│                                                                  │
│   Data Subnet (10.1.3.0/24)                                     │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │   Cosmos DB (10.1.3.10) ← Pod A can reach this directly!│   │
│   └─────────────────────────────────────────────────────────┘   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

**Why we chose Azure CNI over Kubenet:**

| Feature | Kubenet | Azure CNI (Our Choice) |
|---------|---------|------------------------|
| Pod IPs | Fake internal IPs | Real Azure VNet IPs |
| Talk to Azure services | Needs NAT/translation | Direct communication |
| Network policies | Limited | Full support |
| Complexity | Simpler | More IPs needed |
| Performance | Extra hop | Faster (direct) |

---

## How AKS Connects to Other Services

### Connecting to Cosmos DB (Secure Way)

```
┌─────────────────────────────────────────────────────────────────┐
│                         AKS CLUSTER                              │
│                                                                  │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │                       YOUR POD                           │   │
│   │                                                          │   │
│   │   "I need to save data to Cosmos DB"                    │   │
│   │                         │                                │   │
│   │                         ▼                                │   │
│   │   1. Pod uses Managed Identity (no passwords!)          │   │
│   │                         │                                │   │
│   └─────────────────────────┼───────────────────────────────┘   │
│                             │                                    │
│                             │ Goes through VNet (private!)      │
│                             │ Never touches public internet     │
│                             │                                    │
└─────────────────────────────┼────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    PRIVATE ENDPOINT                              │
│                                                                  │
│   Cosmos DB has a private IP in your VNet                       │
│   IP: 10.1.3.50 (only reachable from inside VNet)              │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                       COSMOS DB                                  │
│                                                                  │
│   "Request from 10.1.1.5? That's in my allowed VNet."          │
│   "Managed Identity valid? Yes."                                │
│   "Here's your data!"                                           │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

**Security layers:**
1. ✅ Traffic stays in VNet (private network)
2. ✅ No passwords (Managed Identity)
3. ✅ Cosmos DB only accepts traffic from specific subnets

### Connecting to Key Vault (Getting Secrets)

```
Your Pod                                    Key Vault
─────────                                   ─────────
    │
    │ "I need the database connection string"
    │
    │ ──── Workload Identity proves who you are ────→
    │
    │                                        "Checking Azure AD..."
    │                                        "Yes, this pod is allowed"
    │ ←─────── Here's your secret ───────────
    │
    │ "Got it! Now I can connect to database"
```

**Two ways to get secrets:**

| Method | How it works | Best for |
|--------|--------------|----------|
| **CSI Driver** | Secrets mounted as files in pod | Kubernetes-native apps |
| **SDK** | App directly calls Key Vault API | Application-controlled refresh |

---

## What You Need Before Deploying AKS

### Prerequisites Checklist

```
□ Azure Subscription with Contributor access

□ Virtual Network (VNet) with:
  └── Subnet for AKS nodes (recommend /23 or /24 CIDR)

□ Azure AD (Entra ID) access for:
  └── Enabling AKS-managed Azure AD authentication

□ Service Principal or Managed Identity for:
  └── AKS to manage Azure resources (load balancers, disks)

□ Log Analytics Workspace for:
  └── Collecting logs and metrics
```

### Subnet Sizing Guide

**How many IPs do you need?**

```
Formula: (Number of Nodes × Max Pods per Node) + Number of Nodes + 5

Example:
- 3 nodes
- 30 pods per node max
- Calculation: (3 × 30) + 3 + 5 = 98 IPs needed
- Subnet size: /25 gives 128 IPs (128 - 5 reserved = 123 usable) ✓

Our default: /24 = 256 addresses (plenty of room to grow)
```

---

## How Our Module Creates AKS

When you run `terraform apply`, here's what happens:

```
terraform apply
       │
       ▼
┌──────────────────────────────────────────────────────────────────┐
│ Step 1: Create AKS Cluster Resource                              │
│                                                                   │
│   - Control plane (Azure manages this for you!)                  │
│   - Sets Kubernetes version                                       │
│   - Configures Azure CNI networking                               │
│   - Enables Azure AD authentication                               │
└──────────────────────────────────────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────────────────────────────┐
│ Step 2: Create Default Node Pool                                 │
│                                                                   │
│   - VMs that run your workloads                                  │
│   - Connected to your subnet                                      │
│   - Size: Standard_D2_v2 (default)                               │
│   - Count: 2 nodes (default)                                     │
└──────────────────────────────────────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────────────────────────────┐
│ Step 3: Configure Monitoring                                     │
│                                                                   │
│   - Enable container insights                                    │
│   - Connect to Log Analytics                                     │
│   - Set up metrics collection                                    │
└──────────────────────────────────────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────────────────────────────┐
│ Step 4: Set Up Identity                                          │
│                                                                   │
│   - Create Managed Identity for cluster                          │
│   - Grant permissions to subnet                                  │
│   - Enable Workload Identity (for pods)                          │
└──────────────────────────────────────────────────────────────────┘
       │
       ▼
   AKS Ready! (~10-15 minutes)
```

---

## Using the Module

### Basic Example

```hcl
module "aks" {
  source = "../../modules/aks"

  # Basic settings
  cluster_name = "myapp-aks-dev"
  location     = "eastus"
  
  # Network (from Landing Zone)
  subnet_id = module.landing_zone.subnet_ids["aks-subnet"]
  
  # Monitoring (from Landing Zone)
  log_analytics_workspace_id = module.landing_zone.log_analytics_workspace_id
  
  # Tags
  tags = module.global_standards.common_tags
}
```

### What This Creates

```
Resources created:
├── AKS Cluster (myapp-aks-dev)
│   ├── Control Plane (Azure-managed)
│   └── Default Node Pool
│       ├── Node 1 (Standard_D2_v2)
│       └── Node 2 (Standard_D2_v2)
├── Managed Identity
│   └── For cluster operations
└── Monitoring Integration
    └── Connected to Log Analytics
```

### Accessing Your Cluster

After deployment:

```powershell
# Get credentials
az aks get-credentials --resource-group myapp-rg-dev --name myapp-aks-dev

# Verify connection
kubectl get nodes

# Expected output:
# NAME                                STATUS   ROLES   AGE   VERSION
# aks-default-12345678-vmss000000   Ready    agent   10m   v1.27.3
# aks-default-12345678-vmss000001   Ready    agent   10m   v1.27.3
```

---

## Common Operations

### Deploying an Application

```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-api
spec:
  replicas: 3  # Run 3 copies
  selector:
    matchLabels:
      app: my-api
  template:
    metadata:
      labels:
        app: my-api
    spec:
      containers:
      - name: my-api
        image: myacr.azurecr.io/my-api:v1.0
        ports:
        - containerPort: 8080
```

```powershell
kubectl apply -f deployment.yaml
```

### Scaling

```powershell
# Scale pods (more copies of your app)
kubectl scale deployment my-api --replicas=5

# Scale nodes (more VMs in cluster)
az aks scale --resource-group myapp-rg-dev --name myapp-aks-dev --node-count 5
```

### Checking Logs

```powershell
# See pod logs
kubectl logs -l app=my-api

# See logs in Azure Portal
# Go to: AKS → Insights → Containers
```

---

## Troubleshooting

### Pod won't start

```powershell
# Check pod status
kubectl get pods

# See why it's failing
kubectl describe pod <pod-name>

# Common causes:
# - Image pull error: Check registry access
# - CrashLoopBackOff: Check application logs
# - Pending: Not enough node resources
```

### Can't connect to Cosmos DB

```powershell
# Check if pod has network access
kubectl exec -it <pod-name> -- curl cosmos-account.documents.azure.com

# Common causes:
# - NSG blocking traffic: Check security rules
# - Private endpoint not configured: Add private endpoint
# - Managed Identity not assigned: Check identity configuration
```

### Nodes are unhealthy

```powershell
# Check node status
kubectl get nodes

# See node details
kubectl describe node <node-name>

# Common causes:
# - Disk pressure: Pods using too much storage
# - Memory pressure: Pods using too much RAM
# - Not ready: VM issues, check Azure Portal
```

---

## Cost Tips

### Right-size your nodes

| Node Size | Monthly Cost | Good For |
|-----------|--------------|----------|
| Standard_B2s | ~$30 | Dev, testing |
| Standard_D2_v2 | ~$70 | Small production |
| Standard_D4_v2 | ~$140 | Medium production |
| Standard_D8_v2 | ~$280 | Large production |

### Enable cluster autoscaler

```hcl
# In module configuration
autoscaling_enabled = true
min_node_count      = 2   # Minimum nodes
max_node_count      = 10  # Maximum nodes
```

Cluster automatically scales based on demand!

### Use spot instances for non-critical workloads

Spot VMs cost up to 90% less but can be evicted. Good for:
- Dev/test environments
- Batch processing
- Stateless workloads

---

## Summary

**AKS is:**
- A managed Kubernetes service
- Like an apartment building for your apps
- Automatically handles scaling, healing, and updates

**Key concepts:**
- Cluster = The building
- Node = A floor (VM)
- Pod = An apartment (your app)
- Service = Reception desk
- Ingress = Front door

**Our setup includes:**
- Azure CNI networking (pods get real IPs)
- Managed Identity (no passwords)
- Log Analytics integration (monitoring)
- Private network access to other services

**Next steps:**
1. Deploy your first application
2. Set up ingress for external access
3. Connect to Cosmos DB using Managed Identity
