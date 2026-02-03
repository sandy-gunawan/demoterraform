# WebApp Module - Azure App Service

Deploy web applications, APIs, and backends using Azure App Service. Supports both Linux and Windows with built-in autoscaling, CI/CD, and managed runtimes.

## Features

- ✅ **Managed Platform** - No OS patching or infrastructure management
- ✅ **Multiple Runtimes** - .NET, Node.js, Python, Java, PHP, Go, Docker
- ✅ **Built-in CI/CD** - GitHub Actions, Azure DevOps integration
- ✅ **Auto-scaling** - Scale up/down or in/out based on rules
- ✅ **Custom Domains & SSL** - Free SSL certificates
- ✅ **VNet Integration** - Private connectivity to other Azure services
- ✅ **Managed Identity** - Passwordless authentication
- ✅ **Deployment Slots** - Blue-green deployments (Standard tier+)

## When to Use App Service

| Use App Service For | Use Container Apps For | Use AKS For |
|---------------------|------------------------|-------------|
| Traditional web apps | Serverless containers | Complex orchestration |
| Established frameworks (.NET, Java) | Event-driven microservices | Full Kubernetes control |
| Always-on services | Scale to zero | Multi-tenant platforms |
| Stateful applications | HTTP-triggered functions | Custom operators |

## Usage

### Basic Node.js App

```hcl
module "webapp" {
  source = "../../modules/webapp"

  resource_group_name   = "myapp-rg-dev"
  location              = "eastus"
  app_service_plan_name = "myapp-plan-dev"
  webapp_name           = "myapp-web-dev"

  os_type  = "Linux"
  sku_name = "B1"  # Basic tier

  linux_application_stack = {
    node_version = "18-lts"
  }

  app_settings = {
    "NODE_ENV"        = "production"
    "PORT"            = "8080"
    "API_BASE_URL"    = "https://api.example.com"
  }

  tags = module.global_standards.common_tags
}
```

### .NET App with VNet Integration

```hcl
module "webapp" {
  source = "../../modules/webapp"

  resource_group_name   = "myapp-rg-prod"
  location              = "eastus"
  app_service_plan_name = "myapp-plan-prod"
  webapp_name           = "myapp-web-prod"

  os_type  = "Linux"
  sku_name = "P1V3"  # Premium V3 (production)

  linux_application_stack = {
    dotnet_version = "8.0"
  }

  # VNet integration
  virtual_network_subnet_id = module.networking.subnet_ids["app-subnet"]
  vnet_route_all_enabled    = true

  # Production settings
  always_on     = true
  https_only    = true
  http2_enabled = true

  # Health check
  health_check_path = "/health"

  # Send logs to Log Analytics
  log_analytics_workspace_id = azurerm_log_analytics_workspace.prod.id

  tags = module.global_standards.common_tags
}
```

### Docker Container App

```hcl
module "webapp" {
  source = "../../modules/webapp"

  resource_group_name   = "myapp-rg-prod"
  location              = "eastus"
  app_service_plan_name = "myapp-plan-prod"
  webapp_name           = "myapp-api-prod"

  os_type  = "Linux"
  sku_name = "P1V2"

  linux_application_stack = {
    docker_image_name        = "myacr.azurecr.io/api:v1.0"
    docker_registry_url      = "https://myacr.azurecr.io"
    docker_registry_username = "myacr"
    docker_registry_password = var.acr_password
  }

  app_settings = {
    "WEBSITES_PORT" = "8080"  # Container listens on 8080
  }

  tags = module.global_standards.common_tags
}
```

### Python Flask API

```hcl
module "webapp" {
  source = "../../modules/webapp"

  resource_group_name   = "myapi-rg-dev"
  location              = "eastus"
  app_service_plan_name = "myapi-plan-dev"
  webapp_name           = "myapi-dev"

  os_type  = "Linux"
  sku_name = "B2"

  linux_application_stack = {
    python_version = "3.11"
  }

  app_settings = {
    "FLASK_APP"   = "app.py"
    "FLASK_ENV"   = "production"
  }

  connection_strings = {
    "DefaultConnection" = {
      type  = "SQLAzure"
      value = "Server=tcp:mydb.database.windows.net,1433;Database=mydb;..."
    }
  }

  tags = module.global_standards.common_tags
}
```

### With IP Restrictions (Firewall)

```hcl
module "webapp" {
  source = "../../modules/webapp"

  resource_group_name   = "myapp-rg-prod"
  location              = "eastus"
  app_service_plan_name = "myapp-plan-prod"
  webapp_name           = "myapp-internal-prod"

  os_type  = "Linux"
  sku_name = "P1V3"

  linux_application_stack = {
    node_version = "18-lts"
  }

  # IP restrictions (firewall)
  ip_restrictions = {
    "allow-office" = {
      action     = "Allow"
      priority   = 100
      ip_address = "203.0.113.0/24"
    }
    "allow-vnet" = {
      action                    = "Allow"
      priority                  = 200
      virtual_network_subnet_id = module.networking.subnet_ids["aks-subnet"]
    }
  }

  public_network_access_enabled = false  # Block all except allowed IPs

  tags = module.global_standards.common_tags
}
```

### Java Spring Boot App

```hcl
module "webapp" {
  source = "../../modules/webapp"

  resource_group_name   = "myapp-rg-prod"
  location              = "eastus"
  app_service_plan_name = "myapp-plan-prod"
  webapp_name           = "myapp-api-prod"

  os_type  = "Linux"
  sku_name = "P2V3"

  linux_application_stack = {
    java_version = "17"
  }

  app_settings = {
    "JAVA_OPTS"                      = "-Xms512m -Xmx1024m"
    "SPRING_PROFILES_ACTIVE"         = "prod"
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.prod.connection_string
  }

  always_on                  = true
  health_check_path          = "/actuator/health"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.prod.id

  tags = module.global_standards.common_tags
}
```

## Inputs

| Name | Description | Type | Required | Default |
|------|-------------|------|----------|---------|
| `resource_group_name` | Resource group name | string | Yes | - |
| `location` | Azure region | string | Yes | - |
| `app_service_plan_name` | App Service Plan name | string | Yes | - |
| `webapp_name` | Web app name (globally unique) | string | Yes | - |
| `os_type` | OS type (Linux or Windows) | string | No | "Linux" |
| `sku_name` | SKU (B1, B2, S1, P1V2, P1V3, etc.) | string | No | "B1" |
| `always_on` | Keep app always on | bool | No | false |
| `https_only` | Force HTTPS | bool | No | true |
| `http2_enabled` | Enable HTTP/2 | bool | No | true |
| `minimum_tls_version` | Minimum TLS version | string | No | "1.2" |
| `health_check_path` | Health check endpoint | string | No | null |
| `virtual_network_subnet_id` | Subnet ID for VNet integration | string | No | null |
| `vnet_route_all_enabled` | Route all traffic through VNet | bool | No | false |
| `linux_application_stack` | Linux runtime configuration | object | No | null |
| `windows_application_stack` | Windows runtime configuration | object | No | null |
| `app_settings` | Environment variables | map(string) | No | {} |
| `connection_strings` | Connection strings | map(object) | No | {} |
| `ip_restrictions` | IP access restrictions | map(object) | No | {} |
| `log_analytics_workspace_id` | Log Analytics workspace ID | string | No | null |
| `tags` | Resource tags | map(string) | Yes | - |

## Outputs

| Name | Description |
|------|-------------|
| `webapp_id` | Web App resource ID |
| `webapp_name` | Web App name |
| `webapp_url` | Web App URL (https://...) |
| `webapp_default_hostname` | Default hostname |
| `webapp_identity_principal_id` | Managed identity principal ID |
| `webapp_outbound_ips` | Outbound IP addresses |
| `app_service_plan_id` | App Service Plan ID |

## SKU (Pricing Tiers)

| Tier | SKU | vCPU | Memory | Features | Use Case |
|------|-----|------|--------|----------|----------|
| **Free** | F1 | Shared | 1 GB | No custom domain, no always-on | Testing only |
| **Basic** | B1 | 1 | 1.75 GB | Custom domain, manual scale | Dev |
| **Basic** | B2 | 2 | 3.5 GB | Custom domain, manual scale | Dev/Staging |
| **Standard** | S1 | 1 | 1.75 GB | Deployment slots, autoscale | Small prod |
| **Premium V2** | P1V2 | 1 | 3.5 GB | Better CPU, VNET integration | Production |
| **Premium V3** | P1V3 | 2 | 8 GB | Best performance | Production |

**Recommendation:**
- **Dev:** B1 or B2
- **Staging:** S1 or P1V2
- **Production:** P1V3 or higher

## Supported Runtimes

### Linux
- **.NET:** 6.0, 7.0, 8.0
- **Node.js:** 14-lts, 16-lts, 18-lts, 20-lts
- **Python:** 3.8, 3.9, 3.10, 3.11, 3.12
- **Java:** 8, 11, 17, 21
- **PHP:** 8.0, 8.1, 8.2
- **Go:** 1.19, 1.20, 1.21
- **Docker:** Custom containers

### Windows
- **.NET Framework:** 4.8
- **.NET Core:** 6.0, 7.0, 8.0
- **Node.js:** 16, 18, 20
- **Java:** 8, 11, 17
- **PHP:** 8.0, 8.1
- **Python:** 3.x

## Best Practices

### 1. Always On for Production
```hcl
always_on = true  # Prevents cold starts
```

### 2. Health Checks
```hcl
health_check_path                 = "/health"
health_check_eviction_time_in_min = 10
```

### 3. Use Managed Identity
```hcl
identity_type = "SystemAssigned"
```

Then grant access to other resources:
```bash
az role assignment create \
  --role "Storage Blob Data Reader" \
  --assignee <principal_id> \
  --scope <storage_account_id>
```

### 4. VNet Integration
```hcl
virtual_network_subnet_id = subnet_id
vnet_route_all_enabled    = true
```

### 5. Enable Logging
```hcl
log_analytics_workspace_id = workspace_id
app_logs_file_system_level = "Information"
```

### 6. Use Deployment Slots (Standard+)
```hcl
# Main production slot
module "webapp_prod" { ... }

# Staging slot
resource "azurerm_linux_web_app_slot" "staging" {
  name           = "staging"
  app_service_id = module.webapp_prod.webapp_id
  # ... same config as prod ...
}
```

Swap slots after testing:
```bash
az webapp deployment slot swap \
  --name myapp-web-prod \
  --resource-group myapp-rg-prod \
  --slot staging \
  --target-slot production
```

## Common Patterns

### Pattern 1: Multi-App Shared Plan

```hcl
# One App Service Plan
resource "azurerm_service_plan" "shared" {
  name     = "shared-plan-prod"
  location = "eastus"
  os_type  = "Linux"
  sku_name = "P1V3"
}

# Multiple apps share it
module "webapp1" {
  source = "../../modules/webapp"
  app_service_plan_id = azurerm_service_plan.shared.id
  # ...
}

module "webapp2" {
  source = "../../modules/webapp"
  app_service_plan_id = azurerm_service_plan.shared.id
  # ...
}
```

### Pattern 2: Private Web App

```hcl
module "internal_webapp" {
  source = "../../modules/webapp"

  # Only accessible from VNet
  public_network_access_enabled = false
  virtual_network_subnet_id     = module.networking.subnet_ids["app-subnet"]
  vnet_route_all_enabled        = true

  # Only allow internal traffic
  ip_restrictions = {
    "allow-vnet" = {
      action                    = "Allow"
      priority                  = 100
      virtual_network_subnet_id = module.networking.subnet_ids["aks-subnet"]
    }
  }
}
```

## Troubleshooting

**Problem:** App won't start
- Check logs: `az webapp log tail --name myapp --resource-group rg`
- Verify application stack version
- Check app settings and connection strings

**Problem:** 503 Service Unavailable
- Enable `always_on = true`
- Check health endpoint returns 200 OK
- Verify sufficient App Service Plan resources

**Problem:** Can't access from VNet
- Enable VNet integration: `virtual_network_subnet_id`
- Set `vnet_route_all_enabled = true`
- Check NSG rules allow traffic

## Cost Optimization

1. **Right-size SKU:** Start with B1/B2 for dev, upgrade only if needed
2. **Shut down dev environments:** Use automation to stop/start
3. **Share App Service Plans:** Multiple apps on one plan
4. **Use Linux:** ~40% cheaper than Windows for same SKU

**Monthly costs:**
- **B1:** ~$13/month
- **B2:** ~$26/month
- **S1:** ~$70/month
- **P1V3:** ~$150/month

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| azurerm | ~> 3.80.0 |

## Related Modules

- [container-app](../container-app/) - Serverless alternative
- [aks](../aks/) - For complex container orchestration
- [security](../security/) - Key Vault for secrets
- [networking](../networking/) - VNet integration
