# Azure Enterprise Hub-Spoke Architecture Example

**Note:** This example demonstrates an **advanced enterprise architecture pattern** with hub-spoke networking across multiple subscriptions. This is DIFFERENT from the "Landing Zone" (Layer 1) concept used elsewhere in this framework.

## Overview

This example shows how to build an enterprise-grade hub-spoke network topology - a centralized architecture for large organizations with multiple applications and teams.

## What Is Hub-Spoke Architecture?

A hub-spoke architecture is an advanced networking pattern that includes:
- **Network Hub**: Centralized networking with firewall and gateway
- **Shared Services**: Common resources like monitoring, security, and identity
- **Governance**: Policies, RBAC, and compliance controls
- **Connectivity**: ExpressRoute, VPN, or public internet connectivity
- **Management**: Centralized logging, monitoring, and cost management

## Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                    Subscription: Management                   │
│  ┌────────────────────────────────────────────────────────┐  │
│  │            Hub Virtual Network (10.0.0.0/16)           │  │
│  │  ┌───────────────┐  ┌─────────────┐  ┌─────────────┐ │  │
│  │  │ Gateway       │  │ Firewall    │  │ Bastion     │ │  │
│  │  │ Subnet        │  │ Subnet      │  │ Subnet      │ │  │
│  │  └───────────────┘  └─────────────┘  └─────────────┘ │  │
│  │         │                   │                │         │  │
│  └─────────┼───────────────────┼────────────────┼─────────┘  │
│            │                   │                │             │
└────────────┼───────────────────┼────────────────┼─────────────┘
             │                   │                │
    ┌────────┴────────┐ ┌───────┴────────┐ ┌────┴─────────┐
    │                 │ │                │ │              │
┌───▼─────────────────▼─▼────────────────▼─▼──────────────▼───┐
│           Subscription: Production Workloads                  │
│  ┌────────────────────────────────────────────────────────┐  │
│  │       Spoke VNet 1 (10.1.0.0/16) - App A (AKS)        │  │
│  └────────────────────────────────────────────────────────┘  │
│  ┌────────────────────────────────────────────────────────┐  │
│  │       Spoke VNet 2 (10.2.0.0/16) - App B (Web)        │  │
│  └────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────┘
    │                   │                │
┌───▼─────────────────▼─────────────────▼──────────────────────┐
│         Subscription: Development & Testing                   │
│  ┌────────────────────────────────────────────────────────┐  │
│  │       Spoke VNet 3 (10.10.0.0/16) - Dev/Test          │  │
│  └────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────┘

         Shared Services (Log Analytics, Key Vault, ACR)
```

## Why Use This Framework for Landing Zones?

The same modular structure used for individual applications can be scaled to create enterprise landing zones:

1. **Reusable Modules**: Same networking, security, and monitoring modules
2. **Consistent Patterns**: Teams understand the structure immediately
3. **Scalable**: Easy to add new spoke networks for applications
4. **Governed**: Central policies applied automatically
5. **Cost-Effective**: Shared services reduce duplication

## Components Deployed

### Hub Network (Centralized)
- Virtual Network with hub subnets
- Azure Firewall for traffic inspection
- Azure Bastion for secure VM access
- VPN/ExpressRoute Gateway (optional)
- Network Security Groups

### Shared Services
- Log Analytics Workspace (centralized logging)
- Azure Key Vault (secrets management)
- Azure Container Registry (container images)
- Azure Cosmos DB (shared data services)

### Spoke Networks (Per Application/Team)
- Application-specific virtual networks
- Peering to hub network
- Subnet configuration
- NSG rules

### Governance
- Azure Policy assignments
- RBAC role assignments
- Resource locks
- Tagging standards

## File Structure

```
enterprise-hub-spoke/
├── main.tf              # Main configuration
├── variables.tf         # Input variables
├── terraform.tfvars     # Variable values
├── outputs.tf           # Output values
├── README.md           # This file
└── spoke-templates/    # Templates for new spokes
    ├── aks-spoke.tf
    └── webapp-spoke.tf
```

## Deployment Steps

### 1. Configure Variables

Edit `terraform.tfvars`:

```hcl
organization_name = "contoso"
location          = "southeastasia"
tenant_id         = "your-tenant-id"

# Define spoke networks
spoke_networks = {
  "production-aks" = {
    address_space = "10.1.0.0/16"
    environment   = "production"
    application   = "aks-workloads"
  }
  "production-web" = {
    address_space = "10.2.0.0/16"
    environment   = "production"
    application   = "web-services"
  }
  "dev-test" = {
    address_space = "10.10.0.0/16"
    environment   = "development"
    application   = "dev-test"
  }
}
```

### 2. Deploy Hub Network

```bash
cd examples/enterprise-hub-spoke
terraform init
terraform plan
terraform apply
```

### 3. Deploy Spoke Networks

Spoke networks are automatically created based on configuration in `terraform.tfvars`.

### 4. Add New Spoke Network

To add a new spoke network, simply add it to the `spoke_networks` map and reapply:

```hcl
spoke_networks = {
  # ... existing spokes ...
  
  "staging-api" = {
    address_space = "10.3.0.0/16"
    environment   = "staging"
    application   = "api-services"
  }
}
```

```bash
terraform apply
```

## How This Demonstrates Framework Reusability

### Same Modules, Different Scale

**Individual Application (AKS Example)**:
```hcl
module "networking" {
  source = "../../modules/networking"
  # Single VNet for one application
}
```

**Landing Zone**:
```hcl
# Hub network
module "hub_network" {
  source = "../../modules/networking"
  # Central hub VNet
}

# Multiple spoke networks using the same module
module "spoke_network_prod_aks" {
  source = "../../modules/networking"
  # Spoke VNet for AKS production
}

module "spoke_network_prod_web" {
  source = "../../modules/networking"
  # Spoke VNet for web services
}

module "spoke_network_dev" {
  source = "../../modules/networking"
  # Spoke VNet for development
}
```

### Same Pattern, Different Purpose

The framework structure remains consistent:
- `modules/` - Reusable components
- `environments/` - Environment-specific configs
- `examples/` - Reference implementations

Whether deploying a single application or an entire landing zone, teams use the same patterns and tools.

## Configuration Details

### Hub Network

```hcl
# Hub VNet Configuration
Address Space: 10.0.0.0/16

# Subnets
GatewaySubnet:         10.0.1.0/24   (VPN/ExpressRoute Gateway)
AzureFirewallSubnet:   10.0.2.0/24   (Azure Firewall)
AzureBastionSubnet:    10.0.3.0/24   (Azure Bastion)
SharedServicesSubnet:  10.0.4.0/24   (Shared services)
```

### Spoke Networks

```hcl
# Production AKS Spoke
Address Space: 10.1.0.0/16
Subnets:
  - aks-subnet:     10.1.1.0/24
  - app-subnet:     10.1.2.0/24
  - data-subnet:    10.1.3.0/24

# Production Web Spoke
Address Space: 10.2.0.0/16
Subnets:
  - web-subnet:     10.2.1.0/24
  - api-subnet:     10.2.2.0/24
  - data-subnet:    10.2.3.0/24

# Development Spoke
Address Space: 10.10.0.0/16
Subnets:
  - dev-subnet:     10.10.1.0/24
  - test-subnet:    10.10.2.0/24
```

### Shared Services

```hcl
# Log Analytics Workspace
- Retention: 90 days
- Collects logs from all spokes
- Centralized security monitoring

# Azure Container Registry
- SKU: Premium
- Geo-replication enabled
- Used by all teams

# Key Vault
- SKU: Premium
- Shared secrets management
- Network-restricted access

# Cosmos DB (Shared)
- Multi-region deployment
- Shared data platform
- Team-specific databases
```

## Governance and Compliance

### Azure Policies Applied

1. **Allowed Locations**: Resources must be in approved regions
2. **Required Tags**: All resources must have owner, cost center, environment tags
3. **Network Security**: NSGs required on all subnets
4. **Encryption**: Storage and databases must use encryption
5. **Monitoring**: Diagnostic logs must be enabled

### RBAC Roles

```
Hub Subscription:
- Network Admin: Manages hub and firewall
- Security Admin: Manages policies and monitoring

Spoke Subscriptions:
- Application Team: Contributor on their spoke resources
- Developers: Reader on production, Contributor on dev/test
```

## Cost Breakdown

### Monthly Cost Estimate

| Component | Configuration | Monthly Cost |
|-----------|--------------|--------------|
| Hub VNet | Standard | ~$50 |
| Azure Firewall | Standard | ~$1,250 |
| Azure Bastion | Standard | ~$140 |
| VPN Gateway (optional) | VpnGw1 | ~$140 |
| Spoke VNets (3x) | Standard | ~$150 |
| VNet Peering | Hub↔Spokes | ~$100 |
| Log Analytics | 100GB/month | ~$250 |
| Container Registry | Premium | ~$600 |
| Key Vault | Premium | ~$25 |
| **Hub Total** | | **~$2,705/month** |
| **Per Spoke Workload** | Varies | **$500-5,000/month** |

*Costs shared across all teams and applications*

### Cost Optimization

1. **Shared Infrastructure**: Hub costs shared across all teams
2. **Auto-scaling**: Workloads scale based on demand
3. **Policy Enforcement**: Prevents overprovisioning
4. **Resource Tagging**: Enables chargeback to teams

## Adding a New Application

To deploy a new application to the landing zone:

### Option 1: Use AKS Spoke

```hcl
# Add to spoke_networks in terraform.tfvars
"new-app-aks" = {
  address_space = "10.4.0.0/16"
  environment   = "production"
  application   = "new-application"
}
```

Then deploy your application using the AKS example:

```bash
cd ../aks-application
# Configure to use the new spoke network
terraform apply
```

### Option 2: Create Custom Spoke

Use the framework modules to create a custom spoke:

```hcl
module "custom_spoke" {
  source = "../../modules/networking"
  
  network_name  = "custom-app-vnet"
  address_space = ["10.5.0.0/16"]
  # ... configure for your needs
}

# Peer to hub
resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  # ... peering configuration
}
```

## Scaling Strategies

### Horizontal Scaling (More Applications)
- Add new spoke networks
- Each application gets isolated network
- Centrally managed through hub

### Vertical Scaling (Bigger Applications)
- Use larger address spaces for spokes
- Deploy application-specific resources
- Maintain connection to hub for shared services

### Geographic Scaling (Multiple Regions)
- Deploy additional landing zones in other regions
- Use global resources (Cosmos DB, Traffic Manager)
- Maintain consistent structure across regions

## Security Features

### Network Security
- Azure Firewall inspects all traffic
- NSGs on every subnet
- Private endpoints for Azure services
- No public IPs except on Bastion

### Identity and Access
- Azure AD integration
- Managed identities for services
- Privileged Identity Management (PIM)
- Just-In-Time (JIT) access

### Data Protection
- Encryption at rest and in transit
- Private connectivity to data services
- Backup and disaster recovery
- Compliance monitoring

### Monitoring
- Centralized logging
- Security Center integration
- Sentinel for SIEM (optional)
- Automated alerting

## Troubleshooting

### Issue: Spoke Can't Communicate with Hub

```bash
# Check peering status
az network vnet peering show \
  --resource-group spoke-rg \
  --name spoke-to-hub \
  --vnet-name spoke-vnet

# Verify route tables
az network route-table route list \
  --resource-group hub-rg \
  --route-table-name hub-routes
```

### Issue: Firewall Blocking Traffic

```bash
# Check firewall logs
az monitor log-analytics query \
  --workspace <workspace-id> \
  --analytics-query "AzureDiagnostics | where Category == 'AzureFirewallApplicationRule' | limit 100"
```

### Issue: High Costs

```bash
# Review resource costs
az consumption usage list \
  --start-date 2024-01-01 \
  --end-date 2024-01-31

# Identify top resources
az cost-management query \
  --type Usage \
  --dataset-aggregation totalCost=sum \
  --dataset-grouping name=ResourceId
```

## Cleanup

```bash
# Warning: This will delete the entire landing zone
terraform destroy
```

For production, consider:
1. Backup all data
2. Export configurations
3. Notify all teams
4. Follow change management process

## Comparison: Single App vs Landing Zone

| Aspect | Single Application | Landing Zone |
|--------|-------------------|--------------|
| **Scope** | One application | Multiple applications/teams |
| **Network** | Single VNet | Hub-spoke topology |
| **Resources** | Application-specific | Shared + spoke-specific |
| **Cost** | $500-5,000/month | $3,000-20,000/month |
| **Complexity** | Low-Medium | Medium-High |
| **Governance** | Application-level | Enterprise-level |
| **Use Case** | Single project | Enterprise platform |

## Key Takeaways

1. **Same Framework**: Both examples use identical module structure
2. **Scalable Pattern**: Pattern scales from single app to enterprise
3. **Reusable Components**: Modules work at any scale
4. **Consistent Experience**: Teams understand the structure regardless of scope
5. **Easy Expansion**: Adding resources follows the same process

## Next Steps

1. **Review Architecture**: Understand hub-spoke model
2. **Plan Spokes**: Identify applications and teams
3. **Define Governance**: Establish policies and RBAC
4. **Deploy Hub**: Start with centralized services
5. **Add Spokes**: Gradually migrate applications
6. **Monitor and Optimize**: Continuously improve

## Additional Resources

- [Azure Landing Zone Documentation](https://docs.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/)
- [Hub-Spoke Topology](https://docs.microsoft.com/azure/architecture/reference-architectures/hybrid-networking/hub-spoke)
- [Azure Firewall Best Practices](https://docs.microsoft.com/azure/firewall/firewall-best-practices)
- [Technical Documentation](../../docs/technical/README.md)
- [Executive Summary](../../docs/executive/README.md)
