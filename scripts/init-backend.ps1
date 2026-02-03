# Initialize Terraform Backend (Azure Storage Account)
# PowerShell version for Windows users

$ErrorActionPreference = "Stop"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Terraform Backend Initialization" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$RESOURCE_GROUP_NAME = "terraform-state-rg"
$STORAGE_ACCOUNT_NAME = "tfstate$($env:USERNAME)$(Get-Random -Maximum 9999)"
$CONTAINER_NAME = "tfstate"
$LOCATION = "eastus"

Write-Host "Configuration:"
Write-Host "  Resource Group: $RESOURCE_GROUP_NAME"
Write-Host "  Storage Account: $STORAGE_ACCOUNT_NAME"
Write-Host "  Container: $CONTAINER_NAME"
Write-Host "  Location: $LOCATION"
Write-Host ""

# Check if Azure CLI is installed
if (!(Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Azure CLI is not installed. Please install it first." -ForegroundColor Red
    Write-Host "   https://docs.microsoft.com/en-us/cli/azure/install-azure-cli" -ForegroundColor Yellow
    exit 1
}

# Check if logged in
try {
    $null = az account show 2>$null
} catch {
    Write-Host "⚠️  Not logged in to Azure. Running 'az login'..." -ForegroundColor Yellow
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
  --output table

# Create storage account
Write-Host "Creating storage account..." -ForegroundColor Green
az storage account create `
  --name $STORAGE_ACCOUNT_NAME `
  --resource-group $RESOURCE_GROUP_NAME `
  --location $LOCATION `
  --sku Standard_LRS `
  --encryption-services blob `
  --https-only true `
  --min-tls-version TLS1_2 `
  --allow-blob-public-access false `
  --output table

# Create container
Write-Host "Creating blob container..." -ForegroundColor Green
az storage container create `
  --name $CONTAINER_NAME `
  --account-name $STORAGE_ACCOUNT_NAME `
  --auth-mode login `
  --output table

Write-Host ""
Write-Host "✓ Backend infrastructure created successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Next Steps" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Update your backend.tf files with these values:" -ForegroundColor Yellow
Write-Host ""
Write-Host "   terraform {"
Write-Host "     backend `"azurerm`" {"
Write-Host "       resource_group_name  = `"$RESOURCE_GROUP_NAME`""
Write-Host "       storage_account_name = `"$STORAGE_ACCOUNT_NAME`""
Write-Host "       container_name       = `"$CONTAINER_NAME`""
Write-Host "       key                  = `"ENV_NAME.terraform.tfstate`""
Write-Host "     }"
Write-Host "   }"
Write-Host ""
Write-Host "2. Initialize Terraform in your environment directory:" -ForegroundColor Yellow
Write-Host "   cd infra\envs\dev"
Write-Host "   terraform init"
Write-Host ""
Write-Host "3. Grant your service principal access to the storage account:" -ForegroundColor Yellow
Write-Host "   az role assignment create \"
Write-Host "     --role `"Storage Blob Data Contributor`" \"
Write-Host "     --assignee <SERVICE_PRINCIPAL_ID> \"
Write-Host "     --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP_NAME/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT_NAME"
Write-Host ""
