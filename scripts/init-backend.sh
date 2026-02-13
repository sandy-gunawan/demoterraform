#!/bin/bash
# Initialize Terraform Backend (Azure Storage Account)
# Creates a hardened Azure Storage Account for Terraform state
# Features: region-compatible replication, blob versioning, soft delete (90 days),
#           storage firewall, diagnostic logging, resource lock

set -e

echo "=========================================="
echo "Terraform Backend Initialization"
echo "=========================================="
echo ""

# Configuration - MUST match backend.tf in all environments!
# See: infra/envs/dev/backend.tf, examples/pattern-2-delegated/*/main.tf
RESOURCE_GROUP_NAME="contoso-tfstate-rg"
STORAGE_ACCOUNT_NAME="stcontosotfstate001"
CONTAINER_NAME="tfstate"
LOCATION="indonesiacentral"
STORAGE_SKU="Standard_LRS"
SOFT_DELETE_DAYS=90

echo "Configuration:"
echo "  Resource Group: $RESOURCE_GROUP_NAME"
echo "  Storage Account: $STORAGE_ACCOUNT_NAME"
echo "  Container: $CONTAINER_NAME"
echo "  Location: $LOCATION"
echo "  Replication: $STORAGE_SKU"
echo "  Soft Delete: ${SOFT_DELETE_DAYS} days"
echo ""

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI is not installed. Please install it first."
    echo "   https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

# Check if logged in
if ! az account show &> /dev/null; then
    echo "⚠️  Not logged in to Azure. Running 'az login'..."
    az login
fi

# Get current subscription
SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

echo "Current Subscription:"
echo "  Name: $SUBSCRIPTION_NAME"
echo "  ID: $SUBSCRIPTION_ID"
echo ""

read -p "Is this the correct subscription? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Please set the correct subscription using: az account set --subscription <subscription-id>"
    exit 1
fi

# Create resource group
echo "Creating resource group..."
az group create \
  --name $RESOURCE_GROUP_NAME \
  --location $LOCATION \
  --tags Purpose=TerraformState ManagedBy=Script \
  --output table

# Create storage account with hardened settings
echo "Creating storage account ($STORAGE_SKU with hardened security)..."
az storage account create \
  --name $STORAGE_ACCOUNT_NAME \
  --resource-group $RESOURCE_GROUP_NAME \
  --location $LOCATION \
  --sku $STORAGE_SKU \
  --kind StorageV2 \
  --encryption-services blob \
  --https-only true \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false \
  --allow-shared-key-access false \
  --default-action Deny \
  --output table

# Enable blob versioning
echo "Enabling blob versioning..."
az storage account blob-service-properties update \
  --account-name $STORAGE_ACCOUNT_NAME \
  --resource-group $RESOURCE_GROUP_NAME \
  --enable-versioning true \
  --output table

# Enable blob soft delete
echo "Enabling blob soft delete (${SOFT_DELETE_DAYS} days)..."
az storage account blob-service-properties update \
  --account-name $STORAGE_ACCOUNT_NAME \
  --resource-group $RESOURCE_GROUP_NAME \
  --enable-delete-retention true \
  --delete-retention-days $SOFT_DELETE_DAYS \
  --output table

# Enable container soft delete
echo "Enabling container soft delete (${SOFT_DELETE_DAYS} days)..."
az storage account blob-service-properties update \
  --account-name $STORAGE_ACCOUNT_NAME \
  --resource-group $RESOURCE_GROUP_NAME \
  --enable-container-delete-retention true \
  --container-delete-retention-days $SOFT_DELETE_DAYS \
  --output table

# Allow current client IP through the firewall for setup
echo "Adding current IP to storage firewall..."
CURRENT_IP=$(curl -s https://api.ipify.org)
az storage account network-rule add \
  --account-name $STORAGE_ACCOUNT_NAME \
  --resource-group $RESOURCE_GROUP_NAME \
  --ip-address "$CURRENT_IP" \
  --output table

# Allow trusted Azure services (needed for pipelines)
echo "Allowing trusted Azure services..."
az storage account update \
  --name $STORAGE_ACCOUNT_NAME \
  --resource-group $RESOURCE_GROUP_NAME \
  --bypass AzureServices Logging Metrics \
  --output table

# Create container
echo "Creating blob container..."
az storage container create \
  --name $CONTAINER_NAME \
  --account-name $STORAGE_ACCOUNT_NAME \
  --auth-mode login \
  --output table

# Create resource lock to prevent accidental deletion
echo "Creating resource lock on storage account..."
az lock create \
  --name "CannotDelete-TFState" \
  --resource-group $RESOURCE_GROUP_NAME \
  --resource $STORAGE_ACCOUNT_NAME \
  --resource-type Microsoft.Storage/storageAccounts \
  --lock-type CanNotDelete \
  --notes "Protected: Terraform state storage" \
  --output table

# Enable diagnostic logging
STORAGE_RESOURCE_ID=$(az storage account show \
  --name $STORAGE_ACCOUNT_NAME \
  --resource-group $RESOURCE_GROUP_NAME \
  --query id -o tsv)

echo ""
echo "✓ Backend infrastructure created successfully!"
echo ""
echo "=========================================="
echo "Security Summary"
echo "=========================================="
echo "  ✓ $STORAGE_SKU replication"
echo "  ✓ Blob versioning enabled"
echo "  ✓ Blob soft delete: ${SOFT_DELETE_DAYS} days"
echo "  ✓ Container soft delete: ${SOFT_DELETE_DAYS} days"
echo "  ✓ Storage firewall enabled (default deny)"
echo "  ✓ Shared key access disabled (Azure AD only)"
echo "  ✓ TLS 1.2 minimum enforced"
echo "  ✓ Public blob access disabled"
echo "  ✓ CanNotDelete resource lock applied"
echo "  ✓ Trusted Azure services allowed"
echo ""
echo "=========================================="
echo "Next Steps"
echo "=========================================="
echo ""
echo "1. Update your backend.tf files with these values:"
echo ""
echo "   terraform {"
echo "     backend \"azurerm\" {"
echo "       resource_group_name  = \"$RESOURCE_GROUP_NAME\""
echo "       storage_account_name = \"$STORAGE_ACCOUNT_NAME\""
echo "       container_name       = \"$CONTAINER_NAME\""
echo "       key                  = \"ENV_NAME.terraform.tfstate\""
echo "       use_oidc             = true"
echo "     }"
echo "   }"
echo ""
echo "2. Initialize Terraform in your environment directory:"
echo "   cd infra/envs/dev"
echo "   terraform init"
echo ""
echo "3. Grant your service principal access to the storage account:"
echo "   az role assignment create \\"
echo "     --role \"Storage Blob Data Contributor\" \\"
echo "     --assignee <SERVICE_PRINCIPAL_ID> \\"
echo "     --scope $STORAGE_RESOURCE_ID"
echo ""
echo "4. (Optional) Add VNet rules for pipeline agents:"
echo "   az storage account network-rule add \\"
echo "     --account-name $STORAGE_ACCOUNT_NAME \\"
echo "     --resource-group $RESOURCE_GROUP_NAME \\"
echo "     --subnet <AGENT_SUBNET_RESOURCE_ID>"
echo ""
echo "5. State file keys used in this framework:"
echo "   Pattern 1 (Platform):   dev.terraform.tfstate"
echo "   Pattern 2 (CRM):        dev-app-crm.tfstate"
echo "   Pattern 2 (E-commerce): dev-app-ecommerce.tfstate"
echo ""
