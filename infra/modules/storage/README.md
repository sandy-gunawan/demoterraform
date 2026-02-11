# Azure Storage Account Module

> Enterprise-ready Azure Storage Account with configurable containers, network rules, blob lifecycle management, diagnostics, and optional private endpoints.

---

## Features

- **Storage Account** — Configurable tier (Standard/Premium), replication (LRS/GRS/ZRS/GZRS/RAGRS/RAGZRS), StorageV2 kind, enforced TLS 1.2, HTTPS-only
- **Blob Properties** — Versioning, change feed, last access time tracking, soft delete for blobs and containers
- **Network Rules** — Dynamic firewall with IP whitelisting, subnet allowlisting, Azure service bypass
- **System-Assigned Managed Identity** — Automatic identity for RBAC-based access (no keys needed)
- **Storage Containers** — Create multiple containers via `for_each` with configurable access types
- **Diagnostics** — Conditional integration with Log Analytics workspace (Transaction metrics)
- **Private Endpoint** — Conditional private endpoint for blob subresource (no public internet exposure)

---

## Architecture

```
                         ┌──────────────────────────────────────────────┐
                         │           Azure Resource Group               │
                         │                                              │
  ┌──────────┐           │  ┌───────────────────────────────────────┐   │
  │  Users /  │──(HTTPS)──│─▶│     Storage Account (StorageV2)      │   │
  │  Apps     │           │  │  • TLS 1.2 enforced                  │   │
  └──────────┘           │  │  • HTTPS-only traffic                 │   │
                         │  │  • System-assigned managed identity   │   │
                         │  │                                       │   │
                         │  │  ┌────────────┐  ┌────────────┐      │   │
                         │  │  │ Container  │  │ Container  │ ...  │   │
                         │  │  │ "data"     │  │ "logs"     │      │   │
                         │  │  └────────────┘  └────────────┘      │   │
                         │  │                                       │   │
                         │  │  Blob Properties:                     │   │
                         │  │  • Versioning, Change Feed            │   │
                         │  │  • Soft Delete (blobs + containers)   │   │
                         │  └──────────────┬────────────────────────┘   │
                         │                 │                            │
                         │    ┌────────────┴────────────┐               │
                         │    │                         │               │
                         │    ▼                         ▼               │
                         │  ┌──────────────┐  ┌────────────────────┐   │
                         │  │  Diagnostics  │  │  Private Endpoint  │   │
                         │  │  (optional)   │  │  (optional)        │   │
                         │  │  ─▶ Log       │  │  ─▶ blob subres.  │   │
                         │  │    Analytics  │  │  ─▶ private subnet │   │
                         │  └──────────────┘  └────────────────────┘   │
                         │                                              │
                         │  ┌───────────────────────────────────────┐   │
                         │  │  Network Rules (optional)             │   │
                         │  │  • Default action: Allow / Deny       │   │
                         │  │  • IP allowlist                       │   │
                         │  │  • Subnet allowlist                   │   │
                         │  │  • Bypass: AzureServices              │   │
                         │  └───────────────────────────────────────┘   │
                         └──────────────────────────────────────────────┘
```

---

## Usage

### Basic Usage

```hcl
module "storage" {
  source = "../../modules/storage"

  resource_group_name  = azurerm_resource_group.main.name
  storage_account_name = "myprojectstdev"
  location             = var.location

  tags = module.global_standards.common_tags
}
```

### With Containers and Versioning

```hcl
module "storage" {
  source = "../../modules/storage"

  resource_group_name  = azurerm_resource_group.main.name
  storage_account_name = "myprojectstdev"
  location             = var.location

  # Create multiple containers
  containers = {
    "data"    = { access_type = "private" }
    "logs"    = { access_type = "private" }
    "backups" = { access_type = "private" }
  }

  # Enable blob protection features
  blob_versioning_enabled       = true
  blob_change_feed_enabled      = true
  blob_last_access_time_enabled = true
  blob_delete_retention_days    = 30
  container_delete_retention_days = 30

  tags = module.global_standards.common_tags
}
```

### With Network Rules (Firewall)

```hcl
module "storage" {
  source = "../../modules/storage"

  resource_group_name  = azurerm_resource_group.main.name
  storage_account_name = "myprojectstprod"
  location             = var.location

  # Lock down network access
  network_rules_default_action = "Deny"
  network_rules_bypass         = ["AzureServices"]
  network_rules_ip_rules       = ["203.0.113.0/24"]    # Your office IP range
  network_rules_subnet_ids     = [module.networking.aks_subnet_id]

  tags = module.global_standards.common_tags
}
```

### With Private Endpoint

```hcl
module "storage" {
  source = "../../modules/storage"

  resource_group_name  = azurerm_resource_group.main.name
  storage_account_name = "myprojectstprod"
  location             = var.location

  # Private endpoint for blob access
  enable_private_endpoint    = true
  private_endpoint_subnet_id = module.networking.data_subnet_id

  # Lock down public access
  network_rules_default_action = "Deny"
  network_rules_bypass         = ["AzureServices"]

  tags = module.global_standards.common_tags
}
```

### Production-Ready (All Features)

```hcl
module "storage" {
  source = "../../modules/storage"

  resource_group_name  = azurerm_resource_group.main.name
  storage_account_name = "myprojectstprod"
  location             = var.location

  # High availability
  account_tier             = "Standard"
  account_replication_type = "GRS"

  # Containers
  containers = {
    "data"    = { access_type = "private" }
    "logs"    = { access_type = "private" }
    "backups" = { access_type = "private" }
  }

  # Blob protection
  blob_versioning_enabled         = true
  blob_change_feed_enabled        = true
  blob_last_access_time_enabled   = true
  blob_delete_retention_days      = 90
  container_delete_retention_days = 90

  # Network lockdown
  network_rules_default_action = "Deny"
  network_rules_bypass         = ["AzureServices"]
  network_rules_ip_rules       = ["203.0.113.0/24"]
  network_rules_subnet_ids     = [module.networking.app_subnet_id]

  # Private endpoint
  enable_private_endpoint    = true
  private_endpoint_subnet_id = module.networking.data_subnet_id

  # Diagnostics
  log_analytics_workspace_id = module.security.log_analytics_workspace_id

  tags = module.global_standards.common_tags
}
```

---

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `resource_group_name` | Name of the resource group | `string` | — | **yes** |
| `storage_account_name` | Name of the storage account (3-24 lowercase alphanumeric only) | `string` | — | **yes** |
| `location` | Azure region | `string` | — | **yes** |
| `account_tier` | Storage account tier (`Standard` or `Premium`) | `string` | `"Standard"` | no |
| `account_replication_type` | Replication type (`LRS`, `GRS`, `RAGRS`, `ZRS`, `GZRS`, `RAGZRS`) | `string` | `"LRS"` | no |
| `account_kind` | Storage account kind | `string` | `"StorageV2"` | no |
| `min_tls_version` | Minimum TLS version | `string` | `"TLS1_2"` | no |
| `allow_blob_public_access` | Allow public access to blobs | `bool` | `false` | no |
| `network_rules_default_action` | Default action for network rules (`Allow`/`Deny`, `null` to skip) | `string` | `null` | no |
| `network_rules_bypass` | Services to bypass network rules | `list(string)` | `["AzureServices"]` | no |
| `network_rules_ip_rules` | Allowed IP addresses/CIDR ranges | `list(string)` | `[]` | no |
| `network_rules_subnet_ids` | Allowed subnet IDs | `list(string)` | `[]` | no |
| `blob_versioning_enabled` | Enable blob versioning | `bool` | `false` | no |
| `blob_change_feed_enabled` | Enable blob change feed | `bool` | `false` | no |
| `blob_last_access_time_enabled` | Enable last access time tracking | `bool` | `false` | no |
| `blob_delete_retention_days` | Soft delete retention for blobs in days (`null` to disable) | `number` | `7` | no |
| `container_delete_retention_days` | Soft delete retention for containers in days (`null` to disable) | `number` | `7` | no |
| `containers` | Map of storage containers to create | `map(object({ access_type = optional(string, "private") }))` | `{}` | no |
| `log_analytics_workspace_id` | Log Analytics workspace ID for diagnostics | `string` | `null` | no |
| `enable_private_endpoint` | Create a private endpoint for blob access | `bool` | `false` | no |
| `private_endpoint_subnet_id` | Subnet ID for the private endpoint | `string` | `null` | no |
| `tags` | Tags to apply to all resources | `map(string)` | `{}` | no |

---

## Outputs

| Name | Description | Sensitive |
|------|-------------|:---------:|
| `storage_account_id` | Storage account resource ID | no |
| `storage_account_name` | Storage account name | no |
| `primary_blob_endpoint` | Primary blob endpoint URL | no |
| `primary_access_key` | Primary access key | **yes** |
| `primary_connection_string` | Primary connection string | **yes** |
| `resource_group_name` | Resource group name | no |
| `principal_id` | System-assigned managed identity principal ID | no |

---

## Replication Type Comparison

| Type | Full Name | Copies | Regions | Durability | Use Case |
|------|-----------|:------:|:-------:|------------|----------|
| **LRS** | Locally Redundant Storage | 3 | 1 | 99.999999999% (11 9's) | Dev/test, non-critical data |
| **ZRS** | Zone-Redundant Storage | 3 | 1 (3 zones) | 99.9999999999% (12 9's) | Production, high availability |
| **GRS** | Geo-Redundant Storage | 6 | 2 | 99.99999999999999% (16 9's) | Disaster recovery, compliance |
| **RAGRS** | Read-Access GRS | 6 | 2 (read from secondary) | 99.99999999999999% (16 9's) | Read-heavy DR workloads |
| **GZRS** | Geo-Zone-Redundant | 6 | 2 (3 zones in primary) | 99.99999999999999% (16 9's) | Maximum durability + availability |
| **RAGZRS** | Read-Access GZRS | 6 | 2 (read from secondary) | 99.99999999999999% (16 9's) | Ultimate redundancy |

---

## Environment Recommendations

### Development

```hcl
account_replication_type = "LRS"           # Cheapest, single region
blob_versioning_enabled  = false           # Not needed for dev
enable_private_endpoint  = false           # No private networking
blob_delete_retention_days = 7             # Short retention
# network_rules_default_action left null   # No firewall
```

### Staging

```hcl
account_replication_type = "ZRS"           # Zone redundancy for realistic testing
blob_versioning_enabled  = true            # Test versioning behavior
enable_private_endpoint  = true            # Test private endpoint connectivity
blob_delete_retention_days = 14            # Moderate retention
network_rules_default_action = "Deny"      # Test with firewall
```

### Production

```hcl
account_replication_type = "GRS"           # Geo-redundancy for disaster recovery
blob_versioning_enabled  = true            # Full data protection
blob_change_feed_enabled = true            # Audit trail
enable_private_endpoint  = true            # No public exposure
blob_delete_retention_days = 90            # Long retention for compliance
container_delete_retention_days = 90       # Protect containers too
network_rules_default_action = "Deny"      # Firewall locked down
log_analytics_workspace_id = "..."         # Full diagnostics
```

---

## Storage Account Naming Rules

> **Warning:** Azure Storage account names have strict requirements that differ from most Azure resources.

| Rule | Requirement |
|------|-------------|
| Length | 3–24 characters |
| Characters | **Lowercase letters and numbers only** (no hyphens, underscores, or uppercase) |
| Uniqueness | **Globally unique** across all of Azure |
| Validation | This module enforces the pattern `^[a-z0-9]{3,24}$` |

**Naming convention examples:**

```
Good:  myprojectstdev      (project + st + env)
Good:  acmelogstorageprod  (company + purpose + env)
Good:  app01st2026dev      (app + st + year + env)

Bad:   my-project-storage  (hyphens not allowed)
Bad:   MyProjectStorage    (uppercase not allowed)
Bad:   st                  (too short, minimum 3 chars)
```

---

## Feature Toggles Quick Reference

| Feature | Variable | Default | When to Enable |
|---------|----------|---------|----------------|
| Network firewall | `network_rules_default_action` | `null` (off) | Staging & Production |
| Private endpoint | `enable_private_endpoint` | `false` | Staging & Production |
| Blob versioning | `blob_versioning_enabled` | `false` | Staging & Production |
| Change feed | `blob_change_feed_enabled` | `false` | Production (audit/compliance) |
| Last access tracking | `blob_last_access_time_enabled` | `false` | Cost optimization scenarios |
| Diagnostics | `log_analytics_workspace_id` | `null` (off) | All environments (recommended) |
| Public blob access | `allow_blob_public_access` | `false` | Rarely — only for public static assets |

---

## Troubleshooting

### "Storage account name already exists"

Storage account names are **globally unique across all Azure**. If someone else in the world has taken the name, you must pick a different one. Add your team name, project abbreviation, or a random suffix.

### "AuthorizationFailure" when accessing blobs

If you enabled `network_rules_default_action = "Deny"`, your client IP or subnet must be explicitly allowed. Check:
1. Your IP is in `network_rules_ip_rules`
2. Your subnet is in `network_rules_subnet_ids`
3. `network_rules_bypass` includes `"AzureServices"` if accessing from other Azure resources

### "Private endpoint not resolving"

Ensure your VNet has a Private DNS Zone for `privatelink.blob.core.windows.net` linked to it. Without DNS resolution, clients inside the VNet won't resolve the storage account to its private IP.

### "Soft-deleted data still consuming storage"

Soft delete retains deleted blobs/containers for the configured retention period. This is by design. Data is permanently removed only after the retention period expires. Reduce `blob_delete_retention_days` if storage costs are a concern.

### "Cannot enable versioning on Premium storage"

Blob versioning is only supported on Standard general-purpose v2 (StorageV2) accounts. Premium storage accounts do not support this feature.

---

## Resources Created

This module conditionally creates the following Azure resources:

| Resource | Type | Condition |
|----------|------|-----------|
| Storage Account | `azurerm_storage_account` | Always |
| Storage Container(s) | `azurerm_storage_container` | When `containers` map is non-empty |
| Diagnostic Setting | `azurerm_monitor_diagnostic_setting` | When `log_analytics_workspace_id` is set |
| Private Endpoint | `azurerm_private_endpoint` | When `enable_private_endpoint = true` |

---

## Related Documentation

- [Azure Storage overview](https://learn.microsoft.com/azure/storage/common/storage-introduction)
- [Storage account naming rules](https://learn.microsoft.com/azure/storage/common/storage-account-overview#storage-account-name)
- [Storage redundancy](https://learn.microsoft.com/azure/storage/common/storage-redundancy)
- [Storage firewalls and virtual networks](https://learn.microsoft.com/azure/storage/common/storage-network-security)
- [Private endpoints for Storage](https://learn.microsoft.com/azure/storage/common/storage-private-endpoints)
- [Blob versioning](https://learn.microsoft.com/azure/storage/blobs/versioning-overview)
- [Soft delete for blobs](https://learn.microsoft.com/azure/storage/blobs/soft-delete-blob-overview)
- [Networking module](../networking/README.md) — VNet and subnet configuration
- [Security module](../security/README.md) — Log Analytics and Key Vault
