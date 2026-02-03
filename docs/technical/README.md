# Technical Documentation

## Table of Contents
1. [Getting Started](#getting-started)
2. [Architecture Overview](#architecture-overview)
3. [Module Documentation](#module-documentation)
4. [Environment Configuration](#environment-configuration)
5. [Deployment Guide](#deployment-guide)
6. [Troubleshooting](#troubleshooting)
7. [Best Practices](#best-practices)

## Getting Started

### Prerequisites
- Terraform >= 1.5.0
- Azure CLI installed and configured
- Azure subscription with appropriate permissions
- Azure AD group for administrators

### Initial Setup

1. **Clone the framework**
```bash
git clone <repository-url>
cd terraform-framework
```

2. **Authenticate with Azure**
```bash
az login
az account set --subscription <subscription-id>
```

3. **Configure backend storage** (Optional but recommended)
```bash
# Create storage account for Terraform state
az group create --name terraform-state-rg --location eastus
az storage account create --name tfstateXXXXX --resource-group terraform-state-rg --location eastus --sku Standard_LRS
az storage container create --name tfstate --account-name tfstateXXXXX
```

4. **Update backend configuration**
Edit `shared/backend.tf` and uncomment the backend block with your storage account details.

## Architecture Overview

### Directory Structure Explained

```
terraform-framework/
├── modules/                    # Reusable infrastructure components
│   ├── aks/                   # Kubernetes cluster module
│   ├── cosmosdb/              # Database module
│   ├── networking/            # Virtual networks and subnets
│   ├── container-app/         # Container Apps module
│   └── security/              # Security resources
├── environments/              # Environment-specific configurations
│   ├── development/           # Dev environment (simple security)
│   ├── staging/               # Staging environment (medium security)
│   └── production/            # Production environment (high security)
├── shared/                    # Shared configurations
│   ├── backend.tf             # Terraform backend setup
│   └── variables.tf           # Common variables
└── examples/                  # Working examples
    ├── aks-application/       # Full AKS deployment
    └── landing-zone/          # Landing zone setup
```

### Module Design Philosophy

**WHY**: Modules ensure consistency and reusability across all teams and environments.

**HOW**: Each module:
1. Encapsulates a specific Azure service or logical grouping
2. Accepts parameters for customization
3. Outputs important values for use by other modules
4. Includes comprehensive documentation

### Security Tiers by Environment

| Feature | Development | Staging | Production |
|---------|-------------|---------|------------|
| Network Access | Public | VNet filtered | Private endpoints only |
| Node Count | 1-2 | 2-5 | 3-10 |
| Backup | Basic (240 min) | Enhanced (60 min) | Continuous |
| Multi-region | No | Yes (2 regions) | Yes (3 regions) |
| Azure Policy | Disabled | Audit mode | Enforce |
| Log Retention | 30 days | 60 days | 90 days |
| Cost Profile | Low | Medium | High |

## Module Documentation

### AKS Module

**Purpose**: Deploys a production-ready Azure Kubernetes Service cluster.

**Why This Matters**:
- Consistent cluster configuration across environments
- Built-in security with Azure AD integration
- Auto-scaling for cost optimization
- Integrated monitoring and logging

**Key Features**:
- System and user node pools for workload separation
- Azure CNI networking for pod-level networking
- Azure Policy integration for compliance
- Key Vault integration for secrets
- Log Analytics for observability

**Usage**:
```hcl
module "aks" {
  source = "../../../infra/modules/aks"

  cluster_name               = "myapp-aks-prod"
  location                   = "eastus"
  subnet_id                  = module.networking.subnet_ids["aks-subnet"]
  log_analytics_workspace_id = azurerm_log_analytics_workspace.prod.id
  
  # Configuration based on environment
  system_node_count   = 3
  system_node_vm_size = "Standard_D4s_v3"
  enable_auto_scaling = true
}
```

**Tracing and Debugging**:
```bash
# Get AKS credentials
az aks get-credentials --resource-group <rg-name> --name <cluster-name>

# View cluster nodes
kubectl get nodes

# Check pod logs
kubectl logs <pod-name> -n <namespace>

# View Log Analytics
az monitor log-analytics query --workspace <workspace-id> --analytics-query "ContainerLog | limit 100"
```

### Cosmos DB Module

**Purpose**: Deploys Azure Cosmos DB with optimized partitioning and global distribution.

**Why This Matters**:
- Low-latency data access globally
- Automatic scaling based on demand
- Built-in replication and failover
- Optimized for various data patterns (chat, user profiles, IoT)

**Key Features**:
- Support for hierarchical partition keys (HPK) to overcome 20GB limits
- Flexible consistency levels
- Autoscale throughput for cost optimization
- Integrated diagnostics for query analysis
- VNet integration and private endpoints

**Data Modeling Best Practices**:

1. **Embedding Pattern** (Use when data is always accessed together)
```json
{
  "id": "user-123",
  "userId": "user-123",
  "name": "John Doe",
  "address": {
    "street": "123 Main St",
    "city": "Seattle"
  },
  "preferences": {
    "theme": "dark",
    "notifications": true
  }
}
```

2. **Reference Pattern** (Use when data grows unbounded)
```json
// User document
{
  "id": "user-123",
  "userId": "user-123",
  "name": "John Doe"
}

// Separate orders documents
{
  "id": "order-456",
  "userId": "user-123",
  "items": [...]
}
```

3. **Hierarchical Partition Keys** (For scaling beyond 20GB)
```hcl
partition_key_paths = ["/tenantId", "/userId", "/year"]
```

**Usage**:
```hcl
module "cosmosdb" {
  source = "../../../infra/modules/cosmosdb"

  account_name      = "myapp-cosmos-prod"
  location          = "eastus"
  consistency_level = "Session"
  
  sql_containers = {
    "users" = {
      database_name       = "AppDatabase"
      partition_key_paths = ["/userId"]
      autoscale_max_throughput = 4000
    }
  }
}
```

**Tracing and Debugging**:
```bash
# View Cosmos DB metrics
az cosmosdb show --name <account-name> --resource-group <rg-name>

# Query diagnostic logs
az monitor log-analytics query \
  --workspace <workspace-id> \
  --analytics-query "AzureDiagnostics | where ResourceProvider == 'MICROSOFT.DOCUMENTDB' | limit 100"

# Use VS Code extension for data inspection
# Install: ms-azuretools.vscode-cosmosdb
```

**Performance Optimization**:
- Monitor RU consumption in Azure Portal
- Use diagnostic strings to identify slow queries
- Optimize partition key selection based on query patterns
- Use indexing policies to exclude unnecessary fields

### Networking Module

**Purpose**: Creates secure, scalable network infrastructure.

**Why This Matters**:
- Isolates workloads in separate subnets
- Controls traffic with Network Security Groups
- Enables private connectivity to Azure services
- Supports hub-spoke topology

**Key Features**:
- Virtual Network with customizable address spaces
- Multiple subnets with service endpoints
- Network Security Groups with custom rules
- NAT Gateway for secure outbound connectivity
- Support for private endpoints

**Usage**:
```hcl
module "networking" {
  source = "../../../infra/modules/networking"

  network_name  = "prod-vnet"
  location      = "eastus"
  address_space = ["10.0.0.0/16"]
  
  subnets = {
    "aks-subnet" = {
      address_prefixes  = ["10.0.1.0/24"]
      service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
    }
  }
}
```

## Environment Configuration

### Development Environment

**Purpose**: Rapid development and testing with minimal cost.

**Characteristics**:
- Single region deployment
- Public network access
- Minimal node counts
- Basic backup and monitoring
- No Azure Policy enforcement

**Use Cases**:
- Feature development
- Integration testing
- Developer sandboxes

**Cost**: ~$200-500/month (depending on usage)

### Staging Environment

**Purpose**: Pre-production testing with production-like configuration.

**Characteristics**:
- Multi-region with automatic failover
- VNet-integrated services
- Moderate node counts with auto-scaling
- Enhanced backup (hourly)
- Azure Policy in audit mode

**Use Cases**:
- UAT (User Acceptance Testing)
- Performance testing
- Security scanning
- Integration with production-like data

**Cost**: ~$800-1500/month

### Production Environment

**Purpose**: Mission-critical workloads with maximum security and reliability.

**Characteristics**:
- Multi-region with multi-region writes
- Private endpoints only
- High node counts with auto-scaling
- Continuous backup
- Full Azure Policy enforcement
- 90-day log retention

**Use Cases**:
- Production workloads
- Customer-facing applications
- Compliance-required workloads

**Cost**: ~$3000-8000/month (varies with scale)

## Deployment Guide

### Step-by-Step Deployment

1. **Choose Your Environment**
```bash
cd environments/development  # or staging/production
```

2. **Configure Variables**
Edit `terraform.tfvars`:
```hcl
project_name = "myapp"
location     = "eastus"
tenant_id    = "your-tenant-id"
admin_group_object_ids = ["your-admin-group-id"]
```

3. **Initialize Terraform**
```bash
terraform init
```

4. **Review Plan**
```bash
terraform plan -out=tfplan
```

5. **Apply Configuration**
```bash
terraform apply tfplan
```

6. **Verify Deployment**
```bash
terraform output
```

### Common Deployment Patterns

**Pattern 1: New Application Deployment**
1. Deploy networking infrastructure
2. Deploy AKS cluster
3. Deploy supporting services (Cosmos DB, Key Vault)
4. Configure application
5. Deploy application to AKS

**Pattern 2: Infrastructure Update**
1. Update module or environment configuration
2. Run `terraform plan` to review changes
3. Apply changes incrementally
4. Monitor for issues

## Troubleshooting

### Common Issues and Solutions

#### Issue: Terraform State Lock
**Symptom**: "Error acquiring state lock"
**Solution**:
```bash
# Remove lock (use with caution)
az storage blob lease break --container-name tfstate --blob-name terraform.tfstate --account-name <storage-account>
```

#### Issue: AKS Authentication Failed
**Symptom**: Unable to authenticate to AKS cluster
**Solution**:
```bash
# Re-authenticate
az aks get-credentials --resource-group <rg-name> --name <cluster-name> --overwrite-existing

# Verify
kubectl get nodes
```

#### Issue: Cosmos DB High RU Consumption
**Symptom**: High costs or throttling (429 errors)
**Solution**:
1. Review query patterns in diagnostic logs
2. Optimize indexing policy
3. Consider hierarchical partition keys
4. Enable autoscale throughput

#### Issue: Network Connectivity Problems
**Symptom**: Services can't communicate
**Solution**:
1. Check NSG rules: `az network nsg rule list`
2. Verify service endpoints on subnets
3. Check private endpoint configuration
4. Review route tables

### Debugging Commands

```bash
# Check Terraform state
terraform state list
terraform state show <resource>

# View Azure resources
az resource list --resource-group <rg-name> --output table

# Check AKS cluster health
az aks show --resource-group <rg-name> --name <cluster-name> --query "powerState"

# View Cosmos DB operations
az cosmosdb show --name <account-name> --resource-group <rg-name>

# Check network connectivity
az network watcher test-connectivity --source-resource <source> --dest-resource <dest>
```

## Best Practices

### 1. State Management
- Always use remote state storage (Azure Storage)
- Enable state locking
- Use separate state files per environment
- Regular state backups

### 2. Security
- Never commit secrets to version control
- Use Azure Key Vault for sensitive data
- Implement least privilege access
- Enable audit logging
- Use private endpoints in production

### 3. Cost Optimization
- Use autoscaling where appropriate
- Rightsize VMs based on actual usage
- Use Reserved Instances for production
- Monitor and alert on cost anomalies
- Shut down dev/test resources when not in use

### 4. High Availability
- Deploy across multiple availability zones
- Use multi-region for critical workloads
- Implement health checks
- Test failover procedures regularly

### 5. Monitoring and Alerting
- Enable diagnostic settings for all resources
- Create dashboards for key metrics
- Set up alerts for critical thresholds
- Review logs regularly

### 6. Change Management
- Always run `terraform plan` before apply
- Use workspaces or separate state files per environment
- Implement CI/CD for infrastructure changes
- Maintain changelog for infrastructure updates

### 7. Module Development
- Keep modules focused and single-purpose
- Document all variables and outputs
- Version your modules
- Test modules independently

## Next Steps

- Review the [Executive Documentation](../executive/README.md)
- Explore [AKS Application Example](../../examples/aks-application/README.md)
- Check out [Landing Zone Example](../../examples/landing-zone/README.md)
- Set up [CI/CD Pipeline](ci-cd-guide.md)
