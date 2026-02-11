# Azure Database for PostgreSQL Flexible Server Module

## Purpose

This module creates an Azure Database for PostgreSQL Flexible Server with configurable databases, high availability, VNet integration, Azure AD authentication, and diagnostic logging. It follows Azure best practices for security, reliability, and cost optimization across dev, staging, and production environments.

## Why This Module?

- **Managed PostgreSQL**: Fully managed, community-edition PostgreSQL with no licensing costs
- **Flexible Compute**: Burstable, General Purpose, and Memory Optimized SKU tiers
- **High Availability**: Zone-redundant and same-zone HA with automatic failover
- **VNet Integration**: Private access through delegated subnets and private DNS zones
- **Security**: Azure AD authentication, password auth, and network-level isolation
- **Multiple Databases**: Create multiple databases per server via `for_each`
- **Server Tuning**: Apply PostgreSQL configuration parameters (e.g., `shared_buffers`, `work_mem`)
- **Firewall Rules**: Conditional rules only when public access is enabled
- **Observability**: Diagnostic settings with Log Analytics for PostgreSQLLogs and AllMetrics
- **Geo-Redundant Backups**: Cross-region backup replication for disaster recovery

## Resources Created

| Resource | Description |
|----------|-------------|
| `azurerm_postgresql_flexible_server` | The core PostgreSQL Flexible Server instance |
| `azurerm_postgresql_flexible_server_database` | One or more databases (via `for_each`) |
| `azurerm_postgresql_flexible_server_configuration` | Server parameter configurations (via `for_each`) |
| `azurerm_postgresql_flexible_server_firewall_rule` | Firewall rules (only when `public_network_access_enabled = true`) |
| `azurerm_monitor_diagnostic_setting` | Diagnostic logging (conditional on `log_analytics_workspace_id`) |

## Architecture

```
┌──────────────────────────────────────────────────────────────────────┐
│                         Azure Subscription                           │
│                                                                      │
│   ┌──────────────────────────────────────────────────────────────┐   │
│   │                     Resource Group                            │   │
│   │                                                               │   │
│   │   ┌───────────────────────────────────────────────────────┐   │   │
│   │   │          PostgreSQL Flexible Server                    │   │   │
│   │   │   ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  │   │   │
│   │   │   │  Database 1  │  │  Database 2  │  │  Database N  │  │   │   │
│   │   │   └─────────────┘  └─────────────┘  └─────────────┘  │   │   │
│   │   │                                                        │   │   │
│   │   │   Auth: Password + Azure AD    Version: 13-16          │   │   │
│   │   │   SKU:  B/GP/MO               HA: Zone/Same/None      │   │   │
│   │   └────────────────────┬──────────────────────────────────┘   │   │
│   │                        │                                      │   │
│   │            ┌───────────┴───────────┐                          │   │
│   │            │                       │                          │   │
│   │   ┌────────▼────────┐    ┌────────▼────────┐                 │   │
│   │   │  VNet + Subnet   │    │  Public Access   │                │   │
│   │   │  (delegated)     │    │  + Firewall Rules │                │   │
│   │   │  + Private DNS   │    │  (dev/test only)  │                │   │
│   │   └─────────────────┘    └──────────────────┘                 │   │
│   │                                                               │   │
│   │   ┌───────────────────────────────────────────────────────┐   │   │
│   │   │              Diagnostic Settings                       │   │   │
│   │   │   → Log Analytics Workspace (PostgreSQLLogs + Metrics) │   │   │
│   │   └───────────────────────────────────────────────────────┘   │   │
│   └──────────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────────┘
```

## Usage Examples

### Basic Usage (Development)

```hcl
module "postgresql" {
  source = "../../modules/postgresql"

  resource_group_name    = azurerm_resource_group.main.name
  server_name            = "myproject-pg-dev"
  location               = var.location
  administrator_login    = var.pg_admin_login
  administrator_password = var.pg_admin_password

  sku_name            = "B_Standard_B1ms"
  storage_mb          = 32768
  postgresql_version   = "16"

  databases = {
    "app-db" = {
      charset   = "UTF8"
      collation = "en_US.utf8"
    }
  }

  tags = module.global_standards.common_tags
}
```

### VNet-Integrated Usage (Staging)

```hcl
module "postgresql" {
  source = "../../modules/postgresql"

  resource_group_name    = azurerm_resource_group.main.name
  server_name            = "myproject-pg-staging"
  location               = var.location
  administrator_login    = var.pg_admin_login
  administrator_password = var.pg_admin_password

  sku_name            = "GP_Standard_D2s_v3"
  storage_mb          = 65536
  postgresql_version   = "16"
  backup_retention_days = 14

  # VNet integration — disable public access
  public_network_access_enabled = false
  delegated_subnet_id           = azurerm_subnet.pg_delegated.id
  private_dns_zone_id           = azurerm_private_dns_zone.pg.id

  # Azure AD authentication
  aad_auth_enabled      = true
  password_auth_enabled = true
  tenant_id             = data.azurerm_client_config.current.tenant_id

  databases = {
    "app-db" = {}
    "analytics-db" = {
      collation = "en_US.utf8"
      charset   = "UTF8"
    }
  }

  server_configurations = {
    "shared_buffers"       = "262144"
    "work_mem"             = "16384"
    "log_min_duration_statement" = "1000"
  }

  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  tags = module.global_standards.common_tags
}
```

### High Availability Production Usage

```hcl
module "postgresql" {
  source = "../../modules/postgresql"

  resource_group_name    = azurerm_resource_group.main.name
  server_name            = "myproject-pg-prod"
  location               = var.location
  administrator_login    = var.pg_admin_login
  administrator_password = var.pg_admin_password

  sku_name            = "GP_Standard_D4s_v3"
  storage_mb          = 131072
  postgresql_version   = "16"
  backup_retention_days = 35

  # High availability
  high_availability_mode    = "ZoneRedundant"
  availability_zone         = "1"
  standby_availability_zone = "2"

  # Geo-redundant backups for DR
  geo_redundant_backup_enabled = true

  # VNet integration — no public access
  public_network_access_enabled = false
  delegated_subnet_id           = azurerm_subnet.pg_delegated.id
  private_dns_zone_id           = azurerm_private_dns_zone.pg.id

  # Azure AD only (disable password auth in prod)
  aad_auth_enabled      = true
  password_auth_enabled = false
  tenant_id             = data.azurerm_client_config.current.tenant_id

  databases = {
    "app-db"       = {}
    "analytics-db" = {}
    "audit-db"     = {}
  }

  server_configurations = {
    "shared_buffers"              = "524288"
    "work_mem"                    = "32768"
    "effective_cache_size"        = "1572864"
    "log_min_duration_statement"  = "500"
    "idle_in_transaction_session_timeout" = "60000"
  }

  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  tags = module.global_standards.common_tags
}
```

## Input Variables

| Variable | Type | Default | Required | Description |
|----------|------|---------|----------|-------------|
| `resource_group_name` | `string` | — | **Yes** | Name of the resource group |
| `server_name` | `string` | — | **Yes** | Globally unique name for the PostgreSQL Flexible Server |
| `location` | `string` | — | **Yes** | Azure region for deployment |
| `administrator_login` | `string` (sensitive) | — | **Yes** | Administrator login name |
| `administrator_password` | `string` (sensitive) | — | **Yes** | Administrator password |
| `postgresql_version` | `string` | `"16"` | No | PostgreSQL engine version (13, 14, 15, or 16) |
| `sku_name` | `string` | `"B_Standard_B1ms"` | No | Compute SKU (Burstable, GP, or Memory Optimized) |
| `storage_mb` | `number` | `32768` | No | Storage size in MB |
| `backup_retention_days` | `number` | `7` | No | Backup retention (7–35 days) |
| `geo_redundant_backup_enabled` | `bool` | `false` | No | Enable geo-redundant backups for DR |
| `availability_zone` | `string` | `null` | No | Primary availability zone |
| `high_availability_mode` | `string` | `null` | No | HA mode: `ZoneRedundant`, `SameZone`, or `null` |
| `standby_availability_zone` | `string` | `null` | No | Standby AZ for HA failover |
| `public_network_access_enabled` | `bool` | `true` | No | Enable public network access |
| `delegated_subnet_id` | `string` | `null` | No | Delegated subnet ID for VNet integration |
| `private_dns_zone_id` | `string` | `null` | No | Private DNS zone ID for VNet integration |
| `aad_auth_enabled` | `bool` | `false` | No | Enable Azure Active Directory authentication |
| `password_auth_enabled` | `bool` | `true` | No | Enable password-based authentication |
| `tenant_id` | `string` | `null` | No | Azure AD tenant ID (required when `aad_auth_enabled = true`) |
| `databases` | `map(object)` | `{}` | No | Map of databases to create (keys = db names) |
| `server_configurations` | `map(string)` | `{}` | No | Map of PostgreSQL server parameters |
| `firewall_rules` | `map(object)` | `{}` | No | Map of firewall rules (`start_ip_address`, `end_ip_address`) |
| `log_analytics_workspace_id` | `string` | `null` | No | Log Analytics workspace ID for diagnostics |
| `tags` | `map(string)` | `{}` | No | Tags to apply to all resources |

### Database Object Schema

```hcl
databases = {
  "my-database" = {
    collation = "en_US.utf8"   # optional, default: "en_US.utf8"
    charset   = "UTF8"         # optional, default: "UTF8"
  }
}
```

### Firewall Rule Object Schema

```hcl
firewall_rules = {
  "allow-office" = {
    start_ip_address = "203.0.113.0"
    end_ip_address   = "203.0.113.255"
  }
}
```

## Outputs

| Output | Description |
|--------|-------------|
| `server_id` | The resource ID of the PostgreSQL Flexible Server |
| `server_name` | The name of the PostgreSQL Flexible Server |
| `server_fqdn` | The fully qualified domain name (FQDN) for connecting to the server |
| `database_ids` | Map of database names to their resource IDs |
| `resource_group_name` | The resource group name where the server is deployed |

## Environment Recommendations

| Setting | Dev | Staging | Production |
|---------|-----|---------|------------|
| `sku_name` | `B_Standard_B1ms` | `GP_Standard_D2s_v3` | `GP_Standard_D4s_v3`+ |
| `storage_mb` | `32768` (32 GB) | `65536` (64 GB) | `131072`+ (128 GB+) |
| `backup_retention_days` | `7` | `14` | `35` |
| `high_availability_mode` | `null` | `SameZone` | `ZoneRedundant` |
| `geo_redundant_backup_enabled` | `false` | `false` | `true` |
| `public_network_access_enabled` | `true` | `false` | `false` |
| `aad_auth_enabled` | `false` | `true` | `true` |
| `password_auth_enabled` | `true` | `true` | `false` |
| `log_analytics_workspace_id` | optional | set | set |

## SKU Naming Convention

SKU names follow the pattern `{Tier}_{VM_Family}`:

| Tier Prefix | Tier Name | Use Case |
|-------------|-----------|----------|
| `B_` | Burstable | Dev/test, light workloads, cost-sensitive |
| `GP_` | General Purpose | Production, balanced compute and memory |
| `MO_` | Memory Optimized | High-memory workloads, large caches, analytics |

**Common SKUs:**

| SKU | vCores | Memory | Tier |
|-----|--------|--------|------|
| `B_Standard_B1ms` | 1 | 2 GB | Burstable |
| `B_Standard_B2s` | 2 | 4 GB | Burstable |
| `GP_Standard_D2s_v3` | 2 | 8 GB | General Purpose |
| `GP_Standard_D4s_v3` | 4 | 16 GB | General Purpose |
| `GP_Standard_D8s_v3` | 8 | 32 GB | General Purpose |
| `MO_Standard_E4s_v3` | 4 | 32 GB | Memory Optimized |
| `MO_Standard_E8s_v3` | 8 | 64 GB | Memory Optimized |

## VNet Integration Requirements

When using VNet integration (`delegated_subnet_id` is set), the following must be configured:

1. **Delegated Subnet**: A subnet delegated to `Microsoft.DBforPostgreSQL/flexibleServers`
2. **Private DNS Zone**: An `azurerm_private_dns_zone` with name `*.postgres.database.azure.com`
3. **DNS Zone VNet Link**: The private DNS zone must be linked to the VNet
4. **Public Access Disabled**: Set `public_network_access_enabled = false`

```hcl
# Example: VNet prerequisites
resource "azurerm_subnet" "pg_delegated" {
  name                 = "snet-pg-delegated"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.4.0/24"]

  delegation {
    name = "postgresql"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action"
      ]
    }
  }
}

resource "azurerm_private_dns_zone" "pg" {
  name                = "myproject.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "pg" {
  name                  = "pg-vnet-link"
  private_dns_zone_name = azurerm_private_dns_zone.pg.name
  resource_group_name   = azurerm_resource_group.main.name
  virtual_network_id    = azurerm_virtual_network.main.id
}
```

## Troubleshooting

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| Server name already exists | Server names are globally unique | Choose a different `server_name` |
| Cannot enable HA with Burstable SKU | HA requires General Purpose or Memory Optimized | Upgrade to a `GP_` or `MO_` SKU |
| VNet integration fails | Subnet not delegated properly | Ensure subnet has `Microsoft.DBforPostgreSQL/flexibleServers` delegation |
| Cannot connect from app | Firewall rules missing or VNet not linked | Add firewall rules (public) or ensure app is in same/peered VNet (private) |
| Cannot change `geo_redundant_backup_enabled` | Can only be set at creation time | Recreate the server with the correct setting |
| AAD auth not working | Missing `tenant_id` | Set `tenant_id` when `aad_auth_enabled = true` |
| Storage cannot be decreased | PostgreSQL Flexible Server storage is grow-only | Plan initial storage carefully; it can only be increased |
| Configuration parameter error | Invalid parameter name or value | Check [Azure docs](https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/concepts-server-parameters) for valid parameters |

### Useful Server Configuration Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `shared_buffers` | varies by SKU | Memory for caching data (set to ~25% of total RAM) |
| `work_mem` | `4096` | Memory for query sort/hash operations |
| `effective_cache_size` | varies | Planner estimate of available cache |
| `log_min_duration_statement` | `-1` (disabled) | Log queries slower than N ms |
| `idle_in_transaction_session_timeout` | `0` (disabled) | Kill idle-in-transaction sessions after N ms |
| `max_connections` | varies by SKU | Maximum concurrent connections |

## Related Documentation

- [Azure PostgreSQL Flexible Server Docs](https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/)
- [SKU and Pricing](https://azure.microsoft.com/en-us/pricing/details/postgresql/flexible-server/)
- [High Availability Concepts](https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/concepts-high-availability)
- [VNet Integration](https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/concepts-networking)
- [Server Parameters](https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/concepts-server-parameters)
- [Terraform azurerm_postgresql_flexible_server](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server)

## Related Modules

- [`networking`](../networking/README.md) — VNet and subnet creation (including delegated subnets)
- [`security`](../security/README.md) — Key Vault for storing credentials
- [`landing-zone`](../landing-zone/README.md) — Resource group and base infrastructure
