# Container Apps - How It Works

A beginner-friendly guide to Azure Container Apps. Perfect for teams who want containers without Kubernetes complexity!

---

## What is Container Apps?

**Simple explanation:** Container Apps is like a valet parking service for your containers.

```
Kubernetes (AKS):                 Container Apps:
─────────────────                 ─────────────────
You drive and park yourself       Give keys to valet
You manage the parking lot        Valet handles everything
Full control, more work           Less control, less work
```

### Real-World Analogy

| Aspect | AKS | Container Apps |
|--------|-----|----------------|
| Control | You build and manage the hotel | You book a room, hotel handles the rest |
| Complexity | Need to understand plumbing, HVAC, security | Just use the amenities |
| Best for | Large organizations, complex needs | Small-medium apps, quick deployment |

---

## Key Concepts (Plain English)

### 1. Container App Environment
The shared hosting space for multiple apps. Think of it as the **hotel building**.

### 2. Container App
Your actual application. Think of it as your **hotel room**.

### 3. Revision
A version of your app. Think of it as the **room after renovations** (new furniture, same room).

### 4. Replica
Multiple copies of your app running. Think of it as **identical twin rooms** for high demand.

```
┌─────────────────────────────────────────────────────────────────┐
│                 CONTAINER APP ENVIRONMENT                        │
│                     (The Hotel)                                  │
│                                                                  │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │                    CONTAINER APP: api                    │   │
│   │                     (Your Room)                          │   │
│   │                                                          │   │
│   │   ┌───────────┐  ┌───────────┐  ┌───────────┐          │   │
│   │   │ Revision  │  │ Revision  │  │ Revision  │          │   │
│   │   │    v1     │  │    v2     │  │    v3     │          │   │
│   │   │  (old)    │  │ (staging) │  │ (current) │          │   │
│   │   └───────────┘  └───────────┘  └───────────┘          │   │
│   │                                      │                   │   │
│   │                              ┌───────┴───────┐          │   │
│   │                              │               │          │   │
│   │                          Replica 1      Replica 2       │   │
│   │                         (copy of v3)   (copy of v3)     │   │
│   │                                                          │   │
│   └─────────────────────────────────────────────────────────┘   │
│                                                                  │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │                  CONTAINER APP: web                      │   │
│   │                  (Another Room)                          │   │
│   └─────────────────────────────────────────────────────────┘   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## How Traffic Flows

```
User visits yourapp.azurecontainerapps.io
                    │
                    ▼
┌─────────────────────────────────────────────────────────────────┐
│                    AZURE FRONT DOOR                              │
│           (Automatic HTTPS, Global load balancing)               │
└─────────────────────────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────────────────────┐
│                 INGRESS CONTROLLER                               │
│              (Built into Container Apps)                         │
│                                                                  │
│   "Looking for API? Let me route you to the right replica"      │
└─────────────────────────────────────────────────────────────────┘
                    │
            ┌───────┴───────┐
            ▼               ▼
    ┌─────────────┐  ┌─────────────┐
    │  Replica 1  │  │  Replica 2  │
    │   (API)     │  │   (API)     │
    │             │  │             │
    │  Your code  │  │  Your code  │
    │  runs here  │  │  runs here  │
    └─────────────┘  └─────────────┘
```

**Key difference from AKS:** All this is automatic! No need to configure ingress controllers, certificates, or load balancers.

---

## The Magic: Scale to Zero

This is Container Apps' superpower:

```
                    Traffic Pattern
High    │    ████
        │   ██████
        │  ████████
        │ ██████████
Low     │█          ████████████████
        └─────────────────────────────
         8am  12pm  5pm    Night

What Container Apps does:
────────────────────────
Morning rush:  Scales UP (more replicas)
Lunch time:    Scales UP more
Evening:       Scales DOWN
Night (no traffic): Scales to ZERO (no cost!)
```

**Compare to AKS:**
| Aspect | AKS | Container Apps |
|--------|-----|----------------|
| Minimum running | At least 1 node (~$70/month) | 0 replicas possible ($0) |
| Scaling speed | Minutes (new VMs) | Seconds (just containers) |
| Idle cost | Pay for idle nodes | Pay nothing when idle |

---

## When to Use Container Apps vs AKS

### Use Container Apps When:

✅ Simple web apps or APIs  
✅ Event-driven processing  
✅ You want to scale to zero  
✅ You don't need full Kubernetes control  
✅ Quick deployment is priority  

```
Good fit examples:
├── REST APIs
├── Webhooks
├── Background job processors
├── Microservices (simple)
└── Prototype/MVP applications
```

### Use AKS When:

✅ Complex orchestration needs  
✅ Custom Kubernetes operators  
✅ Specific networking requirements  
✅ Stateful workloads  
✅ You need the Kubernetes ecosystem  

```
Good fit examples:
├── Platform as a Service (your own)
├── Machine Learning pipelines
├── Complex microservices with service mesh
├── Stateful databases
└── Multi-tenant platforms
```

### Decision Flowchart

```
Do you need Kubernetes-specific features?
         │
         ├── YES → Use AKS
         │
         └── NO → Does your app need to be "always on"?
                          │
                          ├── YES → Do you need complex networking?
                          │              │
                          │              ├── YES → Use AKS
                          │              │
                          │              └── NO → Use Container Apps (with min_replicas=1)
                          │
                          └── NO → Use Container Apps (scale to zero!)
```

---

## How Auto-Scaling Works

Container Apps can scale based on different triggers:

### 1. HTTP Traffic (Default)

```
Incoming requests/second    Replicas
────────────────────────    ────────
0                          0 (scale to zero!)
1-10                       1
11-50                      2
51-100                     3
100+                       More...
```

### 2. CPU/Memory Usage

```hcl
# Scale when CPU > 70%
scaling_rules = {
  name = "cpu-scaling"
  custom = {
    type = "cpu"
    metadata = {
      averageUtilization = 70
    }
  }
}
```

### 3. Queue Length (Event-Driven)

```
Azure Service Bus Queue         Replicas
────────────────────────        ────────
0 messages                      0 (sleeping)
1-100 messages                  1
101-500 messages                2-3
500+ messages                   More...
```

---

## Setting Up Container Apps

### What Gets Created

```
terraform apply
       │
       ▼
┌─────────────────────────────────────────────────────────────────┐
│ Step 1: Container App Environment                                │
│                                                                  │
│   - Shared infrastructure for apps                               │
│   - Connected to Log Analytics                                   │
│   - Optional: VNet integration                                   │
└─────────────────────────────────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────────────────────────────┐
│ Step 2: Container App                                            │
│                                                                  │
│   - Your application container                                   │
│   - Ingress configuration (URL)                                  │
│   - Scaling rules                                                │
│   - Environment variables                                        │
└─────────────────────────────────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────────────────────────────┐
│ Step 3: Initial Revision                                         │
│                                                                  │
│   - First version of your app                                    │
│   - Ready to receive traffic                                     │
└─────────────────────────────────────────────────────────────────┘
       │
       ▼
   App is live! (~2-3 minutes)
   URL: myapp.azurecontainerapps.io
```

### Basic Example

```hcl
module "container_app" {
  source = "../../modules/container-app"

  app_name = "my-api"
  location = "eastus"
  
  # Container settings
  container_image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
  container_cpu    = 0.5
  container_memory = "1Gi"
  
  # Scaling
  min_replicas = 0  # Scale to zero!
  max_replicas = 10
  
  # Ingress (public URL)
  enable_ingress = true
  target_port    = 80
  
  tags = module.global_standards.common_tags
}
```

### With Environment Variables

```hcl
module "container_app" {
  source = "../../modules/container-app"

  app_name        = "my-api"
  location        = "eastus"
  container_image = "myregistry.azurecr.io/my-api:v1.0"

  # Regular environment variables
  environment_variables = {
    "LOG_LEVEL"    = "info"
    "API_VERSION"  = "v1"
    "ENVIRONMENT"  = "production"
  }

  # Secrets (stored securely)
  secret_environment_variables = {
    "DATABASE_URL" = var.database_connection_string
    "API_KEY"      = var.api_key
  }

  tags = module.global_standards.common_tags
}
```

---

## Connecting to Other Services

### Connecting to Cosmos DB

```
┌─────────────────────────────────────────────────────────────────┐
│                    CONTAINER APP                                 │
│                                                                  │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │   Your Code                                              │   │
│   │                                                          │   │
│   │   // Get connection string from environment              │   │
│   │   connectionString = env("COSMOS_CONNECTION")            │   │
│   │                                                          │   │
│   │   // Or use Managed Identity (passwordless!)             │   │
│   │   credential = DefaultAzureCredential()                  │   │
│   │   client = CosmosClient(endpoint, credential)            │   │
│   │                                                          │   │
│   └─────────────────────────────────────────────────────────┘   │
│                              │                                   │
└──────────────────────────────┼───────────────────────────────────┘
                               │
                               │ Private VNet connection
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                       COSMOS DB                                  │
│                                                                  │
│   Accepts connections from:                                      │
│   ✅ Your Container App's VNet                                  │
│   ❌ Public internet (blocked)                                  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Connecting to Key Vault

```hcl
module "container_app" {
  source = "../../modules/container-app"

  app_name = "my-api"
  # ...

  # Reference secrets from Key Vault
  secret_environment_variables = {
    "DB_PASSWORD" = "@Microsoft.KeyVault(SecretUri=https://mykv.vault.azure.net/secrets/db-password)"
  }
}
```

---

## Revisions and Deployments

### What's a Revision?

Every time you change your app's configuration or image, a new revision is created:

```
Revision History:
────────────────
my-api--abc123  (v1.0)  Created: Jan 1   ← Old
my-api--def456  (v1.1)  Created: Jan 15  ← Previous
my-api--ghi789  (v2.0)  Created: Feb 1   ← Current (100% traffic)
```

### Traffic Splitting (Blue-Green / Canary)

You can split traffic between revisions for safe deployments:

```
                    Incoming Traffic
                          │
                          │
              ┌───────────┴───────────┐
              │                       │
              ▼                       ▼
        ┌──────────┐            ┌──────────┐
        │ v1.0     │            │ v2.0     │
        │ (90%)    │            │ (10%)    │
        │ Stable   │            │ Canary   │
        └──────────┘            └──────────┘
```

```hcl
# Gradually shift traffic to new version
traffic_weight = {
  "my-api--v1" = 90  # 90% to old
  "my-api--v2" = 10  # 10% to new (canary)
}

# After testing, shift all traffic
traffic_weight = {
  "my-api--v1" = 0   # 0% to old
  "my-api--v2" = 100 # 100% to new
}
```

---

## Cost Breakdown

### How Billing Works

Container Apps charges for:
1. **vCPU-seconds** - How much CPU time you use
2. **Memory GiB-seconds** - How much memory time you use
3. **Requests** - Per million HTTP requests

### Example Costs

**Scenario 1: API that scales to zero at night**
```
Daytime (8 hours): 2 replicas × 0.5 vCPU × 1 GiB
Night (16 hours): 0 replicas

Monthly estimate: ~$15-25
```

**Scenario 2: Always-on web app**
```
24/7: 2 replicas × 0.5 vCPU × 1 GiB

Monthly estimate: ~$35-50
```

**Compare to AKS:**
```
AKS (minimum): 2 nodes × Standard_B2s = ~$60/month
(Even when idle!)
```

---

## Troubleshooting

### App won't start

```bash
# Check logs
az containerapp logs show --name my-api --resource-group my-rg

# Common issues:
# - Wrong image name/tag
# - Container crashes on startup
# - Missing environment variables
```

### Can't reach the app

```bash
# Check ingress configuration
az containerapp show --name my-api --resource-group my-rg --query "properties.configuration.ingress"

# Common issues:
# - Ingress not enabled
# - Wrong target port
# - App not listening on 0.0.0.0
```

### Scaling issues

```bash
# Check current replicas
az containerapp replica list --name my-api --resource-group my-rg

# Common issues:
# - min_replicas = 0 and no traffic (expected!)
# - Reached max_replicas limit
# - Container failing health checks
```

---

## Optional: Dapr Integration

Dapr (Distributed Application Runtime) adds microservices patterns:

```
┌─────────────────────────────────────────────────────────────────┐
│                    CONTAINER APP                                 │
│                                                                  │
│   ┌─────────────────┐    ┌─────────────────────────────────┐   │
│   │   Your App      │    │   Dapr Sidecar                  │   │
│   │                 │◄──►│                                  │   │
│   │   "Save state"  │    │   • State management            │   │
│   │   "Call service"│    │   • Service invocation          │   │
│   │   "Publish msg" │    │   • Pub/sub messaging           │   │
│   │                 │    │   • Secrets                      │   │
│   └─────────────────┘    └─────────────────────────────────┘   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

**When to use Dapr:**
- Service-to-service communication
- State management (without database code)
- Pub/sub messaging patterns
- Distributed tracing

---

## Summary

**Container Apps is:**
- Serverless containers without Kubernetes complexity
- Automatically scales (even to zero!)
- Pay only for what you use
- Perfect for web apps, APIs, event processors

**Key benefits:**
- ⚡ Fast deployment (minutes, not hours)
- 💰 Cost-effective (scale to zero)
- 🔧 Less operational overhead
- 🔄 Built-in traffic splitting for safe deployments

**Best for:**
- New applications
- Microservices without complex orchestration
- Event-driven workloads
- Teams without Kubernetes expertise

**Not ideal for:**
- Complex Kubernetes workloads
- Stateful applications
- Custom operators/controllers
- When you need full cluster control
