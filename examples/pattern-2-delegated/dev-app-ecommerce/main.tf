# E-Commerce Application - Terraform Configuration
# =============================================================================
# 🎓 NEWBIE NOTE: Pattern 2 teams use the SAME terraform version, provider
# version, and backend storage as the Platform layer (infra/platform/).
# Only the backend "key" is different (separate state file per app).
#
# What's SAME as Platform layer:
#   - Terraform version (>= 1.5.0)
#   - Provider version (~> 3.80)
#   - Backend storage account (stcontosotfstate001)
#   - Provider feature settings
#   - Global standards (naming, tagging) via module "global_standards"
#
# What's DIFFERENT from Platform layer:
#   - Backend key (dev-app-ecommerce.tfstate vs platform-dev.tfstate)
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
      version = "~> 3.80"
    }
  }

  # Remote state storage - SAME storage account as Platform team!
  #
  # 🎓 HOW STATE FILES ARE ORGANIZED:
  #    Storage Account: stcontosotfstate001
  #    Container: tfstate/
  #    ├── platform-dev.tfstate       ← Platform layer (infra/platform/dev/)
  #    ├── dev.terraform.tfstate      ← App layer Pattern 1 (infra/envs/dev/)
  #    ├── dev-app-crm.tfstate        ← CRM team (Pattern 2)
  #    └── dev-app-ecommerce.tfstate  ← E-commerce team (Pattern 2, THIS file)
  #
  # 🎓 WHO CREATES THIS STORAGE? Platform team runs scripts/init-backend.ps1 ONCE.
  # ⚠️  WHAT IF KEY IS WRONG? You'll create a NEW empty state (orphaned resources!)
  backend "azurerm" {
    resource_group_name  = "contoso-tfstate-rg"        # Created by: scripts/init-backend.ps1
    storage_account_name = "stcontosotfstate001"       # Created by: scripts/init-backend.ps1
    container_name       = "tfstate"                   # Created by: scripts/init-backend.ps1
    key                  = "dev-app-ecommerce.tfstate" # ← Unique per app team!
    use_azuread_auth     = true                        # Uses Azure AD (no storage access keys)
  }
}

# 🎓 SAME provider settings as Platform team — consistency matters!
# See infra/envs/dev/main.tf for detailed explanation of each setting.
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = true # Safety: can't delete RG with resources
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
# The Platform team already created it in infra/platform/dev/main.tf
# We just READ it using Terraform data sources below.
#
# Think of it like this:
# - Platform team: Builds the roads (VNet, subnets, security rules)
# - Your team: Builds the houses (AKS, CosmosDB, Key Vault)
# ============================================================================

# 🎓 WHAT IS THIS? Gets info about the current Azure login (tenant ID, object ID).
#    We need this for Key Vault access policies (to know WHO we are in Azure AD).
data "azurerm_client_config" "current" {}

# Read E-commerce's dedicated VNet (created by Platform layer)
#
# 🎓 TRACEABILITY — Follow the trail:
#    1. Platform team runs: infra/platform/dev/main.tf
#    2. Which creates: module "networking_ecommerce" { ... }
#    3. That module creates VNet: "vnet-contoso-dev-ecommerce-001"
#    4. We READ it here with data source (read-only, no modification!)
#
# ⚠️  PREREQUISITE: Platform team MUST deploy Platform layer FIRST!
#    Run: cd infra/platform/dev && terraform apply -var-file="dev.tfvars"
data "azurerm_virtual_network" "ecommerce" {
  name                = "vnet-contoso-dev-ecommerce-001" # Must match: module "networking_ecommerce" → network_name
  resource_group_name = "contoso-platform-rg-dev"        # Must match: resource "azurerm_resource_group" "main"
}

# Read E-commerce's AKS subnet (inside the VNet above)
# 🎓 TRACEABILITY: Created by Platform in module "networking_ecommerce" → subnets → "ecom-aks-subnet"
data "azurerm_subnet" "ecom_aks" {
  name                 = "ecom-aks-subnet"                           # Must match subnet name
  virtual_network_name = data.azurerm_virtual_network.ecommerce.name # From VNet data source above
  resource_group_name  = data.azurerm_virtual_network.ecommerce.resource_group_name
}

# ============================================================================
# GLOBAL STANDARDS - Inherit tagging from Platform (consistency!)
# ============================================================================
# 🎓 WHY? All teams use the SAME tagging via global_standards module.
#    No more hardcoded default_tags! Tags come from infra/global/
#    so if platform changes tagging policy, ALL teams inherit it.
# ============================================================================
module "global_standards" {
  source = "../../../infra/global"

  organization_name = var.company_name
  project_name      = "${var.company_name}-${var.workload}"
  environment       = var.environment
  location          = var.location
  cost_center       = var.cost_center
  owner_email       = var.owner_email
  repository_url    = var.repository_url
}

# ============================================================================
# NAMING MODULE - Consistent names across all resources
# ============================================================================
# 🎓 SOURCE: infra/modules/_shared/naming.tf — shared naming convention
# 🎓 WHY? So all teams name resources the SAME way.
# ============================================================================
module "naming" {
  source = "../../../infra/modules/_shared"

  project_name = "${var.company_name}-${var.workload}" # "contoso-ecommerce"
  environment  = var.environment                       # "dev"
  location     = var.location                          # "indonesiacentral"
}

# ============================================================================
# RESOURCE GROUP - E-commerce team's own resource group
# ============================================================================
# 🎓 Pattern 2 teams get their OWN resource group (separate from Platform's).
#    Platform:    "contoso-platform-rg-dev"
#    CRM team:    "rg-contoso-dev-crm-001"
#    E-commerce:  "rg-contoso-dev-ecommerce-001" (this one)
# ============================================================================
resource "azurerm_resource_group" "ecommerce" {
  name     = "rg-${var.company_name}-${var.environment}-${var.workload}-001"
  location = var.location

  tags = merge(module.global_standards.common_tags, {
    Application = "E-commerce API"
    Team        = "E-commerce Team"
  })
}

# ============================================================================
# AKS - Kubernetes cluster (shared OR dedicated)
# ============================================================================
# 🎓 E-COMMERCE has a CHOICE that CRM doesn't:
#    Option A (use_shared_aks = true):  Use Platform's shared AKS cluster
#        → Cheaper, shared with other teams, deploy to a namespace
#    Option B (use_shared_aks = false): Deploy dedicated AKS cluster
#        → More expensive, full control, isolated resources
#
# 🎓 WHY THIS FLEXIBILITY? Not all apps need their own cluster.
#    Small microservices → share a cluster (use Kubernetes namespaces)
#    Large/sensitive apps → dedicated cluster (full isolation)
# ============================================================================

# Option A: Reference existing AKS cluster (deployed by Platform team)
data "azurerm_kubernetes_cluster" "shared" {
  count = var.use_shared_aks ? 1 : 0 # Only read if using shared AKS

  name                = "aks-${var.company_name}-${var.environment}-001"
  resource_group_name = "rg-${var.company_name}-${var.environment}-aks-001"
}

# Option B: Deploy dedicated AKS (if team needs full control)
resource "azurerm_kubernetes_cluster" "dedicated" {
  count = var.use_shared_aks ? 0 : 1 # Only create if NOT using shared AKS

  name                = "aks-${var.company_name}-${var.environment}-${var.workload}-001"
  location            = azurerm_resource_group.ecommerce.location
  resource_group_name = azurerm_resource_group.ecommerce.name
  dns_prefix          = "aks-${var.company_name}-${var.environment}-${var.workload}"

  kubernetes_version = var.kubernetes_version

  default_node_pool {
    name                = "default"
    node_count          = var.aks_node_count
    vm_size             = var.aks_vm_size
    vnet_subnet_id      = data.azurerm_subnet.ecom_aks.id # ← Uses Platform's subnet!
    enable_auto_scaling = true
    min_count           = 1
    max_count           = 5
  }

  # 🎓 SystemAssigned identity: Azure creates + manages this identity automatically.
  #    Different from UserAssigned (which we create manually for the app above).
  identity {
    type = "SystemAssigned"
  }

  # 🎓 NETWORK PROFILE: How pods communicate inside Kubernetes.
  #    network_plugin = "azure" → Azure CNI (pods get real VNet IPs)
  #    network_policy = "azure" → Kubernetes network policies enforced
  #    service_cidr   = internal Kubernetes service IPs (don't overlap with VNet!)
  network_profile {
    network_plugin = "azure"
    network_policy = "azure"
    service_cidr   = "10.2.0.0/16" # Internal K8s services (NOT VNet IPs)
    dns_service_ip = "10.2.0.10"   # Must be inside service_cidr
  }

  tags = merge(module.global_standards.common_tags, {
    Application = "E-commerce API"
  })
}

# ============================================================================
# COSMOS DB - E-commerce's NoSQL database
# ============================================================================
# 🎓 HOW DATA IS ORGANIZED:
#    Account (cosmos-contoso-dev-ecommerce-001)
#    └── Database (ecommerce-db)
#        ├── Container: products   (partitioned by /categoryId)
#        ├── Container: orders     (partitioned by /userId)
#        └── Container: inventory  (partitioned by /warehouseId)
#
# 🎓 COST: ~$36/month minimum (400 RU × 3 containers)
# ============================================================================

resource "azurerm_cosmosdb_account" "ecommerce" {
  name                = "cosmos-${var.company_name}-${var.environment}-${var.workload}-001"
  location            = azurerm_resource_group.ecommerce.location
  resource_group_name = azurerm_resource_group.ecommerce.name
  offer_type          = "Standard"         # Only option available
  kind                = "GlobalDocumentDB" # SQL API

  # Session consistency — user sees their own writes immediately
  consistency_policy {
    consistency_level = var.cosmos_consistency_level
  }

  geo_location {
    location          = azurerm_resource_group.ecommerce.location # indonesiacentral
    failover_priority = 0                                         # Primary region
  }

  # Public access with IP rules (dev environment)
  public_network_access_enabled = true
  ip_range_filter               = var.cosmos_allowed_ips

  tags = merge(module.global_standards.common_tags, {
    Application = "E-commerce API"
  })
}

# SQL Database — logical grouping of containers
resource "azurerm_cosmosdb_sql_database" "ecommerce" {
  name                = "ecommerce-db"
  resource_group_name = azurerm_resource_group.ecommerce.name
  account_name        = azurerm_cosmosdb_account.ecommerce.name # ← Inside the account above
}

# Container 1: Products
# 🎓 PARTITION KEY: /categoryId — Products grouped by category for fast filtering
resource "azurerm_cosmosdb_sql_container" "products" {
  name                = "products"
  resource_group_name = azurerm_resource_group.ecommerce.name
  account_name        = azurerm_cosmosdb_account.ecommerce.name
  database_name       = azurerm_cosmosdb_sql_database.ecommerce.name
  partition_key_path  = "/categoryId"          # ← Query: "show all phones" is fast
  throughput          = var.cosmos_products_ru # 400 RU/s for dev
}

# Container 2: Orders
# 🎓 PARTITION KEY: /userId — All orders for same user stored together (fast "my orders" page)
resource "azurerm_cosmosdb_sql_container" "orders" {
  name                = "orders"
  resource_group_name = azurerm_resource_group.ecommerce.name
  account_name        = azurerm_cosmosdb_account.ecommerce.name
  database_name       = azurerm_cosmosdb_sql_database.ecommerce.name
  partition_key_path  = "/userId"            # ← Query: "show my orders" is fast
  throughput          = var.cosmos_orders_ru # 400 RU/s for dev
}

# Container 3: Inventory
# 🎓 PARTITION KEY: /warehouseId — Stock levels grouped by warehouse location
resource "azurerm_cosmosdb_sql_container" "inventory" {
  name                = "inventory"
  resource_group_name = azurerm_resource_group.ecommerce.name
  account_name        = azurerm_cosmosdb_account.ecommerce.name
  database_name       = azurerm_cosmosdb_sql_database.ecommerce.name
  partition_key_path  = "/warehouseId"          # ← Query: "stock in Jakarta warehouse" is fast
  throughput          = var.cosmos_inventory_ru # 400 RU/s for dev
}

# ============================================================================
# KEY VAULT - Secure storage for E-commerce's secrets
# ============================================================================
# 🎓 Same concept as CRM's Key Vault (see dev-app-crm/main.tf for detailed explanation).
#    Stores: Cosmos DB connection string, API keys, certificates.
# ============================================================================

resource "azurerm_key_vault" "ecommerce" {
  name                = "kv-${var.company_name}-${var.environment}-${var.workload}"
  location            = azurerm_resource_group.ecommerce.location
  resource_group_name = azurerm_resource_group.ecommerce.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  # Allow current user to manage secrets
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Purge"
    ]
  }

  tags = merge(module.global_standards.common_tags, {
    Application = "E-commerce API"
  })
}

# 🎓 AUTO-STORE: Cosmos DB connection string → Key Vault (no manual copy-paste!)
resource "azurerm_key_vault_secret" "cosmos_connection_string" {
  name         = "cosmos-connection-string"
  value        = azurerm_cosmosdb_account.ecommerce.primary_sql_connection_string # ← From Cosmos DB
  key_vault_id = azurerm_key_vault.ecommerce.id                                   # ← Into Key Vault
}

# ============================================================================
# MANAGED IDENTITY - The app's "robot account" in Azure
# ============================================================================
# 🎓 Same concept as CRM's Managed Identity.
#    See dev-app-crm/main.tf for detailed explanation of:
#    - What Managed Identity is
#    - User-Assigned vs System-Assigned
#    - How it connects to Key Vault and Cosmos DB
# ============================================================================

resource "azurerm_user_assigned_identity" "ecommerce" {
  name                = "id-${var.company_name}-${var.environment}-${var.workload}-001"
  location            = azurerm_resource_group.ecommerce.location
  resource_group_name = azurerm_resource_group.ecommerce.name

  tags = merge(module.global_standards.common_tags, {
    Application = "E-commerce API"
  })
}

# 🎓 GRANT #1: Managed Identity → Key Vault (read secrets only)
resource "azurerm_key_vault_access_policy" "app_identity" {
  key_vault_id = azurerm_key_vault.ecommerce.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.ecommerce.principal_id # ← WHO gets access

  secret_permissions = [
    "Get", "List" # Read only! Principle of least privilege.
  ]
}

# 🎓 GRANT #2: Managed Identity → Cosmos DB (read/write data)
# Uses built-in "Cosmos DB Built-in Data Contributor" role (GUID ...0002)
resource "azurerm_cosmosdb_sql_role_assignment" "app_identity" {
  resource_group_name = azurerm_resource_group.ecommerce.name
  account_name        = azurerm_cosmosdb_account.ecommerce.name
  role_definition_id  = "${azurerm_cosmosdb_account.ecommerce.id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002"
  principal_id        = azurerm_user_assigned_identity.ecommerce.principal_id # ← WHO gets the role
  scope               = azurerm_cosmosdb_account.ecommerce.id                 # ← ON which resource
}
