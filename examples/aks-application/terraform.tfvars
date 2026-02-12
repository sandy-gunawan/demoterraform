# Example Values for AKS Application Deployment
# Copy this file and customize for your needs

project_name = "contoso"
app_name     = "ecommerce"
environment  = "production"
location     = "southeastasia"

# Azure AD Configuration (REQUIRED)
# Get tenant ID: az account show --query tenantId -o tsv
# Create AD group: az ad group create --display-name "AKS Admins" --mail-nickname "aks-admins"
# Get group ID: az ad group show --group "AKS Admins" --query objectId -o tsv
tenant_id = "12345678-1234-1234-1234-123456789012" # Replace with your tenant ID
admin_group_object_ids = [
  "87654321-4321-4321-4321-210987654321" # Replace with your AD group ID
]

# Logging
log_retention_days = 90

# AKS Configuration
kubernetes_version = "1.28.3"

# System Node Pool (for Kubernetes system components)
aks_system_node_count = 3
aks_system_node_size  = "Standard_D4s_v3" # 4 vCPUs, 16GB RAM
aks_system_min_nodes  = 3
aks_system_max_nodes  = 10

# User Node Pool (for application workloads)
aks_user_node_count = 3
aks_user_node_size  = "Standard_D8s_v3" # 8 vCPUs, 32GB RAM
aks_user_min_nodes  = 2
aks_user_max_nodes  = 8

enable_azure_policy = true

# Cosmos DB Configuration
cosmos_consistency_level       = "Session" # Session, Eventual, Strong, BoundedStaleness
cosmos_public_access           = false     # Use private endpoints for security
cosmos_backup_type             = "Continuous"
cosmos_multi_region_writes     = true
cosmos_database_max_throughput = 10000

# Multi-region setup for high availability
cosmos_failover_locations = [
  {
    location          = "westus"
    failover_priority = 1
  },
  {
    location          = "westeurope"
    failover_priority = 2
  }
]

# Key Vault
key_vault_public_access = false # Use private endpoints for security

# Tags
tags = {
  Project     = "E-Commerce Platform"
  Team        = "Platform Engineering"
  CostCenter  = "Engineering"
  Criticality = "High"
  Compliance  = "PCI-DSS"
  Owner       = "platform-team@contoso.com"
}
