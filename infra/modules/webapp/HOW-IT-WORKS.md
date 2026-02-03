# App Service (WebApp Module) - How It Works

A beginner-friendly guide to Azure App Service. The easiest way to host web applications!

---

## What is App Service?

**Simple explanation:** App Service is like a hotel for your code. You bring your application, Azure handles everything else (servers, patching, scaling).

```
Self-managed server:              App Service:
────────────────────              ─────────────
You buy the server                Just upload your code
You install the OS                Azure manages the OS
You patch security updates        Azure handles updates
You configure networking          Azure configures networking
You worry about scaling           Azure scales for you

Lots of work!                     Focus on your app!
```

---

## Why App Service?

### The Problem with Managing Servers

```
What you THINK you'll do:          What you ACTUALLY do:
────────────────────────           ────────────────────
Write code                         Write code
Deploy                             Set up servers
Done!                              Configure OS
                                   Install dependencies
                                   Set up SSL certificates
                                   Configure load balancing
                                   Monitor for attacks
                                   Patch security holes
                                   Wake up at 3am when it crashes
                                   ...
```

### The App Service Solution

```
What you do:                       What Azure does:
────────────                       ────────────────
Write code                         Provides managed servers
Upload/deploy                      Handles OS patching
Configure settings                 Manages SSL certificates
Done! ✓                            Auto-scales when busy
                                   Monitors and alerts
                                   99.95% uptime SLA
```

---

## When to Use App Service

### Decision Guide

```
Is your app a traditional web app or API?
         │
         ├── YES → Do you need containers?
         │              │
         │              ├── NO → Use App Service ✅
         │              │
         │              └── YES → Need Kubernetes features?
         │                              │
         │                              ├── YES → Use AKS
         │                              │
         │                              └── NO → Use Container Apps
         │
         └── NO → What kind of app?
                       │
                       ├── Event-driven/serverless → Azure Functions
                       │
                       ├── Microservices → Container Apps or AKS
                       │
                       └── Static website → Azure Static Web Apps
```

### App Service is Great For:

```
✅ Traditional web applications (.NET, Java, Node.js, Python, PHP)
✅ REST APIs
✅ Backend for mobile apps
✅ Line-of-business applications
✅ WordPress and CMS sites
✅ Quick deployments from Git
```

### Consider Alternatives For:

```
⚠️ Complex microservices → Use Container Apps or AKS
⚠️ Need to scale to zero → Use Container Apps or Functions
⚠️ Full container control → Use AKS
⚠️ Event-driven workloads → Use Azure Functions
```

---

## Key Concepts (Plain English)

### 1. App Service Plan

**What:** The "hotel" that hosts your apps. Defines the size and features.

**Why:** Multiple apps can share one plan (cost effective!).

```
App Service Plan = The Hotel Building
┌─────────────────────────────────────────────────────────────────┐
│                    APP SERVICE PLAN (P1V3)                       │
│                    (2 vCPU, 8 GB RAM)                           │
│                                                                  │
│   ┌─────────────────┐  ┌─────────────────┐  ┌───────────────┐  │
│   │   Web App 1     │  │   Web App 2     │  │   API App     │  │
│   │   (mysite.com)  │  │   (blog.com)    │  │   (api.com)   │  │
│   │                 │  │                 │  │               │  │
│   │   Uses: 0.5 CPU │  │   Uses: 0.3 CPU │  │  Uses: 1 CPU  │  │
│   │         2 GB    │  │         1 GB    │  │       3 GB    │  │
│   └─────────────────┘  └─────────────────┘  └───────────────┘  │
│                                                                  │
│   Total used: 1.8 vCPU, 6 GB RAM (still have headroom!)        │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 2. Web App

**What:** Your actual application. Lives inside an App Service Plan.

**Why:** This is where your code runs!

### 3. Deployment Slots (Standard tier+)

**What:** Separate instances of your app for testing before going live.

**Why:** Deploy and test without affecting users.

```
Production Slot (myapp.azurewebsites.net)
├── Current live version (v1.0)
└── Users are using this

Staging Slot (myapp-staging.azurewebsites.net)
├── New version (v2.0)
└── Testing here

After testing, "swap" them:
- Staging becomes Production (instant!)
- Production becomes Staging (for rollback)

Zero downtime deployment!
```

---

## Supported Languages and Frameworks

```
LINUX (Recommended):              WINDOWS:
────────────────────              ────────
.NET Core 6, 7, 8                 .NET Framework 4.8
Node.js 14, 16, 18, 20           .NET Core 6, 7, 8
Python 3.8, 3.9, 3.10, 3.11      Node.js 14, 16, 18, 20
Java 8, 11, 17, 21               Java 8, 11, 17
PHP 8.0, 8.1, 8.2                PHP 8.0, 8.1
Go 1.19, 1.20, 1.21              
Ruby 2.7, 3.0, 3.1               

Custom Containers:
- Bring your own Docker image!
```

---

## How Deployment Works

### Option 1: Git Push (Simplest)

```
You:
$ git push azure main

Azure:
1. Receives your code
2. Detects language (Node.js? Python? .NET?)
3. Installs dependencies (npm install, pip install, etc.)
4. Builds your app
5. Starts it up
6. Routes traffic to it

Done in ~2-5 minutes!
```

### Option 2: CI/CD Pipeline (Recommended)

```
GitHub/Azure DevOps Pipeline:
┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│   Push code → Build → Test → Deploy to Staging → Swap to Prod  │
│                                                                  │
│   Automatic, repeatable, safe!                                  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Option 3: Container Deployment

```
You:
1. Build Docker image
2. Push to Azure Container Registry
3. Configure App Service to use your image

Azure:
1. Pulls your image
2. Runs container
3. Routes traffic

Good for: Custom runtimes, complex dependencies
```

---

## How Your App Handles Traffic

```
User types: myapp.azurewebsites.net
                    │
                    ▼
┌─────────────────────────────────────────────────────────────────┐
│                    AZURE FRONT DOOR (Optional)                   │
│                 (Global load balancing, WAF)                     │
└─────────────────────────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────────────────────┐
│                    APP SERVICE                                   │
│                                                                  │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │              LOAD BALANCER (Built-in)                    │   │
│   │                                                          │   │
│   │   Distributes traffic across instances                   │   │
│   └─────────────────────────┬───────────────────────────────┘   │
│                             │                                    │
│              ┌──────────────┼──────────────┐                    │
│              ▼              ▼              ▼                    │
│         Instance 1     Instance 2     Instance 3                │
│         (Your app)     (Your app)     (Your app)                │
│                                                                  │
│         Azure automatically manages these instances!            │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Scaling: Handle More Traffic

### Scale Up (Bigger Server)

```
Before: B1 (1 vCPU, 1.75 GB RAM)
        │
        │ "My app is slow!"
        ▼
After:  P1V3 (2 vCPU, 8 GB RAM)

More power per instance!
```

### Scale Out (More Servers)

```
Before: 1 instance
        │
        │ "Too many users!"
        ▼
After:  5 instances

Traffic distributed across all instances!
```

### Auto-Scale (Automatic!)

```
┌─────────────────────────────────────────────────────────────────┐
│                    AUTO-SCALE RULES                              │
│                                                                  │
│   IF CPU > 70% for 5 minutes THEN add 1 instance               │
│   IF CPU < 30% for 5 minutes THEN remove 1 instance            │
│   MIN instances: 2                                              │
│   MAX instances: 10                                             │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘

Morning (low traffic):  2 instances
Lunch rush:             6 instances (auto-scaled!)
Night:                  2 instances (auto-scaled down!)
```

---

## Configuration: App Settings

### How to Configure Your App

Instead of config files, use App Settings:

```
Azure Portal / Terraform:
┌─────────────────────────────────────────────────────────────────┐
│                    APP SETTINGS                                  │
│                                                                  │
│   DATABASE_URL     = @Microsoft.KeyVault(SecretUri=...)        │
│   API_KEY          = @Microsoft.KeyVault(SecretUri=...)        │
│   LOG_LEVEL        = info                                       │
│   ENVIRONMENT      = production                                 │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘

Your app reads them as environment variables:
- process.env.DATABASE_URL (Node.js)
- os.environ['DATABASE_URL'] (Python)
- Environment.GetEnvironmentVariable("DATABASE_URL") (C#)
```

### Connection Strings (For Databases)

```hcl
connection_strings = {
  "DefaultConnection" = {
    type  = "SQLAzure"
    value = "Server=tcp:mydb.database.windows.net;Database=mydb;..."
  }
}
```

---

## Using the Module

### Basic Example (Node.js App)

```hcl
module "webapp" {
  source = "../../modules/webapp"

  resource_group_name   = "myapp-rg-dev"
  location              = "eastus"
  app_service_plan_name = "myapp-plan-dev"
  webapp_name           = "myapp-web-dev"

  os_type  = "Linux"
  sku_name = "B1"  # Basic tier for dev

  linux_application_stack = {
    node_version = "18-lts"
  }

  app_settings = {
    "NODE_ENV" = "production"
    "API_URL"  = "https://api.example.com"
  }

  tags = module.global_standards.common_tags
}
```

### Production Example (With VNet)

```hcl
module "webapp" {
  source = "../../modules/webapp"

  resource_group_name   = "myapp-rg-prod"
  location              = "eastus"
  app_service_plan_name = "myapp-plan-prod"
  webapp_name           = "myapp-web-prod"

  os_type  = "Linux"
  sku_name = "P1V3"  # Premium for production

  linux_application_stack = {
    node_version = "18-lts"
  }

  # VNet integration (access private resources)
  virtual_network_subnet_id = module.landing_zone.subnet_ids["app-subnet"]
  vnet_route_all_enabled    = true

  # Keep app always running
  always_on = true

  # Health check
  health_check_path = "/health"

  # HTTPS only
  https_only          = true
  minimum_tls_version = "1.2"

  # Logging
  log_analytics_workspace_id = module.landing_zone.log_analytics_workspace_id

  app_settings = {
    "NODE_ENV"          = "production"
    "DATABASE_URL"      = "@Microsoft.KeyVault(SecretUri=https://myapp-kv.vault.azure.net/secrets/db-url)"
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = module.appinsights.connection_string
  }

  tags = module.global_standards.common_tags
}
```

### Docker Container Example

```hcl
module "webapp" {
  source = "../../modules/webapp"

  resource_group_name   = "myapp-rg-dev"
  location              = "eastus"
  app_service_plan_name = "myapp-plan-dev"
  webapp_name           = "myapp-container-dev"

  os_type  = "Linux"
  sku_name = "P1V2"

  linux_application_stack = {
    docker_image_name        = "myregistry.azurecr.io/myapp:v1.0"
    docker_registry_url      = "https://myregistry.azurecr.io"
    docker_registry_username = "myregistry"
    docker_registry_password = var.acr_password
  }

  app_settings = {
    "WEBSITES_PORT" = "8080"  # Tell Azure which port your container uses
  }

  tags = module.global_standards.common_tags
}
```

---

## Pricing Tiers Explained

```
FREE (F1):
├── Good for: Testing only
├── Limits: 60 CPU minutes/day, shared infrastructure
└── Cost: Free!

BASIC (B1, B2, B3):
├── Good for: Dev/test, low-traffic apps
├── Features: Custom domain, manual scaling
└── Cost: $13-52/month

STANDARD (S1, S2, S3):
├── Good for: Production apps
├── Features: Auto-scale, deployment slots, backups
└── Cost: $70-280/month

PREMIUM (P1V2, P2V2, P3V2):
├── Good for: High-traffic production
├── Features: VNet integration, more memory/CPU
└── Cost: $146-584/month

PREMIUM V3 (P1V3, P2V3, P3V3):
├── Good for: Best performance
├── Features: Best CPU/memory ratio
└── Cost: $150-600/month
```

### Which Tier Should I Choose?

```
Development/Testing → B1 or B2 (~$13-26/month)
Small Production → S1 (~$70/month)
Medium Production → P1V2 or P1V3 (~$150/month)
High-Traffic Production → P2V3 or P3V3 (~$300-600/month)
```

---

## Connecting to Other Services

### Accessing Key Vault Secrets

```hcl
# In app_settings, reference Key Vault directly:
app_settings = {
  "DB_PASSWORD" = "@Microsoft.KeyVault(SecretUri=https://myapp-kv.vault.azure.net/secrets/db-password)"
}

# App Service automatically fetches the secret!
# Your app just reads it as an environment variable.
```

### Accessing Private Database (VNet Integration)

```
┌─────────────────────────────────────────────────────────────────┐
│                         YOUR VNET                                │
│                                                                  │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │                    APP SUBNET                            │   │
│   │                                                          │   │
│   │   ┌───────────────────────────────────────┐             │   │
│   │   │         APP SERVICE                    │             │   │
│   │   │    (VNet integrated)                   │             │   │
│   │   │                                        │             │   │
│   │   │    virtual_network_subnet_id = ...    │             │   │
│   │   │    vnet_route_all_enabled = true       │             │   │
│   │   │                                        │             │   │
│   │   └─────────────────┬─────────────────────┘             │   │
│   │                     │                                    │   │
│   └─────────────────────┼────────────────────────────────────┘   │
│                         │                                        │
│                         │ Private connection!                    │
│                         ▼                                        │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │                   DATA SUBNET                            │   │
│   │                                                          │   │
│   │              SQL Database (Private Endpoint)             │   │
│   │                    10.1.3.50                            │   │
│   │                                                          │   │
│   └─────────────────────────────────────────────────────────┘   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘

Internet ─────X────→ SQL Database
            BLOCKED!
```

---

## Deployment Slots: Zero-Downtime Deploys

### The Problem with Direct Deployment

```
Traditional deployment:
1. Stop old version
2. Deploy new version
3. Start new version
4. Hope it works!

Users see: 503 Error (Site down during deploy)
```

### The Slot Solution

```
With deployment slots:

Production Slot: Running v1.0 (users are here)
Staging Slot: Deploy v2.0 here

1. Deploy to staging slot
2. Test staging slot thoroughly
3. "Swap" slots (instant!)
4. Production now runs v2.0
5. If something's wrong, swap back!

Users see: No downtime! ✓
```

### How to Use Slots

```bash
# Deploy to staging
az webapp deployment source config-zip \
  --resource-group myapp-rg \
  --name myapp-web \
  --slot staging \
  --src app.zip

# Test staging
curl https://myapp-web-staging.azurewebsites.net/health

# Swap to production
az webapp deployment slot swap \
  --resource-group myapp-rg \
  --name myapp-web \
  --slot staging \
  --target-slot production
```

---

## Troubleshooting

### App won't start

```
Check logs:
  az webapp log tail --resource-group RG --name WEBAPP

Common causes:
- Wrong startup command
- Missing dependencies
- App crashes on startup
- Wrong port (check WEBSITES_PORT for containers)
```

### App is slow

```
Checklist:
□ Enable "Always On" (prevents cold starts)
□ Scale up to a larger tier
□ Scale out to more instances
□ Check Application Insights for bottlenecks
□ Enable caching if applicable
```

### Can't connect to database

```
Checklist:
□ Is VNet integration enabled?
□ Is the database firewall configured?
□ Is the connection string correct?
□ Are you using the private endpoint?
□ Check DNS resolution (private DNS zone)
```

### 502 or 503 errors

```
Checklist:
□ Is the app healthy? Check /health endpoint
□ Is the app within resource limits?
□ Check for unhandled exceptions in logs
□ Restart the app: az webapp restart --name NAME --resource-group RG
```

---

## Summary

**App Service is:**
- A managed platform for web apps
- Azure handles servers, patching, scaling
- You focus on code, not infrastructure

**Best for:**
- Traditional web apps and APIs
- .NET, Node.js, Python, Java, PHP apps
- Teams who want simplicity over control

**Key features:**
- Multiple languages supported
- Auto-scaling
- Deployment slots (zero-downtime deploys)
- VNet integration (secure access to private resources)
- Built-in monitoring with Application Insights

**Remember:**
- Start with B1/B2 for dev
- Use P1V3 or higher for production
- Enable "Always On" to prevent cold starts
- Use deployment slots for safe deployments
- Connect to Key Vault for secrets (no passwords in code!)
