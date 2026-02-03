# Networking Module

Create Azure Virtual Networks (VNet) with subnets, Network Security Groups (NSGs), and optional NAT Gateway. This is the foundational networking layer for all Azure workloads.

## Features

- ✅ **Virtual Network (VNet)** - Isolated network with custom IP ranges
- ✅ **Subnets** - Segmented network areas for different workload types
- ✅ **Network Security Groups (NSGs)** - Firewall rules per subnet
- ✅ **Service Endpoints** - Private connectivity to Azure services
- ✅ **Subnet Delegation** - Dedicated subnets for specific services
- ✅ **NAT Gateway** - Outbound internet access from private subnets
- ✅ **Multiple NSG Rules** - Flexible security configuration

## Usage

### Basic Example

```hcl
module "networking" {
  source = "../../modules/networking"

  network_name  = "myapp-vnet-dev"
  location      = "eastus"
  address_space = ["10.1.0.0/16"]

  subnets = {
    "app-subnet" = {
      address_prefixes  = ["10.1.1.0/24"]
      service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
    }
    "data-subnet" = {
      address_prefixes  = ["10.1.2.0/24"]
      service_endpoints = ["Microsoft.Sql", "Microsoft.Storage"]
    }
  }

  tags = {
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
```

### With Network Security Groups

```hcl
module "networking" {
  source = "../../modules/networking"

  network_name  = "myapp-vnet-prod"
  location      = "eastus"
  address_space = ["10.3.0.0/16"]

  subnets = {
    "aks-subnet" = {
      address_prefixes  = ["10.3.1.0/23"]
      service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault", "Microsoft.AzureCosmosDB"]
    }
    "app-subnet" = {
      address_prefixes  = ["10.3.3.0/24"]
      service_endpoints = ["Microsoft.Storage"]
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
          source_port_range          = "*"
          destination_port_range     = "443"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        }
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
        "deny-all-inbound" = {
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
    "app-nsg" = {
      security_rules = {
        "allow-vnet-https" = {
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "443"
          source_address_prefix      = "VirtualNetwork"
          destination_address_prefix = "*"
        }
      }
    }
  }

  subnet_nsg_associations = {
    "aks-subnet" = "aks-nsg"
    "app-subnet" = "app-nsg"
  }

  tags = module.global_standards.common_tags
}
```

### With Subnet Delegation (Container Apps)

```hcl
module "networking" {
  source = "../../modules/networking"

  network_name  = "containerapp-vnet"
  location      = "eastus"
  address_space = ["10.1.0.0/16"]

  subnets = {
    "container-app-subnet" = {
      address_prefixes = ["10.1.1.0/23"]
      delegation = {
        name         = "Microsoft.App.environments"
        service_name = "Microsoft.App/environments"
        actions      = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      }
    }
  }

  tags = module.global_standards.common_tags
}
```

### With NAT Gateway

```hcl
module "networking" {
  source = "../../modules/networking"

  network_name  = "myapp-vnet-prod"
  location      = "eastus"
  address_space = ["10.3.0.0/16"]

  subnets = {
    "aks-subnet" = {
      address_prefixes  = ["10.3.1.0/23"]
      service_endpoints = ["Microsoft.Storage"]
    }
  }

  # Enable NAT Gateway for outbound internet
  create_nat_gateway = true

  tags = module.global_standards.common_tags
}

# Access the NAT Gateway public IP
output "nat_gateway_ip" {
  value = module.networking.nat_gateway_public_ip
}
```

## Inputs

| Name | Description | Type | Required | Default |
|------|-------------|------|----------|---------|
| `network_name` | Name of the virtual network | string | Yes | - |
| `location` | Azure region | string | Yes | - |
| `address_space` | VNet address space | list(string) | No | ["10.0.0.0/16"] |
| `subnets` | Map of subnets to create | map(object) | Yes | - |
| `network_security_groups` | Map of NSGs with security rules | map(object) | No | {} |
| `subnet_nsg_associations` | Subnet to NSG associations | map(string) | No | {} |
| `create_nat_gateway` | Create NAT Gateway | bool | No | false |
| `tags` | Resource tags | map(string) | Yes | - |

### Subnet Object

```hcl
{
  address_prefixes  = ["10.1.1.0/24"]          # CIDR ranges
  service_endpoints = ["Microsoft.Storage"]     # Optional
  delegation = {                                # Optional
    name         = "delegation-name"
    service_name = "Microsoft.App/environments"
    actions      = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
  }
}
```

### NSG Object

```hcl
{
  security_rules = {
    "rule-name" = {
      priority                   = 100
      direction                  = "Inbound"  # or "Outbound"
      access                     = "Allow"     # or "Deny"
      protocol                   = "Tcp"       # or "Udp", "*"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  }
}
```

## Outputs

| Name | Description |
|------|-------------|
| `resource_group_name` | Network resource group name |
| `resource_group_id` | Network resource group ID |
| `vnet_id` | Virtual network ID |
| `vnet_name` | Virtual network name |
| `vnet_address_space` | VNet address space |
| `subnet_ids` | Map of subnet names to IDs |
| `subnet_address_prefixes` | Map of subnet names to address prefixes |
| `nsg_ids` | Map of NSG names to IDs |
| `nat_gateway_id` | NAT Gateway ID (if created) |
| `nat_gateway_public_ip` | NAT Gateway public IP (if created) |

## Architecture

```
Virtual Network (10.1.0.0/16)
│
├── Subnets
│   ├── aks-subnet (10.1.1.0/24)
│   │   ├── NSG: aks-nsg
│   │   └── Service Endpoints: Storage, KeyVault
│   ├── app-subnet (10.1.2.0/24)
│   │   ├── NSG: app-nsg
│   │   └── Service Endpoints: Storage, CosmosDB
│   └── data-subnet (10.1.3.0/24)
│       └── Service Endpoints: SQL, Storage
│
├── Network Security Groups (NSGs)
│   ├── aks-nsg
│   │   ├── Allow HTTPS (443)
│   │   ├── Allow HTTP (80)
│   │   └── Deny All Inbound (priority 4096)
│   └── app-nsg
│       └── Allow HTTPS from VNet
│
└── NAT Gateway (optional)
    ├── Public IP: 20.x.x.x
    └── Associated Subnets: aks-subnet
```

## Best Practices

### 1. IP Address Planning

Use non-overlapping IP ranges per environment:

```hcl
# Dev
address_space = ["10.1.0.0/16"]  # 10.1.0.0 - 10.1.255.255

# Staging
address_space = ["10.2.0.0/16"]  # 10.2.0.0 - 10.2.255.255

# Prod
address_space = ["10.3.0.0/16"]  # 10.3.0.0 - 10.3.255.255
```

### 2. Subnet Sizing

| Workload | Size | Range | Usable IPs |
|----------|------|-------|------------|
| Small (dev) | /24 | 10.1.1.0/24 | 251 IPs |
| Medium (staging) | /23 | 10.2.1.0/23 | 507 IPs |
| Large (prod) | /22 | 10.3.1.0/22 | 1019 IPs |

Azure reserves 5 IPs per subnet.

### 3. NSG Rule Priorities

```hcl
# Lower number = higher priority
100-199  # Allow specific traffic
200-299  # Custom application rules
4000+    # Deny rules (catch-all)
```

### 4. Service Endpoints

Use service endpoints for secure Azure service access:

```hcl
service_endpoints = [
  "Microsoft.Storage",           # Azure Storage
  "Microsoft.Sql",              # Azure SQL Database
  "Microsoft.KeyVault",         # Azure Key Vault
  "Microsoft.AzureCosmosDB",    # Cosmos DB
  "Microsoft.EventHub",         # Event Hubs
  "Microsoft.ServiceBus"        # Service Bus
]
```

### 5. Subnet Delegation

Some services require dedicated subnets:

| Service | Delegation Required |
|---------|---------------------|
| Container Apps | `Microsoft.App/environments` |
| Azure SQL MI | `Microsoft.Sql/managedInstances` |
| Azure NetApp Files | `Microsoft.NetApp/volumes` |
| Azure Databricks | `Microsoft.Databricks/workspaces` |

### 6. NAT Gateway Usage

Use NAT Gateway when:
- ✅ Need static outbound IP
- ✅ High outbound connection volume
- ✅ Avoid SNAT port exhaustion

Skip NAT Gateway when:
- ❌ No outbound internet needed
- ❌ Using service endpoints only
- ❌ Cost-sensitive dev environments

## Security Recommendations

### Production NSG Rules

```hcl
network_security_groups = {
  "prod-nsg" = {
    security_rules = {
      # 1. Allow specific inbound
      "allow-https" = {
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        destination_port_range     = "443"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
      }
      
      # 2. Allow internal VNet traffic
      "allow-vnet" = {
        priority                   = 200
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "*"
        source_address_prefix      = "VirtualNetwork"
        destination_address_prefix = "VirtualNetwork"
      }
      
      # 3. Deny everything else
      "deny-all-inbound" = {
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

## Troubleshooting

**Problem:** Can't connect to Azure service (e.g., Storage)
- ✅ Check service endpoints enabled on subnet
- ✅ Verify NSG allows outbound to `AzureCloud` service tag
- ✅ Check resource firewall allows VNet

**Problem:** Outbound connections failing
- ✅ Enable NAT Gateway
- ✅ Check NSG outbound rules
- ✅ Verify no explicit deny rules

**Problem:** Subnet is full
- ✅ Create larger subnet in planning phase
- ✅ Use /23 instead of /24 (doubles capacity)

## Examples

### Multi-Environment Setup

```hcl
# Development
module "network_dev" {
  source = "../../modules/networking"
  
  network_name  = "myapp-vnet-dev"
  address_space = ["10.1.0.0/16"]
  
  # Small subnets for dev
  subnets = {
    "aks-subnet" = {
      address_prefixes = ["10.1.1.0/24"]  # 251 IPs
    }
  }
  
  create_nat_gateway = false  # Save cost
  tags = module.global_standards.common_tags
}

# Production
module "network_prod" {
  source = "../../modules/networking"
  
  network_name  = "myapp-vnet-prod"
  address_space = ["10.3.0.0/16"]
  
  # Large subnets for prod
  subnets = {
    "aks-subnet" = {
      address_prefixes = ["10.3.1.0/22"]  # 1019 IPs
    }
  }
  
  create_nat_gateway = true  # Static outbound IP
  tags = module.global_standards.common_tags
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| azurerm | ~> 3.80.0 |

## Related Modules

- [landing-zone](../landing-zone/) - Comprehensive networking foundation
- [aks](../aks/) - Requires subnet_id output
- [container-app](../container-app/) - Optional VNet integration
- [cosmosdb](../cosmosdb/) - Uses service endpoints
