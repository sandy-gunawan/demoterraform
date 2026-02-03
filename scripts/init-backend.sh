#!/bin/bash
# Initialize Terraform Backend (Azure Storage Account)
# This script creates the required Azure resources for Terraform state storage

set -e

echo "=========================================="
echo "Terraform Backend Initialization"
echo "=========================================="
echo ""

# Configuration
RESOURCE_GROUP_NAME="terraform-state-rg"
STORAGE_ACCOUNT_NAME="tfstate$(whoami | tr -d '-')$(date +%s | tail -c 5)"
CONTAINER_NAME="tfstate"
LOCATION="eastus"

echo "Configuration:"
echo "  Resource Group: $RESOURCE_GROUP_NAME"
echo "  Storage Account: $STORAGE_ACCOUNT_NAME"
echo "  Container: $CONTAINER_NAME"
echo "  Location: $LOCATION"
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
  --output table

# Create storage account
echo "Creating storage account..."
az storage account create \
  --name $STORAGE_ACCOUNT_NAME \
  --resource-group $RESOURCE_GROUP_NAME \
  --location $LOCATION \
  --sku Standard_LRS \
  --encryption-services blob \
  --https-only true \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false \
  --output table

# Create container
echo "Creating blob container..."
az storage container create \
  --name $CONTAINER_NAME \
  --account-name $STORAGE_ACCOUNT_NAME \
  --auth-mode login \
  --output table

echo ""
echo "✓ Backend infrastructure created successfully!"
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
echo "     --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP_NAME/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT_NAME"
echo ""
