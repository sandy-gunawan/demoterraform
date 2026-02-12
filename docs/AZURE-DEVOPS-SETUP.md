# Azure DevOps Pipeline Setup - Complete Guide for Beginners

## 📚 Table of Contents
1. [Prerequisites](#prerequisites)
2. [Phase 0: Azure DevOps Organization Setup](#phase-0-azure-devops-organization-setup)
3. [Phase 1: Create Repository](#phase-1-create-repository)
4. [Phase 2: Azure Subscription Setup](#phase-2-azure-subscription-setup)
5. [Phase 3: Service Connection Setup (OIDC)](#phase-3-service-connection-setup-oidc)
6. [Phase 4: Environment Setup](#phase-4-environment-setup)
7. [Phase 5: Pipeline Creation](#phase-5-pipeline-creation)
8. [Phase 6: First Deployment](#phase-6-first-deployment)
9. [Troubleshooting](#troubleshooting)

---

## Prerequisites

Before starting, ensure you have:
- ✅ Azure account with active subscription
- ✅ Azure DevOps organization (or ability to create one)
- ✅ Owner or Contributor role on Azure subscription
- ✅ Permissions to create Azure AD applications
- ✅ Git installed on your computer
- ✅ VS Code or another code editor

---

## Phase 0: Azure DevOps Organization Setup

### Step 1: Create Azure DevOps Organization (If You Don't Have One)

1. **Navigate to Azure DevOps**
   - Go to https://dev.azure.com
   - Sign in with your Microsoft account

2. **Create a New Organization**
   - Click **"New organization"**
   - Choose a unique name (e.g., `contoso-devops`)
   - Select your region (choose closest to your location)
   - Click **"Continue"**

   ![Azure DevOps Organization](https://docs.microsoft.com/en-us/azure/devops/media/index/create-organization.png)

3. **Create a Project**
   - Organization name: `terraform-infrastructure`
   - Description: `Infrastructure as Code using Terraform`
   - Visibility: **Private** (recommended for production)
   - Click **"Create project"**

   ![Create Project](https://docs.microsoft.com/en-us/azure/devops/media/create-project.png)

**✓ Checkpoint**: You now have an Azure DevOps organization and project.

---

## Phase 1: Create Repository

### Step 1: Initialize Git Repository

1. **In Azure DevOps, navigate to Repos**
   - Click **Repos** in the left sidebar
   - Click **"Files"**
   - You'll see instructions to clone or push code

2. **Clone the Repository to Your Computer**
   
   Open a terminal/command prompt and run:
   ```bash
   # Copy the clone URL from Azure DevOps
   git clone https://dev.azure.com/your-org/terraform-infrastructure/_git/terraform-infrastructure
   
   cd terraform-infrastructure
   ```

3. **Copy Framework Files**
   - Copy all files from this framework to your cloned repository
   - Your structure should look like:
   ```
   terraform-infrastructure/
   ├── infra/
   │   ├── global/
   │   ├── envs/
   │   └── modules/
   ├── pipelines/
   ├── docs/
   └── scripts/
   ```

4. **Commit and Push**
   ```bash
   git add .
   git commit -m "Initial commit: Add Terraform framework"
   git push origin main
   ```

**✓ Checkpoint**: Your code is now in Azure DevOps Repos.

---

## Phase 2: Azure Subscription Setup

### Step 1: Find Your Azure Subscription Information

1. **Open Azure Portal**
   - Go to https://portal.azure.com
   - Sign in

2. **Get Subscription ID and Tenant ID**
   - Search for **"Subscriptions"** in the top search bar
   - Click on your subscription
   - **Copy these values** (you'll need them later):
     - **Subscription ID**: `12345678-1234-1234-1234-123456789012`
     - **Tenant ID**: Click **"Overview"** → Copy Tenant ID

   ![Subscription Details](https://docs.microsoft.com/en-us/azure/media/subscription-details.png)

3. **Create Resource Group for Terraform State**
   
   This stores your Terraform state file securely in Azure.
   
   ```bash
   # Login to Azure CLI
   az login
   
   # Set your subscription
   az account set --subscription "YOUR_SUBSCRIPTION_ID"
   
   # Create resource group for Terraform state
   az group create \
     --name contoso-tfstate-rg \
     --location southeastasia
   
   # Create storage account (name must be globally unique)
   az storage account create \
     --name stcontosotfstate001 \
     --resource-group contoso-tfstate-rg \
     --location southeastasia \
     --sku Standard_LRS \
     --encryption-services blob
   
   # Create container for state files
   az storage container create \
     --name tfstate \
     --account-name stcontosotfstate001
   ```

**✓ Checkpoint**: You have a storage account ready for Terraform state.

---

## Phase 3: Service Connection Setup (OIDC)

This is the **most critical step** for security. We'll use **Workload Identity Federation (OIDC)** instead of storing secrets.

### Step 1: Create Azure AD App Registration

1. **In Azure Portal, navigate to Azure Active Directory**
   - Search for **"Azure Active Directory"**
   - Click **"App registrations"** in the left menu
   - Click **"+ New registration"**

2. **Register the Application**
   - Name: `terraform-oidc-sp`
   - Supported account types: **Accounts in this organizational directory only**
   - Redirect URI: Leave blank
   - Click **"Register"**

   ![App Registration](https://docs.microsoft.com/en-us/azure/media/app-registration.png)

3. **Note the Application Details**
   - Copy the **Application (client) ID**
   - Copy the **Directory (tenant) ID**

### Step 2: Configure Federated Credentials

1. **In the App Registration, click "Certificates & secrets"**
   - Click **"Federated credentials"** tab
   - Click **"+ Add credential"**

2. **Select Scenario**
   - Federated credential scenario: **Other issuer**

3. **Fill in the Details**
   
   For Azure DevOps, use these values:
   
   - **Issuer**: `https://vstoken.dev.azure.com/<YOUR_AZURE_DEVOPS_ORG_ID>`
   - **Subject identifier**: `sc://YOUR_ORG_NAME/YOUR_PROJECT_NAME/YOUR_SERVICE_CONNECTION_NAME`
   - **Name**: `oidc-terraform-dev`
   - **Description**: `OIDC for Terraform deployments to dev environment`

   **How to find your Azure DevOps Org ID:**
   ```bash
   # In Azure DevOps, go to Organization Settings → Overview
   # Or use this API call:
   curl -u :YOUR_PAT https://dev.azure.com/YOUR_ORG_NAME/_apis/connectionData
   ```

   Example values:
   ```
   Issuer: https://vstoken.dev.azure.com/12345678-abcd-1234-abcd-123456789012
   Subject: sc://contoso-devops/terraform-infrastructure/sc-azure-oidc-or-mi
   ```

4. **Click "Add"**

### Step 3: Assign Azure Role to Service Principal

1. **In Azure Portal, navigate to your Subscription**
   - Click **"Access control (IAM)"**
   - Click **"+ Add"** → **"Add role assignment"**

2. **Select Role**
   - Role: **Contributor** (or **Owner** if you need to create role assignments)
   - Click **"Next"**

3. **Select Members**
   - Assign access to: **User, group, or service principal**
   - Click **"+ Select members"**
   - Search for `terraform-oidc-sp`
   - Click **"Select"**

4. **Review + Assign**
   - Click **"Review + assign"**
   - Click **"Review + assign"** again

**✓ Checkpoint**: Service principal has permissions on your subscription.

### Step 4: Create Service Connection in Azure DevOps

1. **Navigate to Project Settings**
   - In your Azure DevOps project, click **Project settings** (bottom left)
   - Click **"Service connections"** under Pipelines

2. **Create New Service Connection**
   - Click **"+ New service connection"**
   - Select **"Azure Resource Manager"**
   - Click **"Next"**

3. **Select Authentication Method**
   - Authentication method: **Workload Identity federation (manual)**
   - Click **"Next"**

4. **Fill in Connection Details**
   - **Service connection name**: `sc-azure-oidc-or-mi` (⚠️ MUST match your pipeline YAML)
   - **Subscription ID**: Your Azure subscription ID
   - **Subscription Name**: Your subscription name (display only)
   - **Service Principal Id**: Application (client) ID from app registration
   - **Tenant ID**: Your Azure tenant ID
   - **Service Principal Key**: Leave blank (we're using OIDC, not secrets!)

5. **Grant Access Permission**
   - ✅ Check **"Grant access permission to all pipelines"**
   - Click **"Verify and save"**

   ![Service Connection](https://docs.microsoft.com/en-us/azure/devops/media/service-connection-oidc.png)

**✓ Checkpoint**: Azure DevOps can now authenticate to Azure without secrets!

---

## Phase 4: Environment Setup

Environments provide **approval gates** for deployments. This ensures no one can deploy to production without approval.

### Step 1: Create Development Environment

1. **Navigate to Environments**
   - In Azure DevOps, click **Pipelines** → **Environments**
   - Click **"+ New environment"**

2. **Create Dev Environment**
   - Name: `dev`
   - Description: `Development environment`
   - Resource: **None** (we're using it for approvals only)
   - Click **"Create"**

3. **Configure Checks and Approvals (Optional for Dev)**
   - For dev, you may skip approvals
   - Or add approvals for extra safety

### Step 2: Create Staging Environment

1. **Create Staging Environment**
   - Name: `staging`
   - Description: `Staging environment - requires approval`
   - Click **"Create"**

2. **Add Approval Check**
   - Click the **⋮** (three dots) menu
   - Select **"Approvals and checks"**
   - Click **"+"** → Select **"Approvals"**
   
3. **Configure Approval**
   - Approvers: Add yourself and/or team members
   - Instructions: `Please review the Terraform plan before approving`
   - **Timeout**: 30 days (pipeline will wait for approval)
   - Click **"Create"**

### Step 3: Create Production Environment

1. **Create Production Environment**
   - Name: `prod`
   - Description: `Production environment - requires multiple approvals`
   - Click **"Create"**

2. **Add Approvals**
   - Add multiple approvers (e.g., Tech Lead + Manager)
   - Set **"Minimum number of approvers required"**: 2
   - Instructions: `PRODUCTION DEPLOYMENT - Review carefully`

**✓ Checkpoint**: You have gated environments for safe deployments.

---

## Phase 5: Pipeline Creation

### Step 1: Create CI Pipeline (Plan on PR)

1. **Navigate to Pipelines**
   - Click **Pipelines** in the left menu
   - Click **"+ New pipeline"**

2. **Select Repository**
   - Where is your code? **Azure Repos Git**
   - Select your repository: `terraform-infrastructure`

3. **Configure Pipeline**
   - Pipeline configuration: **Existing Azure Pipelines YAML file**
   - Path: `/pipelines/ci-terraform-plan.yml`
   - Click **"Continue"**

4. **Review and Save**
   - Click **"Save"** (don't run yet)
   - Rename pipeline to: `CI - Terraform Plan`

### Step 2: Create CD Pipeline (Apply with Approval)

1. **Create Another Pipeline**
   - Click **"+ New pipeline"**
   - Select repository: `terraform-infrastructure`
   - Existing YAML file: `/pipelines/cd-terraform-apply.yml`

2. **Review and Save**
   - Click **"Save"**
   - Rename to: `CD - Terraform Apply`

3. **Configure Pipeline Variables**
   - Click **"Edit"** on the pipeline
   - Click **"Variables"** (top right)
   - Add variables:
     - `azureSubscription`: Your subscription ID
     - `serviceConnection`: `sc-azure-oidc-or-mi`

**✓ Checkpoint**: Pipelines are created and ready to run.

---

## Phase 6: First Deployment

### Step 1: Prepare Backend Configuration

1. **Update Backend Configuration**
   
   Edit `infra/envs/dev/backend.tf`:
   ```hcl
   terraform {
     backend "azurerm" {
       resource_group_name  = "contoso-tfstate-rg"
       storage_account_name = "stcontosotfstate001"
       container_name       = "tfstate"
       key                  = "dev.terraform.tfstate"
       use_azuread_auth     = true
     }
   }
   ```

2. **Update Variables**
   
   Edit `infra/envs/dev/dev.tfvars`:
   ```hcl
   project_name = "contoso"
   location     = "southeastasia"
   tenant_id    = "YOUR_TENANT_ID"
   admin_group_object_ids = ["YOUR_ADMIN_GROUP_ID"]
   ```

### Step 2: Create a Pull Request

1. **Create a New Branch**
   ```bash
   git checkout -b feature/initial-infrastructure
   git add .
   git commit -m "Configure Terraform backend and variables"
   git push origin feature/initial-infrastructure
   ```

2. **Create PR in Azure DevOps**
   - Go to **Repos** → **Pull requests**
   - Click **"+ New pull request"**
   - Source: `feature/initial-infrastructure`
   - Target: `main`
   - Click **"Create"**

3. **Watch CI Pipeline Run**
   - The CI pipeline will automatically run
   - It will validate and plan your infrastructure
   - Review the plan output carefully

4. **Review and Merge**
   - If the plan looks good, click **"Approve"**
   - Click **"Complete"** to merge

### Step 3: Run CD Pipeline

1. **Navigate to Pipelines**
   - Click **Pipelines** → **"CD - Terraform Apply"**
   - Click **"Run pipeline"**

2. **Select Parameters**
   - Environment: `dev`
   - Auto Approve: Leave unchecked
   - Click **"Run"**

3. **Approve Deployment**
   - Pipeline will pause at the environment gate
   - Click **"Review"** → **"Approve"**
   - Add comment: `Approving initial infrastructure deployment`

4. **Monitor Deployment**
   - Watch the pipeline execute
   - Review the apply output
   - Check for any errors

**🎉 Success!** Your infrastructure is now deployed!

---

## Troubleshooting

### Common Issue 1: "Failed to get existing workspaces"

**Error**: `Error: Failed to get existing workspaces: storage: service returned error: StatusCode=403`

**Solution**: 
- Service principal doesn't have access to storage account
- Grant "Storage Blob Data Contributor" role to the service principal on the storage account

```bash
az role assignment create \
  --role "Storage Blob Data Contributor" \
  --assignee YOUR_SERVICE_PRINCIPAL_ID \
  --scope /subscriptions/YOUR_SUB_ID/resourceGroups/contoso-tfstate-rg/providers/Microsoft.Storage/storageAccounts/stcontosotfstate001
```

### Common Issue 2: "OIDC token validation failed"

**Error**: `Error: OIDC token validation failed`

**Solution**:
- Check that the federated credential subject matches exactly
- Subject format: `sc://ORG_NAME/PROJECT_NAME/CONNECTION_NAME`
- Ensure service connection name matches what you configured in AAD

### Common Issue 3: "Service connection not found"

**Error**: `Could not find service connection 'sc-azure-oidc-or-mi'`

**Solution**:
- Verify service connection name in Azure DevOps matches YAML
- Grant pipeline permission to use the service connection
- In Service Connection settings → Click ⋮ → Security → Grant access

### Common Issue 4: Pipeline runs but doesn't ask for approval

**Problem**: CD pipeline runs immediately without approval

**Solution**:
- Ensure you're using `deployment` job type (not `job`)
- Verify environment name matches exactly (case-sensitive)
- Check that approval is configured on the environment

### Common Issue 5: "Subscription not found"

**Error**: `The subscription 'XXXXXXXX' could not be found`

**Solution**:
- Verify subscription ID in variables
- Ensure service principal has access to the subscription
- Check that you're signed in to the correct tenant

---

## Next Steps

✅ **Congratulations!** You've successfully set up the enterprise Terraform framework with Azure DevOps.

**What to do next:**

1. **Extend to Staging/Production**
   - Repeat Phase 6 for staging and prod environments
   - Configure stricter approval gates

2. **Add More Infrastructure**
   - Deploy AKS cluster
   - Add Cosmos DB
   - Create additional modules

3. **Set Up Monitoring**
   - Configure Azure Monitor alerts for pipeline failures
   - Set up notifications (Teams/Slack)

4. **Implement Branching Strategy**
   - Define branch policies
   - Require PR reviews before merge

5. **Document for Your Team**
   - Create runbook for common operations
   - Document approval process
   - Train team members on workflow

---

## Quick Reference

### Important URLs
- Azure DevOps: `https://dev.azure.com/YOUR_ORG`
- Azure Portal: `https://portal.azure.com`
- Service Connections: `https://dev.azure.com/YOUR_ORG/YOUR_PROJECT/_settings/adminservices`

### Key Commands
```bash
# Azure CLI login
az login

# Set subscription
az account set --subscription "SUBSCRIPTION_ID"

# Get subscription details
az account show

# List service principals
az ad sp list --display-name "terraform-oidc-sp"

# Terraform commands (local testing)
cd infra/envs/dev
terraform init
terraform plan -var-file="dev.tfvars"
```

### Pipeline Files
- CI (Plan): `/pipelines/ci-terraform-plan.yml`
- CD (Apply): `/pipelines/cd-terraform-apply.yml`
- Templates: `/pipelines/templates/`

### Environment Configuration
- Dev: `/infra/envs/dev/`
- Staging: `/infra/envs/staging/`
- Production: `/infra/envs/prod/`
