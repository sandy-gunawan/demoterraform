# AKS Application Deployment Example

## Overview

This example demonstrates a complete production-ready deployment of a web application on Azure Kubernetes Service (AKS) with supporting services including Cosmos DB for data storage, Azure Key Vault for secrets, and comprehensive monitoring.

## What This Example Deploys

1. **Virtual Network** with multiple subnets for isolation
2. **AKS Cluster** with system and user node pools
3. **Azure Cosmos DB** for application data
4. **Azure Key Vault** for secrets management
5. **Log Analytics** for monitoring and diagnostics
6. **Network Security Groups** for traffic control

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────┐
│                    Azure Region (East US)                │
│                                                           │
│  ┌──────────────────────────────────────────────────┐  │
│  │           Virtual Network (10.10.0.0/16)         │  │
│  │                                                   │  │
│  │  ┌────────────────┐      ┌──────────────────┐  │  │
│  │  │  AKS Subnet    │      │  App Subnet      │  │  │
│  │  │  10.10.1.0/24  │      │  10.10.2.0/24    │  │  │
│  │  │                │      │                   │  │  │
│  │  │  ┌──────────┐ │      │  ┌────────────┐  │  │  │
│  │  │  │ AKS      │ │      │  │ Cosmos DB  │  │  │  │
│  │  │  │ Cluster  │◄┼──────┼─►│            │  │  │  │
│  │  │  │          │ │      │  └────────────┘  │  │  │
│  │  │  └──────────┘ │      │                   │  │  │
│  │  │       │        │      │  ┌────────────┐  │  │  │
│  │  │       │        │      │  │ Key Vault  │  │  │  │
│  │  │       └────────┼──────┼─►│            │  │  │  │
│  │  │                │      │  └────────────┘  │  │  │
│  │  └────────────────┘      └──────────────────┘  │  │
│  │                                                   │  │
│  └──────────────────────────────────────────────────┘  │
│                                                           │
│  ┌──────────────────────────────────────────────────┐  │
│  │        Log Analytics Workspace                    │  │
│  │  (Collecting logs from all resources)            │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

## File Structure

```
aks-application/
├── main.tf              # Main configuration
├── variables.tf         # Input variables
├── terraform.tfvars     # Variable values
├── outputs.tf           # Output values
├── README.md           # This file
└── kubernetes/         # Kubernetes manifests
    ├── deployment.yaml
    ├── service.yaml
    └── ingress.yaml
```

## Prerequisites

- Azure subscription
- Azure CLI installed
- kubectl installed
- Terraform >= 1.5.0
- Appropriate Azure permissions

## Deployment Steps

### 1. Configure Variables

Edit `terraform.tfvars` with your values:

```hcl
project_name = "contoso"
environment  = "production"
location     = "indonesiacentral"
tenant_id    = "your-tenant-id"
admin_group_object_ids = ["your-admin-group-id"]

# Application-specific
app_name = "ecommerce-web"
```

### 2. Initialize Terraform

```bash
cd examples/aks-application
terraform init
```

### 3. Review the Plan

```bash
terraform plan
```

This will show:
- 20+ resources to be created
- Estimated costs
- Network topology
- Security configurations

### 4. Deploy Infrastructure

```bash
terraform apply
```

Deployment takes approximately 15-20 minutes.

### 5. Get AKS Credentials

```bash
# Get the cluster name from outputs
CLUSTER_NAME=$(terraform output -raw aks_cluster_name)
RG_NAME=$(terraform output -raw resource_group_name)

# Configure kubectl
az aks get-credentials --resource-group $RG_NAME --name $CLUSTER_NAME
```

### 6. Verify Cluster

```bash
# Check nodes
kubectl get nodes

# Expected output:
# NAME                                STATUS   ROLES   AGE   VERSION
# aks-system-12345678-vmss000000     Ready    agent   5m    v1.28.3
# aks-system-12345678-vmss000001     Ready    agent   5m    v1.28.3
# aks-system-12345678-vmss000002     Ready    agent   5m    v1.28.3
# aks-user-12345678-vmss000000       Ready    agent   5m    v1.28.3
# aks-user-12345678-vmss000001       Ready    agent   5m    v1.28.3
```

### 7. Deploy Application

```bash
# Create namespace
kubectl create namespace myapp

# Deploy application
kubectl apply -f kubernetes/ -n myapp

# Check deployment
kubectl get pods -n myapp
kubectl get services -n myapp
```

## Configuration Details

### Network Configuration

```hcl
# Virtual Network
Address Space: 10.10.0.0/16

# Subnets
AKS Subnet:     10.10.1.0/24  (254 IPs)
App Subnet:     10.10.2.0/24  (254 IPs)
PE Subnet:      10.10.3.0/24  (254 IPs - for private endpoints)
```

### AKS Configuration

```hcl
# Cluster Details
Kubernetes Version: 1.28.3
Network Plugin: Azure CNI
Network Policy: Azure

# System Node Pool
Name: system
Count: 3 nodes
VM Size: Standard_D4s_v3 (4 vCPUs, 16GB RAM)
Auto-scaling: Yes (3-10 nodes)

# User Node Pool
Name: user
Count: 3 nodes
VM Size: Standard_D8s_v3 (8 vCPUs, 32GB RAM)
Auto-scaling: Yes (2-8 nodes)
```

### Cosmos DB Configuration

```hcl
# Account Details
API: SQL (Core)
Consistency: Session
Regions: East US (primary), West US (secondary)
Backup: Continuous (7 days retention)

# Database
Name: AppDatabase
Throughput: Autoscale (1000-10000 RU/s)

# Containers
1. users
   - Partition Key: /userId
   - Throughput: Autoscale (400-4000 RU/s)
   - Indexing: Optimized for queries

2. products
   - Partition Key: /category
   - Throughput: Autoscale (400-4000 RU/s)
   - Analytical Storage: Enabled

3. orders
   - Partition Key: /customerId, /year (Hierarchical)
   - Throughput: Autoscale (1000-10000 RU/s)
   - TTL: 2 years
```

## Application Connection Strings

After deployment, retrieve connection information:

```bash
# Cosmos DB endpoint
terraform output cosmosdb_endpoint

# Get Cosmos DB connection string (stored in Key Vault)
VAULT_NAME=$(terraform output -raw key_vault_name)
az keyvault secret show --vault-name $VAULT_NAME --name cosmosdb-connection-string
```

## Monitoring and Observability

### View Logs

```bash
# AKS cluster logs
az monitor log-analytics query \
  --workspace $(terraform output -raw log_analytics_workspace_id) \
  --analytics-query "ContainerLog | where TimeGenerated > ago(1h) | limit 100"

# Cosmos DB queries
az monitor log-analytics query \
  --workspace $(terraform output -raw log_analytics_workspace_id) \
  --analytics-query "AzureDiagnostics | where ResourceProvider == 'MICROSOFT.DOCUMENTDB' | limit 100"
```

### Azure Portal Dashboards

1. Navigate to Azure Portal
2. Go to Log Analytics Workspace
3. View pre-configured workbooks:
   - Container Insights
   - Cosmos DB Insights
   - Network Monitoring

## Cost Breakdown

### Monthly Cost Estimate (Production)

| Resource | Configuration | Monthly Cost |
|----------|--------------|--------------|
| AKS - System Nodes | 3x D4s_v3 | ~$450 |
| AKS - User Nodes | 3x D8s_v3 | ~$900 |
| Cosmos DB | 10K RU/s autoscale | ~$600 |
| Virtual Network | Standard | ~$50 |
| Log Analytics | 50GB/month | ~$150 |
| Key Vault | Standard | ~$5 |
| Load Balancer | Standard | ~$20 |
| **Total** | | **~$2,175/month** |

*Costs vary based on actual usage, region, and scaling behavior*

### Cost Optimization Tips

1. **Auto-scaling**: Nodes scale down during low traffic
2. **Reserved Instances**: Save 40-60% on VMs (commit 1-3 years)
3. **Spot Instances**: Use for non-critical workloads (up to 90% savings)
4. **Cosmos DB Autoscale**: Pay only for RUs actually used
5. **Log Retention**: Adjust to match compliance requirements

## Security Features

### Network Security
- Private endpoints for Cosmos DB
- Network Security Groups (NSGs) on all subnets
- Azure Firewall integration (optional)
- Service endpoints for Azure services

### Identity and Access
- Azure AD integration for AKS
- Managed identities for service authentication
- RBAC enabled at cluster level
- Key Vault integration for secrets

### Data Protection
- Encryption at rest (all services)
- Encryption in transit (TLS 1.2+)
- Cosmos DB continuous backup
- Geo-redundant backups

### Compliance
- Azure Policy enforcement
- Diagnostic logging enabled
- Audit trails for all operations
- Compliance dashboard available

## Scaling the Application

### Scale Nodes Manually

```bash
# Scale system node pool
az aks nodepool scale \
  --resource-group $RG_NAME \
  --cluster-name $CLUSTER_NAME \
  --name system \
  --node-count 5

# Scale user node pool
az aks nodepool scale \
  --resource-group $RG_NAME \
  --cluster-name $CLUSTER_NAME \
  --name user \
  --node-count 5
```

### Scale Application Pods

```bash
# Scale deployment
kubectl scale deployment myapp --replicas=10 -n myapp

# Enable Horizontal Pod Autoscaler
kubectl autoscale deployment myapp \
  --min=3 --max=20 --cpu-percent=70 -n myapp
```

### Scale Cosmos DB

```bash
# Update throughput (in Terraform)
# Edit main.tf and change autoscale_max_throughput
# Then apply:
terraform apply
```

## Disaster Recovery

### Backup Strategy

1. **Cosmos DB**: Continuous backup (automatic)
2. **AKS Configuration**: Stored in Terraform state
3. **Application Data**: Stored in Cosmos DB (geo-replicated)

### Failover Procedure

1. **Automatic Failover**: Cosmos DB automatically fails over to West US if East US is unavailable
2. **Manual Failover**: Can be triggered for planned maintenance

```bash
# Trigger manual failover to West US
az cosmosdb failover-priority-change \
  --resource-group $RG_NAME \
  --name $(terraform output -raw cosmosdb_account_name) \
  --failover-policies "West US=0" "East US=1"
```

## Troubleshooting

### Issue: Pods Not Starting

```bash
# Check pod status
kubectl describe pod <pod-name> -n myapp

# Common causes:
# 1. Image pull errors - check registry credentials
# 2. Resource limits - check node capacity
# 3. Network issues - check NSG rules
```

### Issue: Can't Connect to Cosmos DB

```bash
# Check network connectivity
az network vnet subnet show \
  --resource-group $RG_NAME \
  --vnet-name $(terraform output -raw vnet_name) \
  --name app-subnet

# Verify service endpoint is enabled for Microsoft.AzureCosmosDB
```

### Issue: High Costs

```bash
# Check actual node count
kubectl get nodes

# Check Cosmos DB RU consumption
az cosmosdb sql database throughput show \
  --resource-group $RG_NAME \
  --account-name $(terraform output -raw cosmosdb_account_name) \
  --name AppDatabase
```

## Cleanup

To destroy all resources:

```bash
# Warning: This will delete all resources and data
terraform destroy
```

For production environments, consider:
1. Backup Cosmos DB data
2. Export logs from Log Analytics
3. Document any manual configurations
4. Review deletion policies

## Next Steps

1. **Customize for Your Application**
   - Update Kubernetes manifests
   - Configure ingress rules
   - Add SSL certificates

2. **Implement CI/CD**
   - Set up Azure DevOps or GitHub Actions
   - Automate deployments
   - Implement blue-green deployments

3. **Enhance Monitoring**
   - Configure custom alerts
   - Create application dashboards
   - Set up on-call rotations

4. **Optimize Performance**
   - Load test the application
   - Tune Cosmos DB indexing
   - Optimize container images

## Additional Resources

- [Technical Documentation](../../docs/technical/README.md)
- [Executive Summary](../../docs/executive/README.md)
- [Module Documentation](../../infra/modules/)
- [Azure AKS Documentation](https://docs.microsoft.com/azure/aks/)
- [Azure Cosmos DB Best Practices](https://docs.microsoft.com/azure/cosmos-db/)
