# Landing Zone Module

This module creates the foundational infrastructure (Landing Zone) that **ALL applications share**. Deploy this **ONCE**, and all application teams connect to it.

## What is a Landing Zone?

A Landing Zone is the shared infrastructure foundation that includes:
- ✅ **Virtual Network (VNet)** - Network isolation with planned IP ranges
- ✅ **Subnets** - Separate network segments for AKS, apps, data
- ✅ **Network Security Groups (NSGs)** - Centralized firewall rules
- ✅ **Log Analytics Workspace** - Centralized logging for all applications
- ✅ **Application Insights** (Optional) - Application performance monitoring
- ✅ **NAT Gateway** (Optional) - Outbound internet access from private subnets

## Why Use This Module?

**Without Landing Zone** (Each team creates their own):
- ❌ IP address conflicts
- ❌ Multiple Log Analytics workspaces (no unified view)
- ❌ Inconsistent security rules
- ❌ Higher costs (duplicate networking)
- ❌ Teams cannot communicate across apps

**With Landing Zone** (Shared foundation):
- ✅ No IP conflicts (centrally managed)
- ✅ ONE Log Analytics (unified monitoring)
- ✅ Consistent security baseline
- ✅ Cost optimized (shared infrastructure)
- ✅ Apps can communicate within VNet

## Usage

### Basic Example

```hcl
module "landing_zone" {
  source = "../../modules/landing-zone"

  resource_group_name = "myorg-landingzone-rg-dev"
  location            = "eastus"
  vnet_name           = "myorg-vnet-dev"
  address_space       = ["10.1.0.0/16"]

  subnets = {
    "aks-subnet" = {
      address_prefixes  = ["10.1.1.0/24"]
      service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault", "Microsoft.AzureCosmosDB"]
    }
    "app-subnet" = {
      address_prefixes  = ["10.1.2.0/24"]
      service_endpoints = ["Microsoft.AzureCosmosDB"]
    }
    "data-subnet" = {
      address_prefixes  = ["10.1.3.0/24"]
      service_endpoints = ["Microsoft.Sql", "Microsoft.Storage"]
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
          source_address_prefix      = "VirtualNetwork"
          destination_address_prefix = "*"
        }
      }
    }
  }

  subnet_nsg_associations = {
    "aks-subnet" = "aks-nsg"
  }

  log_analytics_name          = "myorg-logs-dev"
  log_analytics_retention_days = 30

  tags = {
    ManagedBy   = "Terraform"
    Environment = "dev"
    Project     = "landing-zone"
  }
}
```

### Using Landing Zone Outputs in Application Modules

```hcl
# Deploy AKS using Landing Zone
module "aks" {
  source = "../../modules/aks"

  cluster_name = "myorg-aks-dev"
  location     = module.landing_zone.resource_group_location

  # Use subnet from Landing Zone
  subnet_id = module.landing_zone.subnet_ids["aks-subnet"]

  # Send logs to Landing Zone Log Analytics
  log_analytics_workspace_id = module.landing_zone.log_analytics_workspace_id

  tags = module.landing_zone.tags
}

# Deploy Cosmos DB using Landing Zone
module "cosmosdb" {
  source = "../../modules/cosmosdb"

  account_name = "myorg-cosmos-dev"
  location     = module.landing_zone.resource_group_location

  # Private access only from Landing Zone subnet
  virtual_network_rules = [
    module.landing_zone.subnet_ids["app-subnet"]
  ]

  # Send diagnostics to Landing Zone Log Analytics
  log_analytics_workspace_id = module.landing_zone.log_analytics_workspace_id

  tags = module.landing_zone.tags
}
```

### With Application Insights

```hcl
module "landing_zone" {
  source = "../../modules/landing-zone"

  # ... basic config ...

  create_application_insights = true
  application_insights_name   = "myorg-insights-dev"
}
```

### With NAT Gateway

```hcl
module "landing_zone" {
  source = "../../modules/landing-zone"

  # ... basic config ...

  create_nat_gateway = true
  nat_gateway_subnet_associations = {
    "nat-aks" = "aks-subnet"
  }
}
```

## Inputs

| Name | Description | Type | Required | Default |
|------|-------------|------|----------|---------|
| `resource_group_name` | Name of the resource group | string | Yes | - |
| `location` | Azure region | string | Yes | - |
| `vnet_name` | Name of the virtual network | string | Yes | - |
| `address_space` | VNet address space | list(string) | Yes | - |
| `subnets` | Map of subnets to create | map(object) | Yes | - |
| `log_analytics_name` | Name of Log Analytics workspace | string | Yes | - |
| `tags` | Tags to apply to all resources | map(string) | Yes | - |
| `dns_servers` | Custom DNS servers | list(string) | No | [] |
| `network_security_groups` | Map of NSGs with rules | map(object) | No | {} |
| `subnet_nsg_associations` | Subnet to NSG mappings | map(string) | No | {} |
| `log_analytics_sku` | Log Analytics SKU | string | No | "PerGB2018" |
| `log_analytics_retention_days` | Log retention in days (30-730) | number | No | 30 |
| `create_application_insights` | Create App Insights | bool | No | false |
| `application_insights_name` | App Insights name | string | No | "" |
| `create_nat_gateway` | Create NAT Gateway | bool | No | false |
| `nat_gateway_subnet_associations` | Subnets for NAT Gateway | map(string) | No | {} |

## Outputs

| Name | Description |
|------|-------------|
| `resource_group_name` | Landing Zone resource group name |
| `resource_group_id` | Landing Zone resource group ID |
| `vnet_id` | Virtual network ID |
| `vnet_name` | Virtual network name |
| `subnet_ids` | Map of subnet names to IDs |
| `nsg_ids` | Map of NSG names to IDs |
| `log_analytics_workspace_id` | Log Analytics workspace ID |
| `log_analytics_workspace_name` | Log Analytics workspace name |
| `application_insights_id` | Application Insights ID (if created) |
| `nat_gateway_id` | NAT Gateway ID (if created) |
| `nat_gateway_public_ip` | NAT Gateway public IP (if created) |

## Architecture

```
Landing Zone (Shared Foundation)
│
├── Resource Group
│   └── All resources below live here
│
├── Virtual Network (10.1.0.0/16)
│   ├── aks-subnet (10.1.1.0/24)
│   │   └── NSG: aks-nsg
│   ├── app-subnet (10.1.2.0/24)
│   └── data-subnet (10.1.3.0/24)
│
├── Log Analytics Workspace
│   └── All apps send logs here
│
├── Application Insights (optional)
│   └── App performance monitoring
│
└── NAT Gateway (optional)
    └── Outbound internet access
```

## Best Practices

1. **Deploy Once Per Environment**
   - Create one Landing Zone for dev, one for staging, one for prod
   - All teams in that environment share it

2. **Plan IP Address Space**
   - Use non-overlapping ranges per environment
   - Dev: 10.1.0.0/16, Staging: 10.2.0.0/16, Prod: 10.3.0.0/16

3. **Separate Subnets by Workload Type**
   - AKS nodes: dedicated subnet
   - Container Apps: dedicated subnet
   - Databases/data services: dedicated subnet

4. **Use Service Endpoints**
   - Enable service endpoints on subnets for secure Azure service access
   - Avoids public internet traffic

5. **Consistent Tagging**
   - Pass standardized tags from global_standards module
   - Enables cost tracking and governance

## Deployment Order

```
1. Deploy Landing Zone (this module)
   └── Creates: VNet, Subnets, NSGs, Log Analytics

2. Deploy Applications
   ├── AKS Cluster → uses subnet_ids["aks-subnet"]
   ├── Container Apps → uses subnet_ids["app-subnet"]
   └── Cosmos DB → uses subnet_ids["app-subnet"]
```

## Examples

See the `examples/` folder for complete deployment examples:
- `examples/landing-zone/` - Full Landing Zone setup
- `examples/aks-on-landing-zone/` - AKS using Landing Zone
- `examples/container-apps-on-landing-zone/` - Container Apps using Landing Zone

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| azurerm | ~> 3.80.0 |

## Related Modules

- [aks](../aks/) - Azure Kubernetes Service
- [container-app](../container-app/) - Azure Container Apps
- [cosmosdb](../cosmosdb/) - Azure Cosmos DB
- [networking](../networking/) - Lower-level networking module (Landing Zone uses similar patterns)
