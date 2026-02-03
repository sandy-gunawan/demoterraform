# Container App Module

Deploy serverless containerized applications using Azure Container Apps. This module provisions a Container App Environment and one or more Container Apps with auto-scaling, ingress, and monitoring.

## Features

- ✅ **Serverless Container Hosting** - No infrastructure management required
- ✅ **Auto-scaling** - Scale from 0 to N replicas based on HTTP traffic or custom metrics
- ✅ **Managed Ingress** - Built-in HTTPS endpoints with automatic TLS certificates
- ✅ **Integrated Logging** - Automatic integration with Log Analytics
- ✅ **Secrets Management** - Secure environment variables from secrets
- ✅ **Blue-Green Deployments** - Support for Single or Multiple revision modes
- ✅ **Dapr Integration** - Optional sidecar for microservices patterns

## When to Use Container Apps

| Use Container Apps For | Use AKS For |
|------------------------|-------------|
| Serverless workloads (scale to zero) | Long-running services |
| Event-driven apps | Complex networking requirements |
| Simple microservices | Full Kubernetes control needed |
| Quick deployment from container image | Custom operators/controllers |
| HTTP-triggered APIs | Stateful workloads |

## Usage

### Basic Example

```hcl
module "container_app" {
  source = "../../modules/container-app"

  app_name        = "myapp"
  location        = "eastus"
  container_image = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"

  # Auto-scaling
  min_replicas = 0  # Scale to zero when idle
  max_replicas = 10

  # Resource allocation
  container_cpu    = 0.5
  container_memory = "1Gi"

  # Ingress
  enable_ingress = true
  target_port    = 80

  tags = {
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
```

### With Environment Variables

```hcl
module "container_app" {
  source = "../../modules/container-app"

  app_name        = "myapi"
  location        = "eastus"
  container_image = "myacr.azurecr.io/api:v1.0"

  # Public environment variables
  environment_variables = {
    "API_VERSION" = "v1"
    "LOG_LEVEL"   = "info"
  }

  # Secrets
  secret_environment_variables = {
    "DATABASE_CONNECTION" = "Server=mydb;Database=prod;..."
    "API_KEY"             = "secret-api-key-value"
  }

  tags = module.global_standards.common_tags
}
```

### With VNet Integration (Private Container Apps)

```hcl
module "container_app" {
  source = "../../modules/container-app"

  app_name = "internal-api"
  location = "eastus"

  # Use existing VNet subnet
  subnet_id = module.networking.subnet_ids["app-subnet"]

  # Internal-only ingress
  enable_ingress      = true
  ingress_external    = false  # Not exposed to internet
  target_port         = 8080

  container_image = "myacr.azurecr.io/internal-api:latest"

  tags = module.global_standards.common_tags
}
```

### With Dapr Enabled

```hcl
module "container_app" {
  source = "../../modules/container-app"

  app_name        = "order-service"
  location        = "eastus"
  container_image = "myacr.azurecr.io/order-service:latest"

  # Enable Dapr sidecar
  enable_dapr      = true
  dapr_app_id      = "order-service"
  dapr_app_port    = 3000
  dapr_app_protocol = "http"

  tags = module.global_standards.common_tags
}
```

### Multiple Revisions (Blue-Green Deployment)

```hcl
module "container_app" {
  source = "../../modules/container-app"

  app_name        = "web-app"
  location        = "eastus"
  container_image = "myacr.azurecr.io/webapp:v2.0"

  # Multiple revision mode
  revision_mode = "Multiple"

  # Traffic splitting between revisions
  traffic_weight = {
    "web-app--v1" = 90  # 90% to old version
    "web-app--v2" = 10  # 10% to new version (canary)
  }

  tags = module.global_standards.common_tags
}
```

## Inputs

| Name | Description | Type | Required | Default |
|------|-------------|------|----------|---------|
| `app_name` | Name of the container app | string | Yes | - |
| `location` | Azure region | string | Yes | - |
| `container_image` | Container image (registry/image:tag) | string | Yes | - |
| `container_name` | Name of the container | string | No | "main" |
| `container_cpu` | CPU allocation (0.25, 0.5, 1.0, 2.0) | number | No | 0.5 |
| `container_memory` | Memory allocation (0.5Gi, 1Gi, 2Gi, 4Gi) | string | No | "1Gi" |
| `min_replicas` | Minimum replicas (0 for scale to zero) | number | No | 1 |
| `max_replicas` | Maximum replicas | number | No | 10 |
| `enable_ingress` | Enable HTTP ingress | bool | No | true |
| `ingress_external` | Expose ingress to internet | bool | No | true |
| `target_port` | Container port | number | No | 80 |
| `environment_variables` | Public environment variables | map(string) | No | {} |
| `secret_environment_variables` | Secret environment variables | map(string) | No | {} |
| `revision_mode` | Revision mode (Single or Multiple) | string | No | "Single" |
| `subnet_id` | Subnet ID for VNet integration | string | No | null |
| `enable_dapr` | Enable Dapr sidecar | bool | No | false |
| `log_retention_days` | Log Analytics retention (30-730) | number | No | 30 |
| `tags` | Resource tags | map(string) | Yes | - |

## Outputs

| Name | Description |
|------|-------------|
| `container_app_id` | Container App resource ID |
| `container_app_fqdn` | Fully qualified domain name |
| `container_app_url` | HTTPS URL (https://app.domain.com) |
| `environment_id` | Container App Environment ID |
| `latest_revision_name` | Latest revision name |

## Cost Considerations

Container Apps are billed for:
- **vCPU-seconds** - CPU usage per second
- **Memory GiB-seconds** - Memory usage per second
- **HTTP requests** - Per million requests

**Monthly estimate for small app:**
- 0.5 vCPU, 1 GiB memory
- Running 24/7 with 1 replica
- ~$30-40/month

**Scale to zero** when idle to minimize costs!

## Best Practices

1. **Scale to Zero for Dev**
   ```hcl
   min_replicas = 0  # No idle cost
   ```

2. **Use Private Registries**
   ```hcl
   container_image = "myacr.azurecr.io/app:v1.0"
   # Container Apps can authenticate to ACR automatically
   ```

3. **Set Resource Limits**
   ```hcl
   container_cpu    = 0.5
   container_memory = "1Gi"
   # Prevents runaway costs
   ```

4. **Use Secrets for Sensitive Data**
   ```hcl
   secret_environment_variables = {
     "DB_PASSWORD" = var.db_password
   }
   ```

5. **Enable Logging**
   - All logs automatically go to Log Analytics
   - Query with Kusto (KQL)

6. **VNet Integration for Security**
   ```hcl
   subnet_id        = module.networking.subnet_ids["app-subnet"]
   ingress_external = false  # Internal only
   ```

## Architecture

```
Container App Environment
│
├── Log Analytics Workspace
│   └── All container logs
│
├── Container App 1
│   ├── Revision v1 (90% traffic)
│   └── Revision v2 (10% traffic)
│
├── Container App 2
│   └── Revision latest
│
└── Dapr Components (optional)
    ├── State Store
    ├── Pub/Sub
    └── Bindings
```

## Example Scenarios

### 1. Serverless API (Scale to Zero)

```hcl
module "api" {
  source = "../../modules/container-app"

  app_name        = "weather-api"
  location        = "eastus"
  container_image = "myacr.azurecr.io/weather-api:latest"

  min_replicas = 0  # Scale to zero
  max_replicas = 5

  enable_ingress = true
  target_port    = 8080

  environment_variables = {
    "CACHE_TTL" = "300"
  }

  tags = module.global_standards.common_tags
}
```

### 2. Internal Microservice

```hcl
module "order_processor" {
  source = "../../modules/container-app"

  app_name        = "order-processor"
  location        = "eastus"
  container_image = "myacr.azurecr.io/order-processor:v1.0"

  # Private only
  subnet_id        = module.networking.subnet_ids["app-subnet"]
  ingress_external = false

  # Process orders continuously
  min_replicas = 2
  max_replicas = 20

  enable_dapr   = true
  dapr_app_id   = "order-processor"
  dapr_app_port = 3000

  tags = module.global_standards.common_tags
}
```

### 3. Web Frontend (Always Running)

```hcl
module "web_frontend" {
  source = "../../modules/container-app"

  app_name        = "web-app"
  location        = "eastus"
  container_image = "myacr.azurecr.io/web:v2.0"

  # Always have at least 2 instances
  min_replicas = 2
  max_replicas = 50

  enable_ingress = true
  target_port    = 3000

  environment_variables = {
    "API_ENDPOINT" = module.api.container_app_url
  }

  tags = module.global_standards.common_tags
}
```

## Troubleshooting

**Problem:** Container won't start
- Check container logs in Log Analytics
- Verify container image is accessible
- Check environment variables/secrets

**Problem:** Scale to zero not working
- Ensure `min_replicas = 0`
- Check if HTTP requests are still coming in
- Verify no background tasks keeping container alive

**Problem:** Can't access from internet
- Set `ingress_external = true`
- Check NSG rules if using VNet integration

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| azurerm | ~> 3.80.0 |

## Related Modules

- [aks](../aks/) - For complex Kubernetes workloads
- [networking](../networking/) - VNet integration
- [landing-zone](../landing-zone/) - Shared foundation
