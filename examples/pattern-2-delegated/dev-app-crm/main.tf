# CRM Application - Terraform Configuration
# =============================================================================
# 🎓 NEWBIE NOTE: Pattern 2 teams use the SAME terraform version, provider
# version, and backend storage as Platform team (Pattern 1).
# Only the backend "key" is different (separate state file per app).
#
# What's SAME as Pattern 1:
#   - Terraform version (>= 1.5.0)
#   - Provider version (~> 3.80)
#   - Backend storage account (stcontosotfstate001)
#   - Provider feature settings
#
# What's DIFFERENT from Pattern 1:
#   - Backend key (dev-app-crm.tfstate vs dev.terraform.tfstate)
#   - No VNet creation (reads Platform's VNet via data sources)
#   - Own resource group, own apps
# =============================================================================

terraform {
  # 🎓 WHY ">= 1.5.0"? SAME version constraint as Platform team (infra/envs/dev/main.tf).
  # All teams must use the same Terraform version to avoid state file incompatibilities.
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      # 🎓 WHY "~> 3.80"? Means >= 3.80 but < 4.0. SAME as Platform team.
      # Using the same provider version prevents "works on my machine" issues.
      version = "~> 3.80"
    }
  }

  # Remote state storage - SAME storage account as Platform team!
  #
  # 🎓 HOW STATE FILES ARE ORGANIZED:
  #    Storage Account: stcontosotfstate001
  #    Container: tfstate/
  #    ├── dev.terraform.tfstate      ← Platform team (Pattern 1, infra/envs/dev/)
  #    ├── dev-app-crm.tfstate        ← CRM team (Pattern 2, THIS file)
  #    └── dev-app-ecommerce.tfstate  ← E-commerce team (Pattern 2)
  #
  # 🎓 WHO CREATES THIS STORAGE? Platform team runs scripts/init-backend.ps1 ONCE.
  # ⚠️  WHAT IF KEY IS WRONG? You'll create a NEW empty state (orphaned resources!)
  backend "azurerm" {
    resource_group_name  = "contoso-tfstate-rg"  # Created by: scripts/init-backend.ps1
    storage_account_name = "stcontosotfstate001" # Created by: scripts/init-backend.ps1
    container_name       = "tfstate"             # Created by: scripts/init-backend.ps1
    key                  = "dev-app-crm.tfstate" # ← Unique per app team!
    use_azuread_auth     = true                  # Uses Azure AD (no storage access keys needed)
  }
}

# 🎓 SAME provider settings as Platform team — consistency matters!
# See infra/envs/dev/main.tf for detailed explanation of each setting.
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = true # Safety: can't delete RG with resources inside
    }
    key_vault {
      purge_soft_delete_on_destroy    = false # Safety: don't permanently delete Key Vault
      recover_soft_deleted_key_vaults = true  # Auto-recover if someone manually deleted
    }
  }
}

# ============================================================================
# DATA SOURCES - Read Platform team's infrastructure
# ============================================================================
# 🎓 NEWBIE NOTE: We DON'T create the VNet here!
# The Platform team already created it in infra/envs/dev/main.tf (line 115)
# We just READ it using Terraform data sources below.
#
# Think of it like this:
# - Platform team: Builds the roads (VNet, subnets, security rules)
# - Your team: Builds the houses (App Service, CosmosDB, Key Vault)
# ============================================================================

# 🎓 WHAT IS THIS? Gets info about the current Azure login (tenant ID, object ID).
#    We need this for Key Vault access policies (to know WHO we are in Azure AD).
data "azurerm_client_config" "current" {}

# Read CRM's dedicated VNet (created by Platform team in Pattern 1)
#
# 🎓 TRACEABILITY — Follow the trail:
#    1. Platform team runs: infra/envs/dev/main.tf
#    2. Which creates: module "networking_crm" { ... }
#    3. That module creates VNet: "vnet-contoso-dev-crm-001" in "contoso-platform-rg-dev"
#    4. We READ it here with data source (read-only, no modification!)
#
# 🎓 WHY DATA SOURCE instead of creating our own VNet?
#    Platform team controls networking (IP ranges, security rules, naming).
#    We just use what they built. Separation of concerns!
#
# ⚠️  PREREQUISITE: Platform team MUST deploy Pattern 1 FIRST!
#    Run: cd infra/envs/dev && terraform apply -var-file="dev.tfvars"
#    If VNet doesn't exist, this will FAIL with "resource not found" error.
data "azurerm_virtual_network" "crm" {
  name                = "vnet-contoso-dev-crm-001" # Must match: module "networking_crm" → network_name
  resource_group_name = "contoso-platform-rg-dev"  # Must match: resource "azurerm_resource_group" "main"
}

# Read CRM's app subnet (inside the VNet above)
# 🎓 TRACEABILITY: Created by Platform in module "networking_crm" → subnets → "crm-app-subnet"
data "azurerm_subnet" "crm_app" {
  name                 = "crm-app-subnet"                      # Must match subnet name in Platform's config
  virtual_network_name = data.azurerm_virtual_network.crm.name # From the VNet data source above
  resource_group_name  = data.azurerm_virtual_network.crm.resource_group_name
}

# ============================================================================
# NAMING MODULE - Consistent names across all resources
# ============================================================================
# 🎓 WHAT IS THIS? Generates standardized names like:
#    "contoso-crm-dev-rg-idc" (resource group), "contoso-crm-dev-kv-idc" (key vault)
#
# 🎓 SOURCE: infra/modules/_shared/naming.tf — shared naming convention
# 🎓 WHY? So all teams name resources the SAME way. You can look at any
#    resource name and immediately know: {company}-{app}-{env}-{type}-{region}
# ============================================================================
module "naming" {
  source = "../../../infra/modules/_shared"

  project_name = "${var.company_name}-${var.workload}" # "contoso-crm"
  environment  = var.environment                       # "dev"
  location     = var.location                          # "indonesiacentral"
}

# ============================================================================
# RESOURCE GROUP - CRM team's own resource group
# ============================================================================
# 🎓 WHY OWN RESOURCE GROUP?
#    Pattern 2 teams get their OWN resource group (separate from Platform's).
#    CRM team can manage their resources without affecting others.
#    Platform team has: "contoso-platform-rg-dev"
#    CRM team has:      "rg-contoso-dev-crm-001" (this one)
#    E-commerce has:    "rg-contoso-dev-ecommerce-001"
#
# 🎓 NAMING: rg-{company}-{env}-{workload}-{number}
# ============================================================================
resource "azurerm_resource_group" "crm" {
  name     = "rg-${var.company_name}-${var.environment}-${var.workload}-001"
  location = var.location

  tags = merge(var.default_tags, {
    Application = "CRM System"
    Team        = "CRM Team"
  })
}

# ============================================================================
# APP SERVICE - Web hosting for the CRM application
# ============================================================================
# 🎓 HOW APP SERVICE WORKS (2 resources needed):
#    1. Service Plan (below) = the "server" (CPU, RAM) — like renting a computer
#    2. Web App (next) = your application running ON that server
#    Multiple web apps can share one plan (saves cost in dev).
# ============================================================================

# App Service Plan = the compute resources (CPU + RAM)
# 🎓 NAMING: asp-{company}-{env}-{workload}-{number}
resource "azurerm_service_plan" "crm" {
  name                = "asp-${var.company_name}-${var.environment}-${var.workload}-001"
  location            = azurerm_resource_group.crm.location
  resource_group_name = azurerm_resource_group.crm.name
  os_type             = "Linux"             # Linux is cheaper than Windows for the same SKU
  sku_name            = var.app_service_sku # B1 for dev (~$13/month), P1V2 for prod

  tags = merge(var.default_tags, {
    Application = "CRM System"
  })
}

# Web App = your actual application running on the plan above
# 🎓 NAMING: app-{company}-{env}-{workload}-{number} (must be globally unique!)
resource "azurerm_linux_web_app" "crm" {
  name                = "app-${var.company_name}-${var.environment}-${var.workload}-001"
  location            = azurerm_resource_group.crm.location
  resource_group_name = azurerm_resource_group.crm.name
  service_plan_id     = azurerm_service_plan.crm.id # ← Runs on the plan above

  site_config {
    always_on = true # Keeps app warm (prevents cold start delays)

    application_stack {
      node_version = "18-lts" # CRM app runs on Node.js 18 LTS
    }
  }

  # 🎓 MANAGED IDENTITY: Like a "robot account" for the app.
  # Instead of storing passwords, the app authenticates using this identity.
  # This identity has been granted access to Key Vault and Cosmos DB (see bottom of file).
  identity {
    type = "UserAssigned" # We control the identity (vs SystemAssigned = Azure controls)
    identity_ids = [
      azurerm_user_assigned_identity.crm.id # ← Created at the bottom of this file
    ]
  }

  # 🎓 APP SETTINGS: Environment variables injected into the app at runtime.
  # Your Node.js code reads these with: process.env.COSMOS_ENDPOINT
  app_settings = {
    "COSMOS_ENDPOINT" = azurerm_cosmosdb_account.crm.endpoint        # ← Auto-wired from Cosmos DB below
    "COSMOS_DATABASE" = azurerm_cosmosdb_sql_database.crm.name       # ← Database name from below
    "KEY_VAULT_NAME"  = azurerm_key_vault.crm.name                   # ← Key Vault name from below
    "AZURE_CLIENT_ID" = azurerm_user_assigned_identity.crm.client_id # ← For Azure SDK authentication
    "WEBSITES_PORT"   = "3000"                                       # ← The port your Node.js app listens on
  }

  tags = merge(var.default_tags, {
    Application = "CRM System"
  })
}

# ============================================================================
# COSMOS DB - CRM's NoSQL database
# ============================================================================
# 🎓 WHY COSMOS DB FOR CRM?
#    CRM data (customers, interactions) is semi-structured and needs:
#    - Low latency reads (customers expect instant page loads)
#    - Flexible schema (different customer types have different fields)
#    - Global distribution capability (future: serve worldwide)
#
# 🎓 HOW DATA IS ORGANIZED:
#    Account (cosmos-contoso-dev-crm-001)
#    └── Database (crm-db)
#        ├── Container: customers   (partitioned by /companyId)
#        └── Container: interactions (partitioned by /customerId)
#
# 🎓 COST: ~$24/month minimum (400 RU × 2 containers)
# ============================================================================

resource "azurerm_cosmosdb_account" "crm" {
  name                = "cosmos-${var.company_name}-${var.environment}-${var.workload}-001"
  location            = azurerm_resource_group.crm.location
  resource_group_name = azurerm_resource_group.crm.name
  offer_type          = "Standard"         # Only option available
  kind                = "GlobalDocumentDB" # SQL API (most common, use SQL-like queries)

  # 🎓 CONSISTENCY LEVEL: How quickly data changes are visible to readers.
  #    Session = reader sees their own writes immediately
  #    Best for CRM — user updates a customer record & reads it back instantly.
  #    See: https://learn.microsoft.com/en-us/azure/cosmos-db/consistency-levels
  consistency_policy {
    consistency_level = var.cosmos_consistency_level # Default: "Session"
  }

  # 🎓 GEO LOCATION: Where data is physically stored.
  #    failover_priority = 0 means this is the PRIMARY (write) region.
  #    Add more geo_location blocks for read replicas in other regions.
  geo_location {
    location          = azurerm_resource_group.crm.location # indonesiacentral
    failover_priority = 0
  }

  # Dev: public access for easy development and debugging
  # Prod: should use private endpoints (see infra/envs/prod/main.tf)
  public_network_access_enabled = true
  ip_range_filter               = var.cosmos_allowed_ips # Empty = Azure services only

  tags = merge(var.default_tags, {
    Application = "CRM System"
  })
}

# SQL Database — logical grouping of containers (like a "schema" in relational DB)
resource "azurerm_cosmosdb_sql_database" "crm" {
  name                = "crm-db"
  resource_group_name = azurerm_resource_group.crm.name
  account_name        = azurerm_cosmosdb_account.crm.name # ← Inside the account above
}

# Container 1: Customers
# 🎓 PARTITION KEY: /companyId — Cosmos DB splits data by this field for performance.
#    All customers from the SAME company stored together (fast queries within a company).
#    Choose a field with high cardinality (many unique values) = better performance.
resource "azurerm_cosmosdb_sql_container" "customers" {
  name                = "customers"
  resource_group_name = azurerm_resource_group.crm.name
  account_name        = azurerm_cosmosdb_account.crm.name
  database_name       = azurerm_cosmosdb_sql_database.crm.name
  partition_key_path  = "/companyId"            # ← Data split by company
  throughput          = var.cosmos_customers_ru # 400 RU/s for dev (~$24/month)
}

# Container 2: Interactions (calls, emails, meetings with customers)
# 🎓 PARTITION KEY: /customerId — All interactions for the same customer stored together.
resource "azurerm_cosmosdb_sql_container" "interactions" {
  name                = "interactions"
  resource_group_name = azurerm_resource_group.crm.name
  account_name        = azurerm_cosmosdb_account.crm.name
  database_name       = azurerm_cosmosdb_sql_database.crm.name
  partition_key_path  = "/customerId"              # ← Data split by customer
  throughput          = var.cosmos_interactions_ru # 400 RU/s for dev (~$24/month)
}

# ============================================================================
# KEY VAULT - Secure storage for CRM's secrets
# ============================================================================
# 🎓 WHY KEY VAULT? Never store secrets (passwords, connection strings) in:
#    ❌ Source code (anyone with repo access can see them)
#    ❌ Environment variables on your laptop (not shared, not secure)
#    ✅ Key Vault (encrypted, access-controlled, audited)
#
# 🎓 HOW THE CRM APP ACCESSES SECRETS:
#    1. App has a Managed Identity (created below)
#    2. Identity gets "Get" + "List" permissions on Key Vault
#    3. App code uses Azure SDK: client = SecretClient(vault_url, credential)
#    4. No passwords stored anywhere!
# ============================================================================

resource "azurerm_key_vault" "crm" {
  name                = "kv-${var.company_name}-${var.environment}-${var.workload}"
  location            = azurerm_resource_group.crm.location
  resource_group_name = azurerm_resource_group.crm.name
  tenant_id           = data.azurerm_client_config.current.tenant_id # ← Your Azure AD tenant
  sku_name            = "standard"                                   # Standard is fine (Premium adds HSM hardware support)

  # 🎓 ACCESS POLICY: WHO can do WHAT with secrets.
  # This policy is for the person running terraform (YOU) — full control.
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id # ← Your Azure AD user/service principal

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Purge" # Full permissions for terraform operator
    ]
  }

  tags = merge(var.default_tags, {
    Application = "CRM System"
  })
}

# 🎓 AUTO-STORE SECRETS: Terraform automatically puts Cosmos DB connection string
# into Key Vault. Your app reads it from Key Vault (never handles raw connections).
resource "azurerm_key_vault_secret" "cosmos_connection_string" {
  name         = "cosmos-connection-string"
  value        = azurerm_cosmosdb_account.crm.primary_sql_connection_string # ← From Cosmos DB above
  key_vault_id = azurerm_key_vault.crm.id                                   # ← Into this Key Vault
}

# ============================================================================
# MANAGED IDENTITY - The app's "robot account" in Azure
# ============================================================================
# 🎓 WHAT IS MANAGED IDENTITY?
#    Instead of the app storing a username/password, Azure gives it an identity.
#    Like an employee badge — the app "shows" this identity to access resources.
#
# 🎓 USER-ASSIGNED vs SYSTEM-ASSIGNED:
#    System-Assigned: Tied to ONE resource, deleted when resource is deleted
#    User-Assigned:   Independent, can be shared, survives resource recreation
#    WHY User-Assigned? We can create it BEFORE the app, and it survives
#    if we recreate the App Service (e.g., change SKU or swap plans).
#
# 🎓 CONNECTION DIAGRAM:
#    App Service ──uses──→ Managed Identity ──reads──→ Key Vault (secrets)
#                                          ──reads/writes──→ Cosmos DB (data)
# ============================================================================

resource "azurerm_user_assigned_identity" "crm" {
  name                = "id-${var.company_name}-${var.environment}-${var.workload}-001"
  location            = azurerm_resource_group.crm.location
  resource_group_name = azurerm_resource_group.crm.name

  tags = merge(var.default_tags, {
    Application = "CRM System"
  })
}

# 🎓 GRANT #1: Managed Identity → Key Vault (read secrets only)
# The app can Get and List secrets, but NOT Set or Delete (principle of least privilege).
resource "azurerm_key_vault_access_policy" "app_identity" {
  key_vault_id = azurerm_key_vault.crm.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.crm.principal_id # ← The identity we just created

  secret_permissions = [
    "Get", "List" # Read only! App doesn't need to create/delete secrets.
  ]
}

# 🎓 GRANT #2: Managed Identity → Cosmos DB (read/write data)
# Uses Cosmos DB's built-in RBAC role: "Cosmos DB Built-in Data Contributor"
resource "azurerm_cosmosdb_sql_role_assignment" "app_identity" {
  resource_group_name = azurerm_resource_group.crm.name
  account_name        = azurerm_cosmosdb_account.crm.name
  # 🎓 WHAT IS THIS GUID? It's the built-in "Cosmos DB Built-in Data Contributor" role.
  #    00000000-...-000000000002 = read + write data (NOT manage account settings)
  #    00000000-...-000000000001 = read only (use for reporting apps)
  #    These are standard Azure-defined GUIDs, not something you make up.
  role_definition_id = "${azurerm_cosmosdb_account.crm.id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002"
  principal_id       = azurerm_user_assigned_identity.crm.principal_id # ← WHO gets the role
  scope              = azurerm_cosmosdb_account.crm.id                 # ← ON which resource
}
