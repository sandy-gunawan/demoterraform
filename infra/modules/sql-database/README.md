# SQL Database Module - Azure SQL Server & Databases

Manage Azure SQL Server instances and databases with enterprise-grade security, networking, and monitoring. This module provides a fully-featured SQL Server deployment with Azure AD authentication, firewall rules, private endpoints, and diagnostic logging.

## Features

- ✅ **SQL Server** - Managed SQL Server with configurable TLS and version
- ✅ **Azure AD Authentication** - Azure AD administrator with tenant integration
- ✅ **System-Assigned Identity** - Managed identity for secure service-to-service access
- ✅ **Multiple Databases** - Create any number of databases via `for_each`
- ✅ **Flexible SKUs** - Choose from Basic, Standard, Premium, or vCore SKUs per database
- ✅ **Zone Redundancy** - High availability with zone-redundant deployments
- ✅ **Read Replicas** - Read scale-out and read replicas for read-heavy workloads
- ✅ **Firewall Rules** - IP-based access control with Azure services bypass
- ✅ **VNet Integration** - Virtual network rules for subnet-level access
- ✅ **Private Endpoint** - Full network isolation via private link
- ✅ **Diagnostic Logging** - Security audit events and metrics to Log Analytics
- ✅ **Tagging** - Consistent tagging across all resources

## Usage

### Basic Example

```hcl
module "sql_database" {
  source = "../../modules/sql-database"

  resource_group_name          = "myapp-data-rg-dev"
  location                     = "eastus"
  server_name                  = "myapp-sql-dev-001"
  administrator_login          = var.sql_admin_login
  administrator_login_password = var.sql_admin_password

  # Azure AD admin
  tenant_id               = var.tenant_id
  azuread_admin_login     = "sqladmin@company.com"
  azuread_admin_object_id = "12345678-1234-1234-1234-123456789012"

  tags = module.global_standards.common_tags
}
```

### With Databases

```hcl
module "sql_database" {
  source = "../../modules/sql-database"

  resource_group_name          = "myapp-data-rg-dev"
  location                     = "eastus"
  server_name                  = "myapp-sql-dev-001"
  administrator_login          = var.sql_admin_login
  administrator_login_password = var.sql_admin_password

  tenant_id               = var.tenant_id
  azuread_admin_login     = "sqladmin@company.com"
  azuread_admin_object_id = var.azuread_admin_object_id

  # Create multiple databases
  databases = {
    "app-db" = {
      sku_name    = "S0"
      max_size_gb = 4
    }
    "analytics-db" = {
      sku_name    = "S1"
      max_size_gb = 50
    }
    "reporting-db" = {
      sku_name       = "S2"
      max_size_gb    = 100
      zone_redundant = false
      read_scale     = false
    }
  }

  # Allow dev team IP
  firewall_rules = {
    "dev-office" = {
      start_ip_address = "203.0.113.0"
      end_ip_address   = "203.0.113.255"
    }
  }

  tags = module.global_standards.common_tags
}
```

### With Private Endpoint + VNet Integration

```hcl
module "sql_database" {
  source = "../../modules/sql-database"

  resource_group_name          = "myapp-data-rg-prod"
  location                     = "eastus"
  server_name                  = "myapp-sql-prod-001"
  administrator_login          = var.sql_admin_login
  administrator_login_password = var.sql_admin_password

  tenant_id               = var.tenant_id
  azuread_admin_login     = "sqladmin@company.com"
  azuread_admin_object_id = var.azuread_admin_object_id

  # Disable public access (private only)
  public_network_access_enabled = false

  # Private endpoint
  enable_private_endpoint    = true
  private_endpoint_subnet_id = module.networking.subnet_ids["data-subnet"]

  # VNet rules (for resources that don't use private endpoint)
  virtual_network_rules = {
    "aks-subnet"  = module.networking.subnet_ids["aks-subnet"]
    "app-subnet"  = module.networking.subnet_ids["app-subnet"]
  }

  # Production databases
  databases = {
    "app-db" = {
      sku_name       = "P1"
      max_size_gb    = 256
      zone_redundant = true
      read_scale     = true
    }
  }

  # Don't allow Azure services in prod
  allow_azure_services = false

  tags = module.global_standards.common_tags
}
```

### With Log Analytics

```hcl
module "sql_database" {
  source = "../../modules/sql-database"

  resource_group_name          = "myapp-data-rg-prod"
  location                     = "eastus"
  server_name                  = "myapp-sql-prod-001"
  administrator_login          = var.sql_admin_login
  administrator_login_password = var.sql_admin_password

  tenant_id               = var.tenant_id
  azuread_admin_login     = "sqladmin@company.com"
  azuread_admin_object_id = var.azuread_admin_object_id

  # Send audit logs to Log Analytics
  log_analytics_workspace_id = azurerm_log_analytics_workspace.prod.id

  # Minimum TLS 1.2 (default, but explicit for clarity)
  minimum_tls_version = "1.2"

  databases = {
    "app-db" = {
      sku_name    = "S1"
      max_size_gb = 50
    }
  }

  tags = module.global_standards.common_tags
}
```

### Production Configuration

```hcl
module "sql_database" {
  source = "../../modules/sql-database"

  resource_group_name          = "myapp-data-rg-prod"
  location                     = "eastus"
  server_name                  = "myapp-sql-prod-001"
  administrator_login          = var.sql_admin_login
  administrator_login_password = var.sql_admin_password

  tenant_id               = var.tenant_id
  azuread_admin_login     = "sqladmin@company.com"
  azuread_admin_object_id = var.azuread_admin_object_id

  # Security hardening
  minimum_tls_version           = "1.2"
  public_network_access_enabled = false

  # Network isolation
  enable_private_endpoint    = true
  private_endpoint_subnet_id = module.networking.subnet_ids["data-subnet"]
  allow_azure_services       = false

  # VNet rules
  virtual_network_rules = {
    "aks-subnet" = module.networking.subnet_ids["aks-subnet"]
    "app-subnet" = module.networking.subnet_ids["app-subnet"]
  }

  # Databases with HA
  databases = {
    "app-db" = {
      sku_name           = "P2"
      max_size_gb        = 256
      zone_redundant     = true
      read_scale         = true
      read_replica_count = 1
      license_type       = "BasePrice"  # Azure Hybrid Benefit
    }
    "audit-db" = {
      sku_name    = "S1"
      max_size_gb = 100
    }
  }

  # Audit logging
  log_analytics_workspace_id = azurerm_log_analytics_workspace.prod.id

  tags = module.global_standards.common_tags
}
```

## Inputs

| Name | Description | Type | Required | Default |
|------|-------------|------|----------|---------|
| `resource_group_name` | Name of the resource group | string | Yes | - |
| `server_name` | SQL Server name (must be globally unique) | string | Yes | - |
| `location` | Azure region | string | Yes | - |
| `sql_version` | SQL Server version | string | No | "12.0" |
| `administrator_login` | SQL admin login (sensitive) | string | Yes | - |
| `administrator_login_password` | SQL admin password (sensitive) | string | Yes | - |
| `minimum_tls_version` | Minimum TLS version | string | No | "1.2" |
| `public_network_access_enabled` | Enable public network access | bool | No | true |
| `tenant_id` | Azure AD tenant ID | string | Yes | - |
| `azuread_admin_login` | Azure AD admin login name | string | Yes | - |
| `azuread_admin_object_id` | Azure AD admin object ID | string | Yes | - |
| `databases` | Map of databases to create | map(object) | No | {} |
| `firewall_rules` | Map of firewall rules | map(object) | No | {} |
| `allow_azure_services` | Allow Azure services to access the server | bool | No | true |
| `virtual_network_rules` | Map of VNet rule names to subnet IDs | map(string) | No | {} |
| `log_analytics_workspace_id` | Log Analytics workspace ID for diagnostics | string | No | null |
| `enable_private_endpoint` | Create private endpoint | bool | No | false |
| `private_endpoint_subnet_id` | Subnet ID for private endpoint | string | No | null |
| `tags` | Tags to apply to resources | map(string) | No | {} |

### Database Object Schema

| Property | Description | Type | Default |
|----------|-------------|------|---------|
| `collation` | Database collation | string | "SQL_Latin1_General_CP1_CI_AS" |
| `license_type` | License type (LicenseIncluded or BasePrice) | string | "LicenseIncluded" |
| `max_size_gb` | Maximum database size in GB | number | 4 |
| `sku_name` | SKU name (Basic, S0-S12, P1-P15, GP_Gen5_2, etc.) | string | "S0" |
| `zone_redundant` | Enable zone redundancy | bool | false |
| `read_scale` | Enable read scale-out | bool | false |
| `read_replica_count` | Number of read replicas | number | 0 |

## Outputs

| Name | Description |
|------|-------------|
| `server_id` | SQL Server resource ID |
| `server_name` | SQL Server name |
| `server_fqdn` | SQL Server fully qualified domain name |
| `database_ids` | Map of database names to resource IDs |
| `resource_group_name` | Resource group name |
| `principal_id` | System-assigned identity principal ID |

## Environment Recommendations

| Setting | Dev | Staging | Prod |
|---------|-----|---------|------|
| `sku_name` | Basic / S0 | S1 / S2 | P1+ / GP_Gen5 |
| `max_size_gb` | 2-4 | 10-50 | 100-1000 |
| `zone_redundant` | false | false | true |
| `read_scale` | false | false | true |
| `read_replica_count` | 0 | 0 | 1+ |
| `public_network_access_enabled` | true | true | false |
| `enable_private_endpoint` | false | false | true |
| `allow_azure_services` | true | true | false |
| `log_analytics_workspace_id` | optional | set | set |
| `minimum_tls_version` | "1.2" | "1.2" | "1.2" |
| `firewall_rules` | Dev IPs | CI/CD IPs | None (private only) |
| Estimated cost/month | $5-15 | $30-75 | $200-1500+ |

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           AZURE RESOURCE GROUP                              │
│                                                                             │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │                     AZURE SQL SERVER                                   │ │
│  │                                                                        │ │
│  │  Name: myapp-sql-prod-001                                             │ │
│  │  FQDN: myapp-sql-prod-001.database.windows.net                       │ │
│  │  Identity: SystemAssigned                                             │ │
│  │  Azure AD Admin: sqladmin@company.com                                 │ │
│  │  TLS: 1.2                                                             │ │
│  │                                                                        │ │
│  │  ┌─────────────┐  ┌──────────────┐  ┌──────────────┐                │ │
│  │  │   app-db    │  │ analytics-db │  │ reporting-db │                │ │
│  │  │ SKU: P1     │  │ SKU: S1      │  │ SKU: S2      │                │ │
│  │  │ 256 GB      │  │ 50 GB        │  │ 100 GB       │                │ │
│  │  │ Zone HA ✅  │  │ Zone HA ❌   │  │ Zone HA ❌   │                │ │
│  │  │ Read ✅     │  │ Read ❌      │  │ Read ❌      │                │ │
│  │  └─────────────┘  └──────────────┘  └──────────────┘                │ │
│  │                                                                        │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
│                                                                             │
│  NETWORK LAYER                                                              │
│  ┌─────────────────────┐  ┌─────────────────┐  ┌──────────────────────┐   │
│  │   Firewall Rules    │  │   VNet Rules    │  │  Private Endpoint    │   │
│  │                     │  │                 │  │                      │   │
│  │ AllowAzureServices  │  │ aks-subnet      │  │ myapp-sql-endpoint   │   │
│  │ dev-office          │  │ app-subnet      │  │ → data-subnet        │   │
│  └─────────────────────┘  └─────────────────┘  └──────────────────────┘   │
│                                                                             │
│  MONITORING                                                                 │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │   Diagnostic Settings → Log Analytics Workspace                      │  │
│  │   • SQLSecurityAuditEvents                                           │  │
│  │   • AllMetrics                                                       │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Querying Audit Logs

When `log_analytics_workspace_id` is set, query SQL audit events:

```kusto
AzureDiagnostics
| where ResourceProvider == "MICROSOFT.SQL"
| where Category == "SQLSecurityAuditEvents"
| project TimeGenerated, event_time_t, action_name_s, server_principal_name_s,
          database_name_s, statement_s, client_ip_s
| order by TimeGenerated desc
| take 100
```

## Troubleshooting

**Error: SQL Server name already exists**
- SQL Server names are globally unique across all of Azure
- Use a unique suffix: `myapp-sql-prod-001`
- Check: `nslookup myapp-sql-prod-001.database.windows.net`

**Error: Login failed for user**
- Verify `administrator_login` and `administrator_login_password` are correct
- Check if Azure AD authentication is configured (`azuread_admin_login`)
- Ensure the connecting user/app has been granted access at the database level

**Error: Cannot open server requested by the login (client IP)**
- Your IP is not in the firewall rules
- Add your IP: `firewall_rules = { "my-ip" = { start_ip_address = "x.x.x.x", end_ip_address = "x.x.x.x" } }`
- Or enable `allow_azure_services = true` for Azure-hosted apps

**Error: Private endpoint connection failed**
- Ensure `private_endpoint_subnet_id` is valid and in the same region
- Check that the subnet has no conflicting NSG rules blocking port 1433
- Verify DNS resolution points to the private IP (requires Private DNS Zone)

**Error: The requested service objective is not supported**
- Not all SKUs are available in all regions
- Zone redundancy requires Premium or Business Critical tiers
- Read scale requires Premium (P1+) or Business Critical SKUs
- Check: `az sql db list-editions -l eastus -o table`

**Error: Database size exceeds maximum**
- Upgrade the SKU to support a larger `max_size_gb`
- Basic: 2 GB max, S0: 250 GB max, P1: 1 TB max

## Cost

Azure SQL Database pricing varies by SKU tier:

| Tier | SKU Examples | Cost/Month (estimate) | Best For |
|------|-------------|----------------------|----------|
| Basic | Basic | ~$5 | Dev/test, tiny workloads |
| Standard | S0-S12 | $15-$1,200 | General workloads |
| Premium | P1-P15 | $465-$16,000 | High-performance, HA |
| General Purpose | GP_Gen5_2+ | $200+ | vCore-based flexible |
| Business Critical | BC_Gen5_2+ | $600+ | Mission-critical |

Additional costs:
- **Long-term retention:** ~$0.05/GB/month
- **Geo-replication:** Same as primary database cost
- **Private endpoint:** ~$8/month

**Save money:**
- Use `license_type = "BasePrice"` with Azure Hybrid Benefit (save ~55%)
- Right-size SKUs per environment
- Use Basic/S0 for dev, Premium for prod only

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| azurerm | ~> 3.80.0 |

## Related Modules

- [networking](../networking/) - Provides VNet and subnets for VNet rules and private endpoints
- [security](../security/) - Store SQL connection strings in Key Vault
- [landing-zone](../landing-zone/) - Provides Log Analytics workspace for diagnostics
- [cosmosdb](../cosmosdb/) - Alternative NoSQL database for document-oriented workloads
- [webapp](../webapp/) - App Service that can connect to SQL databases

## Related Documentation

- [Azure SQL Database Documentation](https://learn.microsoft.com/en-us/azure/azure-sql/database/)
- [SQL Server Terraform Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/mssql_server)
- [Azure SQL Security Best Practices](https://learn.microsoft.com/en-us/azure/azure-sql/database/security-best-practice)
- [Private Link for Azure SQL](https://learn.microsoft.com/en-us/azure/azure-sql/database/private-endpoint-overview)
- [Azure SQL SKU Comparison](https://learn.microsoft.com/en-us/azure/azure-sql/database/service-tiers-general-purpose-business-critical)
