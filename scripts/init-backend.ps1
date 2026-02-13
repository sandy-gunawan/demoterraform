# Initialize Terraform Backend (Azure Storage Account)
# PowerShell version for Windows users
# Features: GRS replication, blob versioning, soft delete (90 days),
#           storage firewall, diagnostic logging, resource lock

$ErrorActionPreference = "Stop"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Terraform Backend Initialization" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Configuration - MUST match backend.tf in all environments!
# See: infra/envs/dev/backend.tf, examples/pattern-2-delegated/*/main.tf
$RESOURCE_GROUP_NAME = "contoso-tfstate-rg"
$STORAGE_ACCOUNT_NAME = "stcontosotfstate001"
$CONTAINER_NAME = "tfstate"
$LOCATION = "indonesiacentral"
$SOFT_DELETE_DAYS = 90

Write-Host "Configuration:"
Write-Host "  Resource Group: $RESOURCE_GROUP_NAME"
Write-Host "  Storage Account: $STORAGE_ACCOUNT_NAME"
Write-Host "  Container: $CONTAINER_NAME"
Write-Host "  Location: $LOCATION"
Write-Host "  Replication: Standard_GRS (geo-redundant)"
Write-Host "  Soft Delete: $SOFT_DELETE_DAYS days"
Write-Host ""

# Check if Azure CLI is installed
if (!(Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: Azure CLI is not installed. Please install it first." -ForegroundColor Red
    Write-Host "   https://docs.microsoft.com/en-us/cli/azure/install-azure-cli" -ForegroundColor Yellow
    exit 1
}

# Check if logged in
try {
    $null = az account show 2>$null
} catch {
    Write-Host "WARNING: Not logged in to Azure. Running 'az login'..." -ForegroundColor Yellow
    az login
}

# Get current subscription
$SUBSCRIPTION_NAME = az account show --query name -o tsv
$SUBSCRIPTION_ID = az account show --query id -o tsv

Write-Host "Current Subscription:"
Write-Host "  Name: $SUBSCRIPTION_NAME"
Write-Host "  ID: $SUBSCRIPTION_ID"
Write-Host ""

$response = Read-Host "Is this the correct subscription? (y/n)"
if ($response -ne "y") {
    Write-Host "Please set the correct subscription using: az account set --subscription <subscription-id>"
    exit 1
}

# Create resource group
Write-Host "Creating resource group..." -ForegroundColor Green
az group create `
  --name $RESOURCE_GROUP_NAME `
  --location $LOCATION `
  --tags Purpose=TerraformState ManagedBy=Script `
  --output table

# Create storage account with hardened settings
Write-Host "Creating storage account (Standard_GRS with hardened security)..." -ForegroundColor Green
az storage account create `
  --name $STORAGE_ACCOUNT_NAME `
  --resource-group $RESOURCE_GROUP_NAME `
  --location $LOCATION `
  --sku Standard_GRS `
  --kind StorageV2 `
  --encryption-services blob `
  --https-only true `
  --min-tls-version TLS1_2 `
  --allow-blob-public-access false `
  --allow-shared-key-access false `
  --default-action Deny `
  --output table

# Enable blob versioning
Write-Host "Enabling blob versioning..." -ForegroundColor Green
az storage account blob-service-properties update `
  --account-name $STORAGE_ACCOUNT_NAME `
  --resource-group $RESOURCE_GROUP_NAME `
  --enable-versioning true `
  --output table

# Enable blob soft delete
Write-Host "Enabling blob soft delete ($SOFT_DELETE_DAYS days)..." -ForegroundColor Green
az storage account blob-service-properties update `
  --account-name $STORAGE_ACCOUNT_NAME `
  --resource-group $RESOURCE_GROUP_NAME `
  --enable-delete-retention true `
  --delete-retention-days $SOFT_DELETE_DAYS `
  --output table

# Enable container soft delete
Write-Host "Enabling container soft delete ($SOFT_DELETE_DAYS days)..." -ForegroundColor Green
az storage account blob-service-properties update `
  --account-name $STORAGE_ACCOUNT_NAME `
  --resource-group $RESOURCE_GROUP_NAME `
  --enable-container-delete-retention true `
  --container-delete-retention-days $SOFT_DELETE_DAYS `
  --output table

# Allow current client IP through firewall for setup
Write-Host "Adding current IP to storage firewall..." -ForegroundColor Green
$CURRENT_IP = (Invoke-RestMethod -Uri "https://api.ipify.org")
az storage account network-rule add `
  --account-name $STORAGE_ACCOUNT_NAME `
  --resource-group $RESOURCE_GROUP_NAME `
  --ip-address $CURRENT_IP `
  --output table

# Allow trusted Azure services (needed for pipelines)
Write-Host "Allowing trusted Azure services..." -ForegroundColor Green
az storage account update `
  --name $STORAGE_ACCOUNT_NAME `
  --resource-group $RESOURCE_GROUP_NAME `
  --bypass AzureServices Logging Metrics `
  --output table

# Create container
Write-Host "Creating blob container..." -ForegroundColor Green
az storage container create `
  --name $CONTAINER_NAME `
  --account-name $STORAGE_ACCOUNT_NAME `
  --auth-mode login `
  --output table

# Create resource lock to prevent accidental deletion
Write-Host "Creating resource lock on storage account..." -ForegroundColor Green
az lock create `
  --name "CannotDelete-TFState" `
  --resource-group $RESOURCE_GROUP_NAME `
  --resource $STORAGE_ACCOUNT_NAME `
  --resource-type Microsoft.Storage/storageAccounts `
  --lock-type CanNotDelete `
  --notes "Protected: Terraform state storage" `
  --output table

# Get storage resource ID for outputs
$STORAGE_RESOURCE_ID = az storage account show `
  --name $STORAGE_ACCOUNT_NAME `
  --resource-group $RESOURCE_GROUP_NAME `
  --query id -o tsv

Write-Host ""
Write-Host "OK: Backend infrastructure created successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Security Summary" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  - Standard_GRS geo-redundant replication" -ForegroundColor Green
Write-Host "  - Blob versioning enabled" -ForegroundColor Green
Write-Host "  - Blob soft delete: $SOFT_DELETE_DAYS days" -ForegroundColor Green
Write-Host "  - Container soft delete: $SOFT_DELETE_DAYS days" -ForegroundColor Green
Write-Host "  - Storage firewall enabled (default deny)" -ForegroundColor Green
Write-Host "  - Shared key access disabled (Azure AD only)" -ForegroundColor Green
Write-Host "  - TLS 1.2 minimum enforced" -ForegroundColor Green
Write-Host "  - Public blob access disabled" -ForegroundColor Green
Write-Host "  - CanNotDelete resource lock applied" -ForegroundColor Green
Write-Host "  - Trusted Azure services allowed" -ForegroundColor Green
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Next Steps" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host '1. Update your backend.tf files with these values:' -ForegroundColor Yellow
Write-Host '   terraform {'
Write-Host '     backend azurerm {'
Write-Host ('       resource_group_name  = {0}' -f $RESOURCE_GROUP_NAME)
Write-Host ('       storage_account_name = {0}' -f $STORAGE_ACCOUNT_NAME)
Write-Host ('       container_name       = {0}' -f $CONTAINER_NAME)
Write-Host '       key                  = ENV_NAME.terraform.tfstate'
Write-Host '       use_oidc             = true'
Write-Host '     }'
Write-Host '   }'
Write-Host ''

Write-Host '2. Initialize Terraform in your environment directory:' -ForegroundColor Yellow
Write-Host '   cd infra\envs\dev'
Write-Host '   terraform init'
Write-Host ''

Write-Host '3. Grant your service principal access to the storage account:' -ForegroundColor Yellow
Write-Host ('   az role assignment create --role ''Storage Blob Data Contributor'' --assignee <SERVICE_PRINCIPAL_ID> --scope {0}' -f $STORAGE_RESOURCE_ID)
Write-Host ''

Write-Host '4. (Optional) Add VNet rules for pipeline agents:' -ForegroundColor Yellow
Write-Host ('   az storage account network-rule add --account-name {0} --resource-group {1} --subnet <AGENT_SUBNET_RESOURCE_ID>' -f $STORAGE_ACCOUNT_NAME, $RESOURCE_GROUP_NAME)
Write-Host ''

Write-Host '5. State file keys used in this framework:' -ForegroundColor Yellow
Write-Host '   Pattern 1 (Platform):   dev.terraform.tfstate'
Write-Host '   Pattern 2 (CRM):        dev-app-crm.tfstate'
Write-Host '   Pattern 2 (E-commerce): dev-app-ecommerce.tfstate'
Write-Host ''
