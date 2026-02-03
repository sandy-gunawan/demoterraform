# AKS Module

## Purpose
This module creates a production-ready Azure Kubernetes Service (AKS) cluster with security best practices, monitoring, and scalability built in.

## Why This Module?
- **Consistency**: Ensures all AKS clusters follow the same configuration pattern
- **Security**: Implements Azure AD integration, Azure Policy, and network policies by default
- **Scalability**: Auto-scaling enabled for dynamic workload management
- **Monitoring**: Integrated with Log Analytics for comprehensive observability
- **Maintainability**: Simplified cluster management across multiple environments

## How It Works
1. Creates a resource group for AKS resources
2. Deploys an AKS cluster with system and optional user node pools
3. Configures Azure CNI networking for pod-level networking
4. Enables Azure AD RBAC for secure access control
5. Integrates monitoring with Log Analytics
6. Enables Key Vault integration for secrets management

## Resources Created
- Resource Group
- AKS Cluster with System Node Pool
- Optional User Node Pool for application workloads
- System Assigned Managed Identity
- Network policies and Azure Policy integration

## Usage Example

```hcl
module "aks" {
  source = "../../modules/aks"

  cluster_name               = "myapp-aks-prod"
  location                   = "eastus"
  dns_prefix                 = "myapp-prod"
  kubernetes_version         = "1.28.3"
  subnet_id                  = module.networking.subnet_id
  log_analytics_workspace_id = module.monitoring.workspace_id
  tenant_id                  = var.tenant_id
  admin_group_object_ids     = ["xxxxx-xxxx-xxxx-xxxx-xxxxxxxxx"]
  
  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
```

## Security Configurations by Environment

### Development
- Minimal node count (1-3)
- Azure Policy warnings only
- Basic monitoring

### Staging
- Moderate node count (2-5)
- Azure Policy in audit mode
- Enhanced monitoring

### Production
- Higher node count (3-10)
- Azure Policy enforcement
- Full monitoring and alerting
- Private cluster option
