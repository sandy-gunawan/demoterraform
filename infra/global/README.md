# Global Standards README

## Purpose

This folder contains the **global standards** that all teams and environments must inherit. These files ensure:

- **Consistent Terraform versions** across all deployments
- **Standardized naming conventions** for all Azure resources
- **Unified tagging strategy** for cost tracking and governance
- **Common provider configurations** with secure authentication

## Files

### `versions.tf`
Locks Terraform and provider versions to prevent unexpected changes and ensure reproducibility.

**Why**: Different provider versions can have breaking changes. This ensures all teams use the same versions.

### `providers.tf`
Configures Azure providers with OIDC/Managed Identity support (no secrets).

**Why**: Modern authentication eliminates the need for storing secrets in pipelines.

### `locals.tf`
Defines naming conventions and tagging standards.

**Why**: Consistent naming makes resources easy to find and understand. Standard tags enable cost tracking and governance.

## Usage in Environments

Each environment (dev/staging/prod) should reference these global standards:

```hcl
# In your environment's main.tf
module "global_standards" {
  source = "../../global"
  
  organization_name = "contoso"
  project_name      = "contoso"
  environment       = "dev"
  cost_center       = "Engineering"
  owner_email       = "devops@contoso.com"
}

# Use the standard naming
resource "azurerm_resource_group" "main" {
  name     = module.global_standards.resource_names.resource_group
  location = var.location
  tags     = module.global_standards.common_tags
}
```

## Naming Convention

**Pattern**: `{organization}-{project}-{resource}-{environment}`

**Examples**:
- Resource Group: `contoso-ecommerce-rg-prod`
- AKS Cluster: `contoso-ecommerce-aks-prod`
- Virtual Network: `contoso-ecommerce-vnet-prod`
- Key Vault: `contoso-ecommerce-kv-prod`

**Special Cases**:
- Storage Accounts: No hyphens, lowercase only (e.g., `contosoecommercestprod`)
- Cosmos DB: Global uniqueness required (e.g., `contoso-ecommerce-cosmos-prod`)

## Standard Tags

All resources automatically get these tags:

| Tag | Purpose | Example |
|-----|---------|---------|
| ManagedBy | Identifies IaC tool | Terraform |
| Organization | Company/org name | Contoso |
| Project | Project name | E-Commerce |
| Environment | Environment type | Production |
| CostCenter | Billing allocation | Engineering |
| Owner | Responsible team/person | devops@contoso.com |
| Repository | Source code location | github.com/contoso/infra |
| DeploymentDate | When deployed | 2026-02-02T10:30:00Z |

## Modifying Standards

⚠️ **Warning**: Changes to global standards affect **all environments and teams**.

**Process**:
1. Create a PR with proposed changes
2. Get approval from platform team
3. Test in dev environment first
4. Communicate changes to all teams before merging
5. Teams may need to update their configurations

## Best Practices

1. **Never override naming standards** - Use the centralized patterns
2. **Add environment-specific tags** - Use `additional_tags` variable
3. **Keep versions pinned** - Only update after testing
4. **Document exceptions** - If a team needs special naming, document why
