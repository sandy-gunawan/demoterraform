# Security Module - Azure Key Vault

Manage secrets, keys, and certificates with Azure Key Vault. This module provides centralized secrets management with RBAC, network isolation, and audit logging.

## Features

- ✅ **Secret Management** - Store connection strings, API keys, passwords
- ✅ **RBAC Authorization** - Use Azure AD roles instead of access policies
- ✅ **Network Isolation** - Private endpoints and firewall rules
- ✅ **Audit Logging** - All access logged to Log Analytics
- ✅ **Soft Delete** - Recover deleted secrets (7-90 days retention)
- ✅ **Purge Protection** - Prevent permanent deletion in production
- ✅ **Private DNS** - Automatic private DNS zone configuration

## Usage

### Basic Example

```hcl
module "security" {
  source = "../../modules/security"

  resource_group_name = "myapp-security-rg-dev"
  location            = "eastus"
  key_vault_name      = "myapp-kv-dev-001"
  tenant_id           = "12345678-1234-1234-1234-123456789012"

  # Basic security settings
  sku_name                 = "standard"
  purge_protection_enabled = false  # Allow deletion in dev

  # Network rules (default deny + allow Azure services)
  network_acls_default_action = "Deny"
  network_acls_bypass         = "AzureServices"

  tags = module.global_standards.common_tags
}
```

### With Secrets

```hcl
module "security" {
  source = "../../modules/security"

  resource_group_name = "myapp-security-rg-prod"
  location            = "eastus"
  key_vault_name      = "myapp-kv-prod-001"
  tenant_id           = var.tenant_id

  # Create secrets
  secrets = {
    "db-connection-string" = {
      value        = "Server=mydb.database.windows.net;Database=prod;..."
      content_type = "connection-string"
    }
    "api-key" = {
      value        = var.api_key
      content_type = "api-key"
    }
    "storage-account-key" = {
      value = azurerm_storage_account.main.primary_access_key
    }
  }

  tags = module.global_standards.common_tags
}
```

### With VNet Integration (Private Endpoint)

```hcl
module "security" {
  source = "../../modules/security"

  resource_group_name = "myapp-security-rg-prod"
  location            = "eastus"
  key_vault_name      = "myapp-kv-prod-001"
  tenant_id           = var.tenant_id

  # Network isolation
  network_acls_default_action = "Deny"
  virtual_network_subnet_ids  = [
    module.networking.subnet_ids["app-subnet"]
  ]

  # Private endpoint
  create_private_endpoint      = true
  private_endpoint_subnet_id   = module.networking.subnet_ids["data-subnet"]
  vnet_id                      = module.networking.vnet_id

  tags = module.global_standards.common_tags
}
```

### With Log Analytics Integration

```hcl
module "security" {
  source = "../../modules/security"

  resource_group_name = "myapp-security-rg-prod"
  location            = "eastus"
  key_vault_name      = "myapp-kv-prod-001"
  tenant_id           = var.tenant_id

  # Send audit logs to Log Analytics
  log_analytics_workspace_id = azurerm_log_analytics_workspace.prod.id

  purge_protection_enabled = true  # Production setting

  tags = module.global_standards.common_tags
}
```

### Production Configuration

```hcl
module "security" {
  source = "../../modules/security"

  resource_group_name = "myapp-security-rg-prod"
  location            = "eastus"
  key_vault_name      = "myapp-kv-prod-001"
  tenant_id           = var.tenant_id

  # Production SKU (supports HSM-backed keys)
  sku_name = "premium"

  # Production protection
  purge_protection_enabled   = true   # Cannot delete permanently
  soft_delete_retention_days = 90     # Max retention

  # Use RBAC (recommended)
  enable_rbac_authorization = true

  # Network security
  network_acls_default_action = "Deny"
  network_acls_ip_rules       = ["203.0.113.0/24"]  # Office IP
  virtual_network_subnet_ids  = [
    module.networking.subnet_ids["aks-subnet"],
    module.networking.subnet_ids["app-subnet"]
  ]

  # Private access only
  create_private_endpoint    = true
  private_endpoint_subnet_id = module.networking.subnet_ids["data-subnet"]
  vnet_id                    = module.networking.vnet_id

  # Audit logging
  log_analytics_workspace_id = azurerm_log_analytics_workspace.prod.id

  tags = module.global_standards.common_tags
}
```

## Inputs

| Name | Description | Type | Required | Default |
|------|-------------|------|----------|---------|
| `resource_group_name` | Resource group name | string | Yes | - |
| `location` | Azure region | string | Yes | - |
| `key_vault_name` | Key Vault name (3-24 chars, unique) | string | Yes | - |
| `tenant_id` | Azure AD tenant ID | string | Yes | - |
| `sku_name` | SKU (standard or premium) | string | No | "standard" |
| `enable_rbac_authorization` | Use RBAC for access control | bool | No | true |
| `purge_protection_enabled` | Prevent permanent deletion | bool | No | false |
| `soft_delete_retention_days` | Retention days (7-90) | number | No | 90 |
| `network_acls_default_action` | Default network action | string | No | "Deny" |
| `network_acls_bypass` | Bypass for Azure services | string | No | "AzureServices" |
| `network_acls_ip_rules` | Allowed IP addresses | list(string) | No | [] |
| `virtual_network_subnet_ids` | Allowed subnet IDs | list(string) | No | [] |
| `log_analytics_workspace_id` | Log Analytics workspace ID | string | No | null |
| `secrets` | Secrets to create | map(object) | No | {} |
| `create_private_endpoint` | Create private endpoint | bool | No | false |
| `private_endpoint_subnet_id` | Private endpoint subnet ID | string | No | null |
| `vnet_id` | VNet ID for private DNS | string | No | null |
| `tags` | Resource tags | map(string) | Yes | - |

## Outputs

| Name | Description |
|------|-------------|
| `key_vault_id` | Key Vault resource ID |
| `key_vault_name` | Key Vault name |
| `key_vault_uri` | Key Vault URI (https://...) |
| `secret_ids` | Map of secret names to IDs |
| `private_endpoint_id` | Private endpoint ID |
| `private_endpoint_ip` | Private endpoint IP address |

## RBAC Roles

After creating Key Vault with RBAC enabled, assign roles:

```bash
# Grant yourself admin access
az role assignment create \
  --role "Key Vault Administrator" \
  --assignee "user@company.com" \
  --scope "/subscriptions/SUB_ID/resourceGroups/RG_NAME/providers/Microsoft.KeyVault/vaults/KV_NAME"

# Grant app access to secrets
az role assignment create \
  --role "Key Vault Secrets User" \
  --assignee "APP_OBJECT_ID" \
  --scope "/subscriptions/SUB_ID/resourceGroups/RG_NAME/providers/Microsoft.KeyVault/vaults/KV_NAME"
```

Built-in roles:
- **Key Vault Administrator** - Full management
- **Key Vault Secrets Officer** - Create/manage secrets
- **Key Vault Secrets User** - Read secrets only
- **Key Vault Crypto Officer** - Manage keys
- **Key Vault Crypto User** - Encrypt/decrypt with keys

## Accessing Secrets

### From Application Code

```python
# Python example
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient

credential = DefaultAzureCredential()
client = SecretClient(vault_url="https://myapp-kv-prod-001.vault.azure.net/", credential=credential)

secret = client.get_secret("db-connection-string")
print(secret.value)
```

```csharp
// C# example
using Azure.Identity;
using Azure.Security.KeyVault.Secrets;

var client = new SecretClient(
    new Uri("https://myapp-kv-prod-001.vault.azure.net/"),
    new DefaultAzureCredential()
);

KeyVaultSecret secret = await client.GetSecretAsync("db-connection-string");
Console.WriteLine(secret.Value);
```

### From Azure Resources

**AKS:** Use Workload Identity or CSI driver
**Container Apps:** Reference as environment variable
**App Service:** Use Key Vault references

## Best Practices

### 1. Use RBAC (Not Access Policies)

```hcl
enable_rbac_authorization = true  # ✅ Recommended
```

### 2. Enable Purge Protection in Production

```hcl
purge_protection_enabled = true  # ✅ Production
```

### 3. Network Isolation

```hcl
network_acls_default_action = "Deny"
virtual_network_subnet_ids  = [subnet_ids]
create_private_endpoint     = true
```

### 4. Audit Logging

```hcl
log_analytics_workspace_id = workspace_id
```

Query audit logs:
```kusto
AzureDiagnostics
| where ResourceProvider == "MICROSOFT.KEYVAULT"
| where OperationName == "SecretGet"
| project TimeGenerated, CallerIPAddress, identity_claim_upn_s, ResultDescription
```

### 5. Secret Rotation

Rotate secrets regularly:
- Database passwords: 90 days
- API keys: 180 days
- Certificates: Before expiration

### 6. Least Privilege Access

Use **Key Vault Secrets User** for apps (read-only).

## Common Patterns

### Pattern 1: Shared Key Vault

```hcl
# One Key Vault shared by all apps
module "shared_security" {
  source = "../../modules/security"

  key_vault_name = "myorg-shared-kv-prod"
  # ... other config ...
}

# App 1 uses it
module "app1" {
  key_vault_id = module.shared_security.key_vault_id
}

# App 2 uses it
module "app2" {
  key_vault_id = module.shared_security.key_vault_id
}
```

### Pattern 2: Per-App Key Vault

```hcl
# Each app gets its own Key Vault
module "app1_security" {
  source = "../../modules/security"
  key_vault_name = "myapp1-kv-prod"
}

module "app2_security" {
  source = "../../modules/security"
  key_vault_name = "myapp2-kv-prod"
}
```

## Troubleshooting

**Error: Key Vault name already exists**
- Key Vault names are globally unique
- Use suffix: `myapp-kv-prod-001`

**Error: Forbidden (403)**
- Assign RBAC role: `Key Vault Secrets User`
- Check network rules allow your IP/VNet

**Error: Soft delete conflict**
- Key Vault still in soft-delete state
- Recover: `az keyvault recover --name KV_NAME`
- Or purge: `az keyvault purge --name KV_NAME`

## Cost

Key Vault pricing:
- **Standard:** $0.03 per 10,000 operations
- **Premium:** $0.03 per 10,000 operations + HSM key costs
- **Secrets:** First 10,000 operations/month free

Typical costs: **$1-5/month** for small apps.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| azurerm | ~> 3.80.0 |

## Related Modules

- [landing-zone](../landing-zone/) - Provides VNet for private endpoints
- [aks](../aks/) - Can use Workload Identity to access Key Vault
- [container-app](../container-app/) - Can reference secrets from Key Vault
