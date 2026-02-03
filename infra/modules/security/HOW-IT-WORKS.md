# Key Vault (Security Module) - How It Works

A beginner-friendly guide to Azure Key Vault. Learn how to keep your secrets safe!

---

## What is Key Vault?

**Simple explanation:** Key Vault is like a super-secure safety deposit box for your passwords, API keys, and certificates.

```
Without Key Vault:                 With Key Vault:
──────────────────                 ────────────────
Password in code:                  Password in Key Vault:
  password = "MySecret123"           password = getSecret("db-pass")

Problems:                          Benefits:
- Anyone who sees code             - Code contains no secrets
  sees password                    - Access is controlled
- Hard to change passwords         - Easy to rotate secrets
- Passwords in git history         - Full audit trail
```

---

## Why Do We Need Key Vault?

### The Problem with Secrets

```
Where do developers put passwords?

BAD: In code
─────────────
connection_string = "Server=mydb;Password=SuperSecret123"

↓ Code pushed to Git ↓

Anyone with repo access can see it!
Even after you delete it, it's in git history forever!
```

```
BAD: In environment variables
─────────────────────────────
export DB_PASSWORD="SuperSecret123"

↓ Process crashes, dumps memory ↓

Password might appear in:
- Error logs
- Process listings
- Crash dumps
```

```
BAD: In config files
────────────────────
# config.json
{ "password": "SuperSecret123" }

↓ File permissions wrong ↓

Anyone on the server can read it!
```

### The Solution: Key Vault

```
GOOD: In Key Vault
──────────────────

┌─────────────────────────────────────────────────────────────────┐
│                        KEY VAULT                                 │
│                                                                  │
│   ┌───────────────────────────────────────────────────────────┐ │
│   │  SECRETS                                                   │ │
│   │                                                            │ │
│   │  db-password          = "************" (encrypted)        │ │
│   │  api-key              = "************" (encrypted)        │ │
│   │  storage-connection   = "************" (encrypted)        │ │
│   │                                                            │ │
│   └───────────────────────────────────────────────────────────┘ │
│                                                                  │
│   Access Control:                                                │
│   ✅ App-1 can read secrets                                     │
│   ✅ Admin can manage secrets                                   │
│   ❌ Developer can NOT read production secrets                  │
│                                                                  │
│   Audit Log:                                                     │
│   - 2024-01-15 10:30: App-1 read "db-password"                 │
│   - 2024-01-15 11:45: Admin rotated "api-key"                  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Key Concepts (Plain English)

### 1. Secrets

**What:** Hidden values like passwords, connection strings, API keys.

**How it works:**
```
Store:  "db-password" → "MySuperSecretPassword123"
                         (encrypted at rest)

Retrieve: App asks for "db-password"
          Key Vault checks: "Is this app allowed?"
          If yes: Returns the value
          If no: Access denied!
```

### 2. Keys

**What:** Encryption keys for encrypting/decrypting data.

**How it works:**
```
Your data: "Credit card: 4111-1111-1111-1111"
                    │
                    ▼
            Key Vault encrypts
                    │
                    ▼
Encrypted: "xK9#mP2$vL7@qR5..."
           (Unreadable without the key)
```

### 3. Certificates

**What:** SSL/TLS certificates for HTTPS.

**How it works:**
```
Key Vault stores:
- The certificate
- The private key
- Renewal information

Your app: "I need the cert for myapp.com"
Key Vault: "Here it is, and I'll renew it automatically!"
```

---

## Access Control: RBAC vs Access Policies

### The Old Way: Access Policies

```
Key Vault → Access Policies
├── Policy 1: User A can read secrets
├── Policy 2: User B can manage keys
└── Policy 3: App C can read secrets

Problem: Managed separately from rest of Azure
```

### The New Way: RBAC (Our Choice)

```
Azure AD Roles:
├── "Key Vault Administrator" → Full control
├── "Key Vault Secrets Officer" → Manage secrets
├── "Key Vault Secrets User" → Read secrets only
└── "Key Vault Crypto User" → Use keys for encryption

Assign to users/apps like any other Azure resource!
```

**Why RBAC is better:**
| Feature | Access Policies | RBAC (Our Choice) |
|---------|-----------------|-------------------|
| Managed in | Key Vault settings | Azure AD (central) |
| Consistent with other Azure resources | ❌ No | ✅ Yes |
| Fine-grained permissions | ⚠️ Limited | ✅ Very granular |
| Audit trail | ⚠️ Basic | ✅ Full Azure AD logs |

---

## How Apps Get Secrets (No Passwords!)

### The Magic: Managed Identity

Instead of storing passwords to access Key Vault, we use Managed Identity:

```
┌─────────────────────────────────────────────────────────────────┐
│                         YOUR APP (in AKS)                        │
│                                                                  │
│   // No passwords anywhere!                                      │
│   const credential = new DefaultAzureCredential();              │
│   const client = new SecretClient(vaultUrl, credential);        │
│   const secret = await client.getSecret("db-password");         │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ "I'm the AKS app, verified by Azure AD"
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                         AZURE AD                                 │
│                                                                  │
│   "Let me verify... Yes, this is the AKS managed identity"      │
│   "Here's a token proving who you are"                          │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ Token
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                        KEY VAULT                                 │
│                                                                  │
│   "Token received. Let me check RBAC..."                        │
│   "AKS app has 'Key Vault Secrets User' role"                   │
│   "Access granted! Here's the secret value."                    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

**The beauty:** No passwords stored anywhere. Azure handles authentication automatically!

---

## Network Security: Private Access

### Why This Matters

By default, Key Vault has a public endpoint:
```
mykeyvault.vault.azure.net → Public IP (accessible from anywhere!)
```

This is risky! Anyone who gets valid credentials could access it from anywhere.

### Our Solution: Network Restrictions

```
┌─────────────────────────────────────────────────────────────────┐
│                    KEY VAULT FIREWALL                            │
│                                                                  │
│   Who can access?                                                │
│                                                                  │
│   ✅ Requests from VNet: 10.1.1.0/24 (AKS subnet)              │
│   ✅ Requests from VNet: 10.1.2.0/24 (App subnet)              │
│   ✅ Requests from Office IP: 203.0.113.0/24                   │
│   ❌ All other requests: DENIED                                 │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘

Hacker from random IP → Key Vault = BLOCKED! 🛡️
```

### Even More Secure: Private Endpoint

```
┌─────────────────────────────────────────────────────────────────┐
│                         YOUR VNET                                │
│                                                                  │
│   ┌─────────────┐          ┌────────────────────────────────┐  │
│   │   Your App  │ ───────→ │  Key Vault (Private Endpoint)  │  │
│   │ 10.1.1.50   │          │  10.1.3.100                    │  │
│   └─────────────┘          │                                │  │
│                            │  Private IP, no public access! │  │
│                            └────────────────────────────────┘  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘

Public Internet → Key Vault = NO ROUTE EXISTS!
```

---

## Using the Module

### Basic Example

```hcl
module "security" {
  source = "../../modules/security"

  resource_group_name = "myapp-security-rg-dev"
  location            = "eastus"
  key_vault_name      = "myapp-kv-dev-001"  # Must be globally unique!
  tenant_id           = var.tenant_id

  # Use RBAC (recommended)
  enable_rbac_authorization = true

  # Basic settings
  sku_name                   = "standard"
  purge_protection_enabled   = false  # OK for dev
  soft_delete_retention_days = 30

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

  # Store secrets
  secrets = {
    "db-connection-string" = {
      value        = "Server=tcp:mydb.database.windows.net;..."
      content_type = "connection-string"
    }
    "api-key" = {
      value        = var.external_api_key
      content_type = "api-key"
    }
  }

  tags = module.global_standards.common_tags
}
```

### With Network Restrictions (Production)

```hcl
module "security" {
  source = "../../modules/security"

  resource_group_name = "myapp-security-rg-prod"
  location            = "eastus"
  key_vault_name      = "myapp-kv-prod-001"
  tenant_id           = var.tenant_id

  # Network security
  network_acls_default_action = "Deny"  # Block by default
  virtual_network_subnet_ids  = [
    module.landing_zone.subnet_ids["aks-subnet"],
    module.landing_zone.subnet_ids["app-subnet"]
  ]

  # Private endpoint (most secure)
  create_private_endpoint    = true
  private_endpoint_subnet_id = module.landing_zone.subnet_ids["data-subnet"]
  vnet_id                    = module.landing_zone.vnet_id

  # Production settings
  purge_protection_enabled   = true  # Prevent accidental deletion
  soft_delete_retention_days = 90

  # Audit logging
  log_analytics_workspace_id = module.landing_zone.log_analytics_workspace_id

  tags = module.global_standards.common_tags
}
```

---

## How to Access Secrets in Your App

### Python

```python
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient

# No passwords needed - uses Managed Identity!
credential = DefaultAzureCredential()
vault_url = "https://myapp-kv-prod-001.vault.azure.net/"
client = SecretClient(vault_url=vault_url, credential=credential)

# Get a secret
db_password = client.get_secret("db-password").value
print(f"Connected with password: {db_password}")
```

### JavaScript/Node.js

```javascript
const { DefaultAzureCredential } = require("@azure/identity");
const { SecretClient } = require("@azure/keyvault-secrets");

// No passwords needed - uses Managed Identity!
const credential = new DefaultAzureCredential();
const vaultUrl = "https://myapp-kv-prod-001.vault.azure.net/";
const client = new SecretClient(vaultUrl, credential);

// Get a secret
const secret = await client.getSecret("db-password");
console.log(`Password: ${secret.value}`);
```

### C# / .NET

```csharp
using Azure.Identity;
using Azure.Security.KeyVault.Secrets;

// No passwords needed - uses Managed Identity!
var credential = new DefaultAzureCredential();
var vaultUri = new Uri("https://myapp-kv-prod-001.vault.azure.net/");
var client = new SecretClient(vaultUri, credential);

// Get a secret
KeyVaultSecret secret = await client.GetSecretAsync("db-password");
Console.WriteLine($"Password: {secret.Value}");
```

---

## Granting Access to Your App

After creating Key Vault, grant your app access:

```bash
# Get your app's managed identity principal ID
APP_PRINCIPAL_ID=$(az aks show -g myapp-rg-dev -n myapp-aks-dev \
  --query identityProfile.kubeletidentity.objectId -o tsv)

# Grant "Key Vault Secrets User" role
az role assignment create \
  --role "Key Vault Secrets User" \
  --assignee $APP_PRINCIPAL_ID \
  --scope /subscriptions/SUB_ID/resourceGroups/myapp-security-rg-dev/providers/Microsoft.KeyVault/vaults/myapp-kv-dev-001
```

Available roles:
| Role | What it can do |
|------|----------------|
| Key Vault Administrator | Everything |
| Key Vault Secrets Officer | Create, update, delete secrets |
| Key Vault Secrets User | Read secrets only |
| Key Vault Crypto Officer | Manage keys |
| Key Vault Crypto User | Use keys for encryption |

---

## Soft Delete and Purge Protection

### Soft Delete (Enabled by Default)

```
When you delete a secret:
─────────────────────────
Before: Secret exists → myapp-kv/secrets/db-password
Delete: Secret is "soft deleted" (recoverable!)
After 30-90 days: Permanently gone

Why? Protects against accidental deletion!

To recover:
  az keyvault secret recover --vault-name myapp-kv --name db-password
```

### Purge Protection (For Production)

```
With purge_protection_enabled = true:
─────────────────────────────────────
Even with "purge" permission, you CANNOT permanently delete
until the retention period expires.

Why? Protects against malicious deletion!
     Even if attacker gets admin access, they can't
     permanently destroy your secrets.
```

---

## Common Scenarios

### Scenario 1: App Needs Database Password

```
1. Store password in Key Vault:
   az keyvault secret set --vault-name myapp-kv \
     --name "db-password" --value "SuperSecret123"

2. Grant app access (via Terraform or CLI)

3. App reads at startup:
   password = client.get_secret("db-password").value
   connect_to_database(password)
```

### Scenario 2: Rotate a Secret

```
1. Update secret in Key Vault:
   az keyvault secret set --vault-name myapp-kv \
     --name "db-password" --value "NewPassword456"

2. Restart app (or wait for cache expiry)

3. App gets new value automatically!

No code changes. No redeployment. Just restart.
```

### Scenario 3: Multiple Environments

```
DEV Key Vault:  myapp-kv-dev-001
├── db-password = "dev-password"
└── api-key = "dev-api-key"

PROD Key Vault: myapp-kv-prod-001
├── db-password = "prod-super-secret"
└── api-key = "prod-api-key"

Same code works in both environments!
App reads from Key Vault based on environment config.
```

---

## Troubleshooting

### "Access denied" Error

```
Problem: App can't read secrets

Checklist:
□ Does app have Managed Identity enabled?
  → az aks show -g RG -n AKS --query identityProfile

□ Is the correct RBAC role assigned?
  → az role assignment list --assignee PRINCIPAL_ID

□ Is the Key Vault firewall blocking the app?
  → Check network_acls_default_action and allowed subnets

□ Is the app in the correct VNet?
  → Private endpoint requires VNet connectivity
```

### "Key Vault not found" Error

```
Problem: Can't connect to Key Vault

Checklist:
□ Is the vault name correct?
  → Key Vault names are globally unique

□ Is DNS resolving correctly?
  → For private endpoints, need Private DNS Zone

□ Is there network connectivity?
  → Check NSG rules allow outbound HTTPS
```

### "Soft delete conflict" Error

```
Problem: Can't create Key Vault with same name

Cause: Old Key Vault was deleted but still in "soft delete" state

Solutions:
1. Recover it:
   az keyvault recover --name myapp-kv

2. Or purge it (if not protected):
   az keyvault purge --name myapp-kv

3. Or use different name:
   key_vault_name = "myapp-kv-v2"
```

---

## Cost

Key Vault is very affordable:

| Item | Cost |
|------|------|
| Secrets operations | $0.03 per 10,000 operations |
| Keys (standard) | $0.03 per 10,000 operations |
| Keys (HSM-backed) | $1-5 per key per month |
| Certificates | $3 per renewal |

**Typical monthly cost:** $1-5 for most applications

---

## Summary

**Key Vault is:**
- A secure vault for passwords, keys, and certificates
- Encrypted at rest and in transit
- Access controlled via Azure AD (RBAC)
- Audited (who accessed what, when)

**Why use it:**
- No secrets in code
- Easy rotation
- Fine-grained access control
- Meets compliance requirements

**Best practices:**
- Use RBAC (not Access Policies)
- Use Managed Identity (no passwords!)
- Enable network restrictions in production
- Use Private Endpoint for maximum security
- Enable purge protection in production
- Send audit logs to Log Analytics

**Never do:**
- Store secrets in code
- Store secrets in environment variables
- Share one Key Vault across environments
- Give everyone admin access
