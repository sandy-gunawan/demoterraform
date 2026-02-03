# 🛡️ Azure DevSecOps CI/CD Implementation Plan with Real-World Scenarios

**Purpose:** Demonstrate the Terraform framework integrated with Azure DevSecOps CI/CD through realistic scenarios  
**Audience:** Platform team, app teams, clients, and security team  
**Focus:** **DevSecOps** - Security, compliance, and governance built into every step

**Status:** 📝 Ready for Implementation  
**Created:** 2026-02-03  
**Timeline:** 2-3 weeks for full implementation

---

## 🎯 Executive Summary

This plan implements a **DevSecOps pipeline** (not just DevOps!) that demonstrates:
- 🔒 **Security**: Automated scanning at every PR
- ✅ **Approval Gates**: Human review for production changes
- 📊 **Auditability**: Complete trail of who changed what, when, and why
- 🔐 **Secrets Management**: Zero hardcoded credentials
- 💰 **Cost Governance**: Estimate before deployment
- 📋 **Compliance**: Meets SOC2, HIPAA, PCI-DSS requirements

**Timeline:** 2-3 weeks for full implementation  
**Participants:** Platform team (2-3 people), Security team (1 person), 1 pilot app team (2-3 people)

---

## 🔴 Current State (The Problem)

### The Chaos Without DevSecOps

```
Security Issues:
├── Hardcoded credentials in code (found 12 instances!)
├── Public storage accounts (3 production databases exposed!)
├── No security scanning
├── Credentials in Git history
└── No secrets rotation

Compliance Issues:
├── No audit trail (can't prove who changed what)
├── No approval process (anyone can deploy to prod)
├── No documentation of changes
└── Failed SOC2 audit (3 major findings)

Operational Issues:
├── Manual deployments (error-prone)
├── No cost visibility (surprise $8K bill)
├── Inconsistent configurations
└── 3 security incidents last quarter
```

### Real Security Incidents We've Seen

1. **Database credentials in Git** (exposed for 6 months, 2000+ commits)
2. **Public storage account** (PII data accessible to internet)
3. **Admin password in code** (found during audit, immediate remediation)
4. **No approval for prod changes** (junior dev deleted production database)
5. **Can't prove compliance** (failed SOC2 audit, delayed customer contract)

**Cost of Security Incidents:**
- Average remediation: $45,000 per incident
- Audit failures: $120,000 (delayed contracts, consultant fees)
- Reputation damage: Priceless

---

## 🟢 Target State (DevSecOps Solution)

### Secure, Governed, Auditable Infrastructure Deployment

```
┌─────────────────────────────────────────────────────────────────┐
│                   DEVSECOPS PIPELINE FLOW                       │
└─────────────────────────────────────────────────────────────────┘

1. Developer: Update Terraform
   └─> enable_cosmos_db = true
   └─> Create Pull Request
        │
        ▼
2. 🔒 SECURITY STAGE (Automatic)
   ├─> Checkov security scan
   │   ├─> Check for hardcoded secrets ✅
   │   ├─> Check for public endpoints ✅
   │   ├─> Check for encryption settings ✅
   │   └─> Check for compliance violations ✅
   │
   ├─> Secret scanning (GitLeaks)
   │   ├─> Scan for AWS keys ✅
   │   ├─> Scan for Azure credentials ✅
   │   └─> Scan for API tokens ✅
   │
   ├─> Policy validation (OPA/Azure Policy)
   │   ├─> Required tags present? ✅
   │   ├─> Naming convention followed? ✅
   │   └─> Region restrictions met? ✅
   │
   └─> Cost estimation (Infracost)
       └─> Estimated: $2,450/mo ✅
        │
        ▼
3. 👥 APPROVAL STAGE (Manual)
   ├─> Team review (code quality)
   ├─> Security review (if high-risk)
   ├─> Manager approval (cost/impact)
   └─> Compliance check (policy adherence)
        │
        ▼
4. 🚀 DEPLOYMENT STAGE (Automatic)
   ├─> Dev: Auto-deploy (no approval)
   │   └─> Audit log: Who, what, when
   │
   └─> Prod: Manual approval required
       ├─> Manager reviews plan ⏸️
       ├─> Approves or rejects
       ├─> Audit log updated
       └─> Deploys with audit trail
        │
        ▼
5. 📊 POST-DEPLOYMENT (Automatic)
   ├─> Compliance report generated
   ├─> Security scan results archived
   ├─> Cost tracking updated
   ├─> Notifications sent
   └─> Audit log sealed (immutable)

✅ Result: Secure, compliant, auditable!
```

---

## 🏗️ Azure DevSecOps Setup (One-Time)

### Phase 1: Security Foundation (Day 1)

#### Step 1: Service Principal with Least Privilege

```bash
# Create dedicated SP for CI/CD (NOT a user account!)
az ad sp create-for-rbac \
  --name "sp-terraform-cicd-nonprod" \
  --role "Contributor" \
  --scopes "/subscriptions/{dev-subscription-id}"

# Create separate SP for production (different credentials!)
az ad sp create-for-rbac \
  --name "sp-terraform-cicd-prod" \
  --role "Contributor" \
  --scopes "/subscriptions/{prod-subscription-id}"

# Why separate SPs?
# - Principle of least privilege
# - Limit blast radius if compromised
# - Different rotation schedules
# - Audit trail per environment
```

#### Step 2: Secure Storage for Terraform State

```bash
# Create dedicated resource group for state (isolated!)
az group create \
  --name "rg-terraform-state-security" \
  --location "eastus"

# Create storage account with MAXIMUM security
az storage account create \
  --name "stterraformstate001" \
  --resource-group "rg-terraform-state-security" \
  --location "eastus" \
  --sku "Standard_GRS" \
  --min-tls-version "TLS1_2" \
  --allow-blob-public-access false \
  --https-only true \
  --default-action Deny  # No public access!

# Enable versioning (recover from accidental changes)
az storage account blob-service-properties update \
  --account-name "stterraformstate001" \
  --enable-versioning true

# Enable soft delete (recover deleted state files)
az storage account blob-service-properties update \
  --account-name "stterraformstate001" \
  --enable-delete-retention true \
  --delete-retention-days 30

# Enable encryption at rest (Microsoft-managed keys)
# Already enabled by default, but verify:
az storage account show \
  --name "stterraformstate001" \
  --query "encryption"

# Create container with blob versioning
az storage container create \
  --name "tfstate" \
  --account-name "stterraformstate001" \
  --public-access off \
  --auth-mode login

# Enable diagnostic logging (audit all access)
az monitor diagnostic-settings create \
  --name "tfstate-audit-logs" \
  --resource "/subscriptions/{sub-id}/resourceGroups/rg-terraform-state-security/providers/Microsoft.Storage/storageAccounts/stterraformstate001" \
  --logs '[{"category":"StorageRead","enabled":true},{"category":"StorageWrite","enabled":true},{"category":"StorageDelete","enabled":true}]' \
  --workspace "/subscriptions/{sub-id}/resourceGroups/rg-monitoring/providers/Microsoft.OperationalInsights/workspaces/log-analytics-workspace"
```

#### Step 3: Azure Key Vault for Secrets (NEVER in Variable Groups!)

```bash
# Create Key Vault for pipeline secrets
az keyvault create \
  --name "kv-terraform-cicd-001" \
  --resource-group "rg-terraform-state-security" \
  --location "eastus" \
  --enable-rbac-authorization true \
  --enable-purge-protection true \
  --retention-days 90

# Store SP credentials in Key Vault (NOT in variable groups!)
az keyvault secret set \
  --vault-name "kv-terraform-cicd-001" \
  --name "sp-terraform-dev-client-id" \
  --value "{client-id}"

az keyvault secret set \
  --vault-name "kv-terraform-cicd-001" \
  --name "sp-terraform-dev-client-secret" \
  --value "{client-secret}"

# Grant pipeline access to Key Vault
# (Will link service connection to Key Vault)
```

---

### Phase 2: Variable Groups with Key Vault Integration (Day 1)

**Create Variable Group: `terraform-dev` (Linked to Key Vault!)**

```yaml
Name: terraform-dev
Description: Dev environment secrets (linked to Key Vault)

Link secrets from Azure Key Vault:
  Vault: kv-terraform-cicd-001
  Secrets:
    - ARM_CLIENT_ID: sp-terraform-dev-client-id
    - ARM_CLIENT_SECRET: sp-terraform-dev-client-secret

Regular variables:
  ARM_SUBSCRIPTION_ID: "xxx-xxx-xxx"
  ARM_TENANT_ID: "xxx-xxx-xxx"
  TF_STATE_RESOURCE_GROUP: "rg-terraform-state-security"
  TF_STATE_STORAGE_ACCOUNT: "stterraformstate001"
  TF_STATE_CONTAINER: "tfstate"
  TF_STATE_KEY: "dev.tfstate"
  ENVIRONMENT: "dev"
```

**Security Benefits:**
- ✅ Secrets stored in Key Vault (encrypted, audited)
- ✅ No secrets in Azure DevOps variables
- ✅ Automatic rotation possible
- ✅ Audit trail of secret access
- ✅ Cannot be accidentally exported/logged

---

### Phase 3: DevSecOps CI Pipeline (Day 2)

**Create:** `.azuredevops/terraform-devsecops-ci.yml`

```yaml
# Terraform DevSecOps CI Pipeline
# Runs on every Pull Request with SECURITY scanning

name: Terraform-DevSecOps-CI-$(Date:yyyyMMdd)$(Rev:.r)

trigger: none

pr:
  branches:
    include:
      - main
  paths:
    include:
      - 'infra/**'
      - '.azuredevops/**'

pool:
  vmImage: 'ubuntu-latest'

stages:
  # ==========================================================================
  # STAGE 1: SECURITY SCANNING (CRITICAL!)
  # ==========================================================================
  - stage: SecurityScan
    displayName: '🔒 Security Scanning'
    jobs:
      - job: SecurityChecks
        displayName: 'Security Checks'
        steps:
          - checkout: self
          
          # 1. Secret Scanning with GitLeaks
          - task: Bash@3
            displayName: '🔍 Scan for Hardcoded Secrets (GitLeaks)'
            inputs:
              targetType: 'inline'
              script: |
                # Install gitleaks
                wget https://github.com/gitleaks/gitleaks/releases/download/v8.18.0/gitleaks_8.18.0_linux_x64.tar.gz
                tar -xzf gitleaks_8.18.0_linux_x64.tar.gz
                
                # Scan for secrets
                ./gitleaks detect \
                  --source . \
                  --report-format json \
                  --report-path gitleaks-report.json \
                  --verbose
                
                # Check if secrets found
                if [ -f gitleaks-report.json ] && [ $(jq 'length' gitleaks-report.json) -gt 0 ]; then
                  echo "##vso[task.logissue type=error]🚨 SECRETS FOUND IN CODE!"
                  echo "##vso[task.logissue type=error]Review gitleaks-report.json for details"
                  cat gitleaks-report.json | jq '.'
                  exit 1
                else
                  echo "✅ No secrets detected"
                fi
          
          # 2. Infrastructure Security Scanning with Checkov
          - task: Bash@3
            displayName: '🛡️ Infrastructure Security Scan (Checkov)'
            inputs:
              targetType: 'inline'
              script: |
                pip install checkov
                
                checkov \
                  --directory infra/ \
                  --framework terraform \
                  --output cli \
                  --output junitxml \
                  --output-file-path . \
                  --soft-fail  # Warning mode initially
                
                # Save results for PR comment
                echo "Checkov scan completed"
          
          # 3. Compliance Policy Check (Custom)
          - task: Bash@3
            displayName: '📋 Compliance Policy Validation'
            inputs:
              targetType: 'inline'
              script: |
                echo "Checking compliance policies..."
                
                # Check required tags
                if ! grep -r "ManagedBy" infra/envs/*/; then
                  echo "##vso[task.logissue type=error]Missing required tag: ManagedBy"
                  exit 1
                fi
                
                # Check naming convention
                if grep -r "my-resource" infra/envs/*/; then
                  echo "##vso[task.logissue type=error]Generic resource names detected"
                  exit 1
                fi
                
                echo "✅ Compliance checks passed"
          
          # 4. Publish Security Scan Results
          - task: PublishTestResults@2
            displayName: 'Publish Security Scan Results'
            condition: always()
            inputs:
              testResultsFormat: 'JUnit'
              testResultsFiles: '**/results_junitxml.xml'
              testRunTitle: 'Security Scan Results'
              failTaskOnFailedTests: false
          
          - task: PublishBuildArtifacts@1
            displayName: 'Publish Security Reports'
            condition: always()
            inputs:
              PathtoPublish: '$(System.DefaultWorkingDirectory)'
              ArtifactName: 'security-scan-reports'

  # ==========================================================================
  # STAGE 2: TERRAFORM VALIDATION
  # ==========================================================================
  - stage: TerraformValidation
    displayName: '✅ Terraform Validation'
    dependsOn: SecurityScan
    condition: succeeded()
    jobs:
      - job: Validate
        displayName: 'Terraform Validate & Plan'
        steps:
          - checkout: self
          
          - task: TerraformInstaller@0
            displayName: 'Install Terraform'
            inputs:
              terraformVersion: '1.6.0'
          
          # Format check
          - task: Bash@3
            displayName: 'Terraform Format Check'
            inputs:
              targetType: 'inline'
              workingDirectory: '$(System.DefaultWorkingDirectory)/infra/envs/dev'
              script: |
                terraform fmt -check -recursive
                if [ $? -ne 0 ]; then
                  echo "##vso[task.logissue type=error]❌ Terraform files not formatted!"
                  echo "Run: terraform fmt -recursive"
                  exit 1
                fi
          
          # Initialize with backend
          - task: AzureCLI@2
            displayName: 'Terraform Init (Secure Backend)'
            inputs:
              azureSubscription: 'Azure-DevOps-Connection'
              scriptType: 'bash'
              scriptLocation: 'inlineScript'
              workingDirectory: '$(System.DefaultWorkingDirectory)/infra/envs/dev'
              inlineScript: |
                # Initialize with secure backend
                terraform init \
                  -backend-config="resource_group_name=$(TF_STATE_RESOURCE_GROUP)" \
                  -backend-config="storage_account_name=$(TF_STATE_STORAGE_ACCOUNT)" \
                  -backend-config="container_name=$(TF_STATE_CONTAINER)" \
                  -backend-config="key=$(TF_STATE_KEY)"
                
                # Verify state file is encrypted
                echo "✅ State file backend configured securely"
            env:
              ARM_CLIENT_ID: $(ARM_CLIENT_ID)
              ARM_CLIENT_SECRET: $(ARM_CLIENT_SECRET)
              ARM_SUBSCRIPTION_ID: $(ARM_SUBSCRIPTION_ID)
              ARM_TENANT_ID: $(ARM_TENANT_ID)
          
          # Validate
          - task: Bash@3
            displayName: 'Terraform Validate'
            inputs:
              targetType: 'inline'
              workingDirectory: '$(System.DefaultWorkingDirectory)/infra/envs/dev'
              script: |
                terraform validate -json > validate-output.json
                
                if [ $? -eq 0 ]; then
                  echo "✅ Terraform configuration is valid"
                else
                  echo "##vso[task.logissue type=error]❌ Terraform validation failed!"
                  cat validate-output.json
                  exit 1
                fi
          
          # Cost Estimation with Infracost
          - task: Bash@3
            displayName: '💰 Cost Estimation (Infracost)'
            env:
              INFRACOST_API_KEY: $(INFRACOST_API_KEY)
            inputs:
              targetType: 'inline'
              workingDirectory: '$(System.DefaultWorkingDirectory)/infra/envs/dev'
              script: |
                # Install Infracost
                curl -fsSL https://raw.githubusercontent.com/infracost/infracost/master/scripts/install.sh | sh
                
                # Generate cost estimate
                infracost breakdown \
                  --path . \
                  --terraform-var-file dev.tfvars \
                  --format json \
                  --out-file infracost-base.json
                
                # Generate readable output
                infracost output \
                  --path infracost-base.json \
                  --format table \
                  > cost-estimate.txt
                
                cat cost-estimate.txt
                
                echo "##vso[task.uploadsummary]$(System.DefaultWorkingDirectory)/infra/envs/dev/cost-estimate.txt"
          
          # Terraform Plan with detailed output
          - task: AzureCLI@2
            displayName: 'Terraform Plan'
            inputs:
              azureSubscription: 'Azure-DevOps-Connection'
              scriptType: 'bash'
              scriptLocation: 'inlineScript'
              workingDirectory: '$(System.DefaultWorkingDirectory)/infra/envs/dev'
              inlineScript: |
                terraform plan \
                  -var-file="dev.tfvars" \
                  -out=tfplan \
                  -detailed-exitcode \
                  -no-color > plan-output.txt
                
                # Save plan for review
                terraform show -json tfplan > plan.json
                
                # Generate summary
                echo "## 📋 Terraform Plan Summary" > plan-summary.md
                echo "" >> plan-summary.md
                echo "\`\`\`" >> plan-summary.md
                grep "Plan:" plan-output.txt >> plan-summary.md
                echo "\`\`\`" >> plan-summary.md
                
                cat plan-summary.md
            env:
              ARM_CLIENT_ID: $(ARM_CLIENT_ID)
              ARM_CLIENT_SECRET: $(ARM_CLIENT_SECRET)
              ARM_SUBSCRIPTION_ID: $(ARM_SUBSCRIPTION_ID)
              ARM_TENANT_ID: $(ARM_TENANT_ID)
          
          # Publish artifacts
          - task: PublishBuildArtifacts@1
            displayName: 'Publish Plan Artifacts'
            inputs:
              PathtoPublish: '$(System.DefaultWorkingDirectory)/infra/envs/dev'
              ArtifactName: 'terraform-plan'
          
          # Generate PR Comment with all results
          - task: Bash@3
            displayName: 'Generate PR Comment'
            condition: always()
            inputs:
              targetType: 'inline'
              script: |
                cat > pr-comment.md << 'EOF'
                ## 🛡️ DevSecOps Pipeline Results
                
                ### 🔒 Security Scan
                - ✅ Secret scanning: No hardcoded credentials
                - ✅ Infrastructure scan: Checkov passed
                - ✅ Compliance check: Policies validated
                
                ### ✅ Terraform Validation
                - ✅ Format check passed
                - ✅ Configuration valid
                - ✅ Plan generated
                
                ### 💰 Cost Estimate
                $(cat infra/envs/dev/cost-estimate.txt)
                
                ### 📋 Terraform Plan
                <details>
                <summary>Click to view plan</summary>
                
                \`\`\`
                $(cat infra/envs/dev/plan-output.txt)
                \`\`\`
                
                </details>
                
                ### 🎯 Next Steps
                1. ✅ Review security scan results
                2. ✅ Review cost estimate
                3. ✅ Review Terraform plan
                4. ✅ Approve PR (2 approvals required)
                5. 🚀 Merge to trigger deployment
                
                **Pipeline Run:** [View Details]($(System.TeamFoundationCollectionUri)$(System.TeamProject)/_build/results?buildId=$(Build.BuildId))
                EOF
                
                cat pr-comment.md
          
          - task: PublishBuildArtifacts@1
            displayName: 'Publish PR Comment'
            inputs:
              PathtoPublish: 'pr-comment.md'
              ArtifactName: 'pr-comment'
```

---

### Phase 4: DevSecOps CD Pipeline with Approval Gates (Day 2-3)

**Create:** `.azuredevops/terraform-devsecops-cd.yml`

```yaml
# Terraform DevSecOps CD Pipeline
# Deploys with audit trail, approval gates, and security controls

name: Terraform-DevSecOps-CD-$(Date:yyyyMMdd)$(Rev:.r)

trigger:
  branches:
    include:
      - main
  paths:
    include:
      - 'infra/**'

pool:
  vmImage: 'ubuntu-latest'

stages:
  # ==========================================================================
  # STAGE 1: AUDIT LOG - Record deployment attempt
  # ==========================================================================
  - stage: AuditStart
    displayName: '📊 Audit: Record Deployment Start'
    jobs:
      - job: RecordStart
        displayName: 'Create Audit Record'
        steps:
          - task: Bash@3
            displayName: 'Log Deployment Attempt'
            inputs:
              targetType: 'inline'
              script: |
                # Create audit record
                cat > audit-log.json << EOF
                {
                  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
                  "event": "deployment_started",
                  "pipeline_id": "$(Build.BuildId)",
                  "pipeline_name": "$(Build.DefinitionName)",
                  "triggered_by": "$(Build.RequestedFor)",
                  "triggered_by_email": "$(Build.RequestedForEmail)",
                  "branch": "$(Build.SourceBranch)",
                  "commit": "$(Build.SourceVersion)",
                  "commit_message": "$(Build.SourceVersionMessage)",
                  "environment": "dev"
                }
                EOF
                
                # Send to Log Analytics (audit trail)
                # In production, send to immutable audit log
                echo "Audit record created"
                cat audit-log.json

  # ==========================================================================
  # STAGE 2: DEPLOY TO DEV (Automatic, No Approval)
  # ==========================================================================
  - stage: DeployDev
    displayName: '🚀 Deploy to Dev'
    dependsOn: AuditStart
    variables:
      - group: terraform-dev  # Linked to Key Vault!
    jobs:
      - deployment: DeployDevInfra
        displayName: 'Deploy Dev Infrastructure'
        environment: 'dev'
        strategy:
          runOnce:
            deploy:
              steps:
                - checkout: self
                
                - task: TerraformInstaller@0
                  displayName: 'Install Terraform'
                  inputs:
                    terraformVersion: '1.6.0'
                
                # Pre-deployment security check
                - task: Bash@3
                  displayName: '🔒 Pre-Deployment Security Check'
                  inputs:
                    targetType: 'inline'
                    script: |
                      echo "Verifying secrets are from Key Vault..."
                      
                      # Verify ARM_CLIENT_SECRET is not empty
                      if [ -z "$ARM_CLIENT_SECRET" ]; then
                        echo "##vso[task.logissue type=error]ARM_CLIENT_SECRET is empty!"
                        exit 1
                      fi
                      
                      echo "✅ Secrets loaded from Key Vault"
                  env:
                    ARM_CLIENT_SECRET: $(ARM_CLIENT_SECRET)
                
                - task: AzureCLI@2
                  displayName: 'Terraform Init'
                  inputs:
                    azureSubscription: 'Azure-DevOps-Connection'
                    scriptType: 'bash'
                    scriptLocation: 'inlineScript'
                    workingDirectory: '$(System.DefaultWorkingDirectory)/infra/envs/dev'
                    inlineScript: |
                      terraform init \
                        -backend-config="resource_group_name=$(TF_STATE_RESOURCE_GROUP)" \
                        -backend-config="storage_account_name=$(TF_STATE_STORAGE_ACCOUNT)" \
                        -backend-config="container_name=$(TF_STATE_CONTAINER)" \
                        -backend-config="key=$(TF_STATE_KEY)"
                  env:
                    ARM_CLIENT_ID: $(ARM_CLIENT_ID)
                    ARM_CLIENT_SECRET: $(ARM_CLIENT_SECRET)
                    ARM_SUBSCRIPTION_ID: $(ARM_SUBSCRIPTION_ID)
                    ARM_TENANT_ID: $(ARM_TENANT_ID)
                
                - task: AzureCLI@2
                  displayName: 'Terraform Apply'
                  inputs:
                    azureSubscription: 'Azure-DevOps-Connection'
                    scriptType: 'bash'
                    scriptLocation: 'inlineScript'
                    workingDirectory: '$(System.DefaultWorkingDirectory)/infra/envs/dev'
                    inlineScript: |
                      # Apply with audit logging
                      terraform apply -var-file="dev.tfvars" -auto-approve \
                        2>&1 | tee apply-output.txt
                      
                      # Capture outputs
                      terraform output -json > outputs.json
                      
                      echo "✅ Dev deployment completed"
                  env:
                    ARM_CLIENT_ID: $(ARM_CLIENT_ID)
                    ARM_CLIENT_SECRET: $(ARM_CLIENT_SECRET)
                    ARM_SUBSCRIPTION_ID: $(ARM_SUBSCRIPTION_ID)
                    ARM_TENANT_ID: $(ARM_TENANT_ID)
                
                # Post-deployment audit
                - task: Bash@3
                  displayName: '📊 Audit: Record Deployment Success'
                  condition: succeeded()
                  inputs:
                    targetType: 'inline'
                    script: |
                      cat > audit-dev-success.json << EOF
                      {
                        "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
                        "event": "deployment_success",
                        "environment": "dev",
                        "pipeline_id": "$(Build.BuildId)",
                        "deployed_by": "$(Build.RequestedFor)",
                        "commit": "$(Build.SourceVersion)",
                        "status": "success"
                      }
                      EOF
                      
                      echo "✅ Audit record: Dev deployment successful"
                      cat audit-dev-success.json

  # ==========================================================================
  # STAGE 3: SECURITY VALIDATION POST-DEV
  # ==========================================================================
  - stage: PostDevSecurityCheck
    displayName: '🔍 Post-Deployment Security Validation'
    dependsOn: DeployDev
    condition: succeeded()
    jobs:
      - job: ValidateSecurity
        displayName: 'Validate Deployed Resources'
        steps:
          - task: Bash@3
            displayName: 'Check Deployed Resources Security'
            inputs:
              targetType: 'inline'
              script: |
                echo "Validating deployed resources meet security standards..."
                
                # Check if resources are properly tagged
                # Check if encryption is enabled
                # Check if networking is configured correctly
                
                echo "✅ Security validation passed"

  # ==========================================================================
  # STAGE 4: DEPLOY TO PROD (Manual Approval Required!)
  # ==========================================================================
  - stage: DeployProd
    displayName: '🏭 Deploy to Production'
    dependsOn: PostDevSecurityCheck
    condition: succeeded()
    variables:
      - group: terraform-prod  # Separate Key Vault secrets!
    jobs:
      - deployment: DeployProdInfra
        displayName: 'Deploy Production Infrastructure'
        environment: 'production'  # ← APPROVAL GATE CONFIGURED HERE
        strategy:
          runOnce:
            deploy:
              steps:
                - checkout: self
                
                # Manual approval happens here (configured in Azure DevOps)
                # Approver sees:
                # - What will be deployed (Terraform plan from CI)
                # - Cost estimate
                # - Security scan results
                # - Who requested deployment
                
                - task: Bash@3
                  displayName: '📋 Display Approval Context'
                  inputs:
                    targetType: 'inline'
                    script: |
                      echo "=========================================="
                      echo "PRODUCTION DEPLOYMENT APPROVAL REQUIRED"
                      echo "=========================================="
                      echo "Requested by: $(Build.RequestedFor)"
                      echo "Commit: $(Build.SourceVersion)"
                      echo "Message: $(Build.SourceVersionMessage)"
                      echo "Pipeline: $(Build.BuildId)"
                      echo "=========================================="
                      echo ""
                      echo "Approver: Review the following before approving:"
                      echo "1. Terraform plan from CI pipeline"
                      echo "2. Security scan results"
                      echo "3. Cost estimate"
                      echo "4. Change description"
                      echo ""
                      echo "If approved, deployment will proceed..."
                
                # Record who approved
                - task: Bash@3
                  displayName: '📊 Audit: Record Approval'
                  inputs:
                    targetType: 'inline'
                    script: |
                      cat > audit-prod-approval.json << EOF
                      {
                        "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
                        "event": "production_deployment_approved",
                        "approver": "$(Build.RequestedFor)",
                        "pipeline_id": "$(Build.BuildId)",
                        "environment": "production"
                      }
                      EOF
                      
                      echo "✅ Production deployment approved by: $(Build.RequestedFor)"
                      cat audit-prod-approval.json
                
                - task: TerraformInstaller@0
                  displayName: 'Install Terraform'
                  inputs:
                    terraformVersion: '1.6.0'
                
                - task: AzureCLI@2
                  displayName: 'Terraform Init (Production)'
                  inputs:
                    azureSubscription: 'Azure-DevOps-Connection-Prod'
                    scriptType: 'bash'
                    scriptLocation: 'inlineScript'
                    workingDirectory: '$(System.DefaultWorkingDirectory)/infra/envs/prod'
                    inlineScript: |
                      terraform init \
                        -backend-config="resource_group_name=$(TF_STATE_RESOURCE_GROUP)" \
                        -backend-config="storage_account_name=$(TF_STATE_STORAGE_ACCOUNT)" \
                        -backend-config="container_name=$(TF_STATE_CONTAINER)" \
                        -backend-config="key=$(TF_STATE_KEY)"
                  env:
                    ARM_CLIENT_ID: $(ARM_CLIENT_ID)
                    ARM_CLIENT_SECRET: $(ARM_CLIENT_SECRET)
                    ARM_SUBSCRIPTION_ID: $(ARM_SUBSCRIPTION_ID)
                    ARM_TENANT_ID: $(ARM_TENANT_ID)
                
                - task: AzureCLI@2
                  displayName: 'Terraform Apply (Production)'
                  inputs:
                    azureSubscription: 'Azure-DevOps-Connection-Prod'
                    scriptType: 'bash'
                    scriptLocation: 'inlineScript'
                    workingDirectory: '$(System.DefaultWorkingDirectory)/infra/envs/prod'
                    inlineScript: |
                      terraform apply -var-file="prod.tfvars" -auto-approve \
                        2>&1 | tee prod-apply-output.txt
                      
                      terraform output -json > prod-outputs.json
                      
                      echo "✅ PRODUCTION deployment completed"
                  env:
                    ARM_CLIENT_ID: $(ARM_CLIENT_ID)
                    ARM_CLIENT_SECRET: $(ARM_CLIENT_SECRET)
                    ARM_SUBSCRIPTION_ID: $(ARM_SUBSCRIPTION_ID)
                    ARM_TENANT_ID: $(ARM_TENANT_ID)
                
                # Seal audit log (immutable record)
                - task: Bash@3
                  displayName: '🔒 Audit: Seal Production Deployment Record'
                  condition: always()
                  inputs:
                    targetType: 'inline'
                    script: |
                      cat > audit-prod-final.json << EOF
                      {
                        "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
                        "event": "production_deployment_completed",
                        "environment": "production",
                        "pipeline_id": "$(Build.BuildId)",
                        "pipeline_run": "$(Build.BuildNumber)",
                        "approved_by": "$(Build.RequestedFor)",
                        "deployed_by": "Service Principal (sp-terraform-cicd-prod)",
                        "commit": "$(Build.SourceVersion)",
                        "commit_message": "$(Build.SourceVersionMessage)",
                        "status": "$(Agent.JobStatus)",
                        "audit_sealed": true,
                        "audit_hash": "$(echo $(Build.BuildId)-$(date +%s) | sha256sum)"
                      }
                      EOF
                      
                      echo "🔒 AUDIT LOG SEALED (Immutable Record)"
                      cat audit-prod-final.json
                      
                      # In production: Send to immutable audit log (Azure Monitor, etc.)
                
                # Notify stakeholders
                - task: Bash@3
                  displayName: '📧 Notify Stakeholders'
                  condition: always()
                  inputs:
                    targetType: 'inline'
                    script: |
                      echo "📧 Sending notifications..."
                      echo "To: Management, Security Team, Platform Team"
                      echo "Subject: PRODUCTION Deployment Completed"
                      echo "Status: $(Agent.JobStatus)"
                      echo "Approved by: $(Build.RequestedFor)"
                      echo "Pipeline: $(Build.BuildId)"
```

---

## 🎬 Real-World Scenarios

This plan includes **TWO types of scenarios** to demonstrate different aspects:

### Part A: Operational Efficiency Scenarios (Framework Value)
Shows how the framework makes infrastructure deployment faster, safer, and more collaborative:
1. **Scenario 1**: Deploy AKS Cluster - Full workflow from PR to production
2. **Scenario 2**: Add Cosmos DB Incrementally - Terraform only creates new resources
3. **Scenario 3**: New Team Adds Their App (Pattern 2) - Team independence, no conflicts
4. **Scenario 4**: Remove Resources Safely - Governance prevents data loss

### Part B: DevSecOps Security Scenarios (Security Value)
Shows how DevSecOps catches security issues and enforces governance:
1. **Security Scenario 1**: Secret Detection - Pipeline catches hardcoded credentials
2. **Security Scenario 2**: Approval Gates - Production requires management approval
3. **Security Scenario 3**: Unauthorized Access - RBAC blocks improper access

**Together, these scenarios demonstrate:** Fast deployment + Security + Governance = Modern infrastructure management

---

## 📋 PART A: Operational Efficiency Scenarios

### Operational Scenario 1: Deploy AKS Cluster (Initial Infrastructure)

**Goal:** Demonstrate complete workflow from development to production  
**Timeline:** 5 hours (vs 3 days without framework)  
**Teams:** Platform Team + E-commerce Team

---

#### Monday, 9:00 AM - Product Manager: "We need Kubernetes!"

```
Sarah (E-commerce Dev): We need to deploy our microservices on Kubernetes.
Alice (Manager): How long will it take?
Sarah: With the framework? About 5 hours including security reviews and testing.
Alice: Without the framework?
Tom (Platform): Last time it took 3 days - manual setup, security issues, configuration drift...
Alice: Perfect! Let's use the framework. Start the process.
```

---

#### 9:15 AM - Sarah: Reviews Framework Documentation

```bash
# Sarah opens STEP-BY-STEP-EXAMPLE.md
# Finds section: "Adding AKS Cluster"

# Step 1: Check what's already deployed
cd infra/envs/dev
terraform state list

# Output:
# azurerm_resource_group.main
# azurerm_virtual_network.main
# azurerm_subnet.aks
# azurerm_log_analytics_workspace.main
# (Landing Zone already exists! ✅)

# Step 2: Enable AKS in configuration
```

---

#### 9:30 AM - Sarah: Creates Branch & Enables AKS

```bash
git checkout -b feature/add-aks-cluster
```

**Edit:** `infra/envs/dev/dev.tfvars`

```hcl
# Enable AKS cluster
enable_aks = true

# AKS Configuration (dev environment - simple setup)
aks_config = {
  node_count          = 2
  vm_size            = "Standard_D2s_v3"
  enable_autoscaling = false
  min_nodes          = 2
  max_nodes          = 5
  
  # Dev settings (cost-optimized)
  enable_azure_policy        = false
  enable_private_cluster     = false
  enable_workload_identity   = true
}

# Tags
tags = {
  Environment = "dev"
  ManagedBy   = "Terraform"
  Team        = "E-commerce"
  CostCenter  = "Engineering"
}
```

**Commit:**
```bash
git add dev.tfvars
git commit -m "feat: enable AKS cluster for e-commerce microservices

- Enable AKS with 2 nodes (dev config)
- Use Standard_D2s_v3 (cost-optimized)
- Enable workload identity for pod authentication
- Estimated cost: $145/month

Justification: Deploy e-commerce microservices (cart, checkout, inventory)
Testing plan: Deploy sample app in dev, validate networking
"
git push origin feature/add-aks-cluster
```

---

#### 9:35 AM - Sarah: Creates Pull Request

```
PR #42: Add AKS Cluster for E-commerce Microservices

## Summary
Enable AKS cluster in dev environment for e-commerce team microservices deployment.

## Changes
- Enable AKS in dev.tfvars
- 2-node cluster with Standard_D2s_v3 VMs
- Workload identity enabled for secure pod authentication

## Cost Impact
Estimated: $145/month (within approved budget)

## Testing Plan
1. Deploy to dev (automatic)
2. Deploy sample nginx app
3. Validate networking (LoadBalancer service)
4. Test pod-to-Cosmos connectivity
5. Request production approval after 2 days testing

## Checklist
- [x] Cost estimate reviewed
- [x] Security requirements met
- [x] Monitoring plan documented
- [x] Rollback plan documented

cc: @tom-platform @alice-manager
```

---

#### 9:36 AM - 🔄 DevSecOps CI Pipeline Triggered

```
Pipeline: Terraform-DevSecOps-CI-42
Trigger: Pull Request #42
Branch: feature/add-aks-cluster

STAGE 1: Security Scanning
├── 🔍 Secret Scanning (GitLeaks)
│   └── ✅ PASSED: No secrets detected (2 seconds)
│
├── 🛡️ Infrastructure Security Scan (Checkov)
│   └── ✅ PASSED: 48/48 checks passed (45 seconds)
│       - AKS uses managed identity ✅
│       - Network policy available ✅
│       - RBAC enabled ✅
│       - Azure policy support ✅
│       - Encryption at rest ✅
│
├── 📋 Compliance Policy Validation
│   └── ✅ PASSED: All policies met (5 seconds)
│       - Required tags present ✅
│       - Naming convention: aks-ecom-dev ✅
│       - Region: eastus (allowed) ✅
│
└── 💰 Cost Estimation (Infracost)
    └── ✅ PASSED: $145/month (15 seconds)
        - 2x Standard_D2s_v3: $140/mo
        - Public IP: $3/mo
        - Load Balancer: $2/mo

Duration: 1 minute 7 seconds
Status: ✅ ALL CHECKS PASSED

STAGE 2: Terraform Validation
├── ✅ Format check passed
├── ✅ Configuration valid
└── ✅ Plan generated: +15 resources

📊 Terraform Plan Summary:
Plan: 15 to add, 0 to change, 0 to destroy

Resources to be created:
+ azurerm_kubernetes_cluster.main
+ azurerm_user_assigned_identity.aks
+ azurerm_role_assignment.aks_network
+ azurerm_role_assignment.aks_acr
... (11 more resources)

✅ PIPELINE SUCCESSFUL - Ready for Review
```

---

#### 9:40 AM - 🤖 Bot Comments on PR

```
## 🛡️ DevSecOps Pipeline Results

### ✅ Security Scan: PASSED
- ✅ No secrets detected
- ✅ Infrastructure security: 48/48 checks passed
- ✅ Compliance policies: All met

### 💰 Cost Estimate
Monthly cost: **$145** (within budget ✅)

<details>
<summary>Cost Breakdown</summary>

| Resource | Cost/Month |
|----------|-----------|
| AKS Control Plane | Free |
| 2x Standard_D2s_v3 VMs | $140 |
| Public IP | $3 |
| Load Balancer | $2 |
| **Total** | **$145** |

</details>

### 📋 Terraform Plan
Plan: **15 to add**, 0 to change, 0 to destroy

<details>
<summary>Resources to be created (click to expand)</summary>

- azurerm_kubernetes_cluster.main
- azurerm_user_assigned_identity.aks
- azurerm_role_assignment.aks_network (x4)
- azurerm_kubernetes_cluster_node_pool.system
- azurerm_monitor_diagnostic_setting.aks
- azurerm_log_analytics_solution.container_insights
(+ 7 more resources)

</details>

### 🎯 Next Steps
1. ✅ Review security scan results
2. ✅ Review cost estimate  
3. ✅ Review Terraform plan
4. ⏳ Approve PR (2 approvals required)
5. 🚀 Merge to deploy to dev

---
**Pipeline:** [View Full Results](#) | **Duration:** 1m 7s
```

---

#### 10:00 AM - Tom (Platform Team): Reviews PR

```
Tom commented:

Great work Sarah! A few observations:

✅ Security scans all passed
✅ Cost is within budget
✅ Proper tags applied
✅ Workload identity enabled (good choice!)

Suggestions for production:
- Enable private cluster (security)
- Enable Azure Policy (governance)
- Increase node count to 3 (availability)
- Enable autoscaling (elasticity)

But for dev, this looks perfect! 

Approved ✅ (1/2)
```

---

#### 10:15 AM - Alice (Manager): Reviews PR

```
Alice commented:

Thanks for the detailed PR description Sarah!

I can see:
- Clear justification (microservices deployment)
- Cost impact ($145/mo - approved)
- Testing plan documented
- Security validated

One question: What's the rollback plan if we need to remove this?

Please confirm, then I'll approve.
```

---

#### 10:20 AM - Sarah: Responds

```
Sarah replied:

Great question Alice!

Rollback plan:
1. Set `enable_aks = false` in dev.tfvars
2. Create PR (same process)
3. Terraform will destroy AKS cluster
4. Application data (in Cosmos DB) is UNAFFECTED
5. Total rollback time: ~20 minutes

Safety:
- AKS cluster is stateless (apps store data in Cosmos)
- Pod logs are in Log Analytics (retained 30 days)
- Container images are in ACR (not affected)

We can safely create/destroy AKS anytime!

Also documented in: docs/RUNBOOK-AKS.md
```

---

#### 10:25 AM - Alice: Approves

```
Alice commented:

Perfect! Thanks for the detailed rollback plan.

Approved ✅ (2/2)

Go ahead and merge!
```

---

#### 10:30 AM - Sarah: Merges PR

```
PR #42 merged into main
✅ 2 approvals received
✅ All checks passed
🚀 Triggering CD pipeline...
```

---

#### 10:31 AM - 🚀 DevSecOps CD Pipeline: Deploy to Dev

```
Pipeline: Terraform-DevSecOps-CD-67
Trigger: Merge to main (PR #42)
Environment: dev (automatic deployment)

STAGE: Audit Start
📊 Audit Record Created:
{
  "deployment_started": "2026-02-03T15:31:00Z",
  "triggered_by": "Sarah Jones",
  "commit": "a4f8e2b",
  "change": "Enable AKS cluster",
  "pipeline_id": "67"
}

STAGE: Deploy to Dev
├── 🔒 Pre-Deployment Security Check
│   └── ✅ Secrets loaded from Key Vault
│
├── ⚙️  Terraform Init
│   └── ✅ Backend initialized (secure state)
│
├── 🚀 Terraform Apply
│   ├── Creating AKS cluster... (12 minutes)
│   ├── Creating managed identity... (1 minute)
│   ├── Creating role assignments... (2 minutes)
│   ├── Configuring monitoring... (1 minute)
│   └── ✅ Apply complete! 15 resources added
│
└── 📊 Audit: Deployment Success
    └── ✅ Recorded at 2026-02-03T15:47:00Z

Duration: 17 minutes
Status: ✅ SUCCESS

Outputs:
- AKS cluster: aks-ecom-dev
- Resource group: rg-ecom-dev
- Kube config: Available via Azure CLI
```

---

#### 10:48 AM - 📧 Notification Sent

```
📧 To: Sarah, Tom, Alice, E-commerce Team

Subject: ✅ Dev Deployment Successful - AKS Cluster

The AKS cluster has been deployed to dev environment!

Cluster Details:
- Name: aks-ecom-dev
- Nodes: 2x Standard_D2s_v3
- Region: East US
- Cost: $145/month

Next Steps:
1. Connect to cluster: az aks get-credentials --name aks-ecom-dev --resource-group rg-ecom-dev
2. Deploy your applications
3. Test thoroughly (recommended: 2 days)
4. Request production deployment

Monitoring:
- Dashboard: [Azure Portal Link]
- Logs: [Log Analytics Link]

Questions? Contact Platform Team (#platform-team)
```

---

#### 11:00 AM - Sarah: Tests AKS Cluster

```bash
# Get credentials
az aks get-credentials --name aks-ecom-dev --resource-group rg-ecom-dev

# Verify connectivity
kubectl get nodes
# NAME                                STATUS   ROLE   AGE     VERSION
# aks-nodepool1-12345678-vmss000000  Ready    agent  10m     v1.27.7
# aks-nodepool1-12345678-vmss000001  Ready    agent  10m     v1.27.7

# Deploy test application
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --port=80 --type=LoadBalancer

# Wait for LoadBalancer IP
kubectl get svc nginx --watch
# nginx  LoadBalancer  10.0.0.10  20.12.34.56  80:30123/TCP  2m

# Test connectivity
curl http://20.12.34.56
# <html><body><h1>Welcome to nginx!</h1></body></html>

echo "✅ AKS cluster working perfectly!"
```

---

#### Day 2-3: Testing in Dev

```
Sarah's team deploys and tests:
- Cart microservice ✅
- Checkout microservice ✅
- Inventory microservice ✅
- Inter-service communication ✅
- Connection to Cosmos DB ✅
- Log Analytics monitoring ✅

All tests passed! Ready for production.
```

---

#### Day 3, 2:00 PM - Sarah: Request Production Deployment

```
Sarah creates comment in original PR:

---
## 🏭 Production Deployment Request

Dev testing completed successfully! Ready for production deployment.

**Testing Summary (2 days):**
- ✅ All 3 microservices deployed and running
- ✅ LoadBalancer working (external traffic)
- ✅ Pod-to-Cosmos connectivity validated
- ✅ Monitoring and alerting verified
- ✅ No issues or errors

**Production Configuration:**
Will use `prod.tfvars` with:
- Node count: 3 (high availability)
- Enable private cluster: true (security)
- Enable Azure Policy: true (governance)
- Enable autoscaling: 3-10 nodes (elasticity)

**Cost Estimate:** $320/month (approved budget)

**Rollback Plan:** Same as dev (set enable_aks = false)

**On-call:** Tom (Platform) + Sarah (E-commerce) - PagerDuty configured

Requesting production approval from @alice-manager

cc: @tom-platform
```

---

#### 2:30 PM - Alice: Reviews Production Request

```
Alice reviews:
- Dev testing: 2 days (thorough ✅)
- All tests passed ✅
- Production config reviewed ✅
- Cost within budget ✅
- Rollback plan documented ✅
- On-call assigned ✅

Alice: Approved for production deployment! ✅

Tom, please proceed with production deployment when ready.
```

---

#### 3:00 PM - Tom: Triggers Production Deployment

```bash
# Tom updates prod.tfvars
cd infra/envs/prod

# Edit prod.tfvars (same changes as dev, but prod settings)
enable_aks = true
aks_config = {
  node_count          = 3  # HA
  vm_size            = "Standard_D4s_v3"  # More powerful
  enable_autoscaling = true
  min_nodes          = 3
  max_nodes          = 10
  
  # Prod settings (security-focused)
  enable_azure_policy        = true
  enable_private_cluster     = true
  enable_workload_identity   = true
}

git add prod.tfvars
git commit -m "feat: enable AKS cluster in production"
git push
```

---

#### 3:05 PM - 🏭 Production CD Pipeline: Approval Gate

```
Pipeline: Terraform-DevSecOps-CD-68
Environment: production
Status: ⏸️  WAITING FOR APPROVAL

Approval Required From:
- Tom (Platform Lead) ⏳
- Alice (Manager) ⏳

Approval Context:
- Dev testing: 2 days (successful)
- Security scans: All passed
- Cost estimate: $320/month
- Risk level: Medium (new infrastructure)

Pipeline will wait up to 24 hours for approval...
```

---

#### 3:10 PM - Tom: Approves Production

```
Tom reviews approval request:

✅ Dev testing successful (2 days)
✅ Security scans passed
✅ Prod configuration reviewed
✅ More secure than dev (private cluster, policies)
✅ Cost approved by management
✅ Rollback plan documented

Tom: Approved ✅ (1/2)

Waiting for Alice's approval...
```

---

#### 3:15 PM - Alice: Approves Production

```
Alice reviews:

All requirements met for production deployment.
Dev testing was thorough.
Team is prepared for production support.

Alice: Approved ✅ (2/2)

Proceeding with production deployment...
```

---

#### 3:16 PM - 🚀 Production Deployment Starts

```
Pipeline: Terraform-DevSecOps-CD-68
Status: 🚀 DEPLOYING TO PRODUCTION

AUDIT LOG (SEALED):
{
  "event": "production_deployment_started",
  "timestamp": "2026-02-03T20:16:00Z",
  "approved_by": ["Tom (Platform)", "Alice (Manager)"],
  "deployed_by": "Service Principal (sp-terraform-cicd-prod)",
  "commit": "b7e9f3c",
  "security_validated": true,
  "audit_sealed": true
}

Terraform Apply (Production):
├── Creating AKS cluster (private)... (15 minutes)
├── Creating managed identity... (1 minute)
├── Configuring Azure Policy... (2 minutes)
├── Configuring monitoring... (1 minute)
└── ✅ Apply complete! 18 resources added

Duration: 20 minutes
Status: ✅ PRODUCTION DEPLOYMENT SUCCESSFUL

AUDIT LOG (SEALED):
{
  "event": "production_deployment_completed",
  "timestamp": "2026-02-03T20:36:00Z",
  "status": "success",
  "resources_created": 18,
  "cost_actual": "$320/month",
  "audit_sealed": true,
  "audit_hash": "sha256:abc123..."
}
```

---

#### 3:40 PM - 📧 Production Deployment Notification

```
📧 To: Management, Platform Team, E-commerce Team

Subject: ✅ PRODUCTION Deployment Successful - AKS Cluster

Production AKS cluster deployed successfully!

Cluster: aks-ecom-prod
Nodes: 3x Standard_D4s_v3 (autoscale 3-10)
Region: East US
Security: Private cluster, Azure Policy enabled
Cost: $320/month

Deployed by: Tom (Platform)
Approved by: Tom, Alice
Duration: 20 minutes

Next Steps:
- Deploy production applications
- Configure production DNS
- Enable production monitoring alerts

Monitoring: [Dashboard] | Audit Log: [Link]
```

---

#### 4:00 PM - Sarah: Deploys Production Apps

```bash
# Connect to production cluster
az aks get-credentials --name aks-ecom-prod --resource-group rg-ecom-prod

# Deploy production microservices
kubectl apply -f k8s/production/

# Verify deployments
kubectl get pods
# All pods running! ✅

echo "✅ Production deployment complete!"
```

---

### Operational Scenario 1: Key Results

**Timeline:**
- **Day 1, 9:00 AM**: Requirement identified
- **Day 1, 10:30 AM**: Deployed to dev (1.5 hours)
- **Day 1-3**: Testing in dev (2 days)
- **Day 3, 3:40 PM**: Deployed to production (35 minutes)

**Total Time: 5 hours of actual work** (vs 3 days manually)

**What Happened:**
1. ✅ Developer enabled AKS in configuration
2. ✅ Automated security scanning caught issues
3. ✅ Team reviewed and approved
4. ✅ Automatically deployed to dev
5. ✅ Tested for 2 days
6. ✅ Management approved production
7. ✅ Automatically deployed to production
8. ✅ Complete audit trail recorded

**Security:**
- ✅ No secrets in code
- ✅ Security scans passed
- ✅ Compliance validated
- ✅ Approvals recorded
- ✅ Audit log sealed

**Benefits vs Manual Deployment:**
| Aspect | Manual (Old Way) | Framework (New Way) | Improvement |
|--------|------------------|---------------------|-------------|
| Time to dev | 1 day (manual setup) | 1.5 hours (automated) | 83% faster |
| Security scanning | Manual (days) | Automatic (2 min) | 99% faster |
| Approval process | Email chains | Automated gates | 100% traceable |
| Deployment errors | 40% failure rate | 5% failure rate | 87% improvement |
| Audit trail | Incomplete | Complete | 100% coverage |
| Cost visibility | Unknown upfront | Pre-estimated | Full transparency |
| Time to production | 3 days total | 5 hours total | 85% faster |

---

### Operational Scenario 2: Add Cosmos DB (Incremental Change)

**Goal:** Demonstrate Terraform's incremental capability - only creates NEW resources  
**Timeline:** 30 minutes  
**Key Learning:** Terraform doesn't re-deploy existing infrastructure!

---

#### Week 2, Monday 10:00 AM - Sarah: "We Need a Database"

```
Sarah (E-commerce): Our microservices need a database for product catalog.
Tom (Platform): Easy! Let's add Cosmos DB. It'll be incremental - won't touch your AKS cluster.
Sarah: Wait, incremental? What does that mean?
Tom: Terraform will ONLY create the database. Your AKS cluster stays untouched!
Sarah: Oh! So we're not re-deploying everything?
Tom: Exactly! That's the beauty of Terraform. Let me show you...
```

---

#### 10:15 AM - Sarah: Enables Cosmos DB

```bash
git checkout -b feature/add-cosmosdb
```

**Edit:** `infra/envs/dev/dev.tfvars`

```hcl
# AKS (already enabled - UNCHANGED)
enable_aks = true
aks_config = {
  node_count = 2
  vm_size   = "Standard_D2s_v3"
  # ... (existing config)
}

# NEW: Enable Cosmos DB
enable_cosmosdb = true  # ← Only this changed!

cosmosdb_config = {
  database_name     = "ecommerce"
  consistency_level = "Session"
  
  # Dev settings
  enable_free_tier           = true  # $0/month for dev!
  enable_automatic_failover  = false
  enable_multi_region_writes = false
  
  # Collections
  containers = [
    {
      name               = "products"
      partition_key_path = "/category"
      throughput         = 400  # RU/s (minimal for dev)
    },
    {
      name               = "orders"
      partition_key_path = "/userId"
      throughput         = 400
    }
  ]
}
```

**Commit:**
```bash
git add dev.tfvars
git commit -m "feat: add Cosmos DB for product catalog and orders

- Enable Cosmos DB with free tier (dev)
- Create 'products' container (partitioned by /category)
- Create 'orders' container (partitioned by /userId)
- Cost: $0/month (free tier)

Note: AKS cluster unchanged - incremental deployment only!
"
git push origin feature/add-cosmosdb
```

---

#### 10:20 AM - Sarah: Creates Pull Request

```
PR #45: Add Cosmos DB for E-commerce Data

## Summary
Add Cosmos DB to store product catalog and order data.

## Changes
- Enable Cosmos DB in dev.tfvars
- Create 2 containers: products, orders
- Use free tier (dev cost: $0)

## Impact
- **AKS cluster**: UNCHANGED ✅
- **Networking**: UNCHANGED ✅
- **New resources**: Only Cosmos DB + containers

Terraform will only create new resources!

## Testing Plan
1. Deploy to dev (automatic)
2. Verify containers created
3. Test connectivity from AKS pods
4. Load sample data
5. Request production approval

Cost: $0/month (dev free tier)

cc: @tom-platform @alice-manager
```

---

#### 10:21 AM - 🔄 DevSecOps CI Pipeline

```
Pipeline: Terraform-DevSecOps-CI-45

STAGE 1: Security Scanning
├── ✅ No secrets detected
├── ✅ Infrastructure security: All passed
│   - Cosmos DB encryption enabled ✅
│   - Network rules configured ✅
│   - Firewall enabled ✅
└── ✅ Compliance: All policies met

STAGE 2: Terraform Validation
├── ✅ Format check passed
├── ✅ Configuration valid
└── ✅ Plan generated

📊 Terraform Plan Summary:
Plan: 8 to add, 0 to change, 0 to destroy

✨ KEY INSIGHT: Only NEW resources!
- azurerm_cosmosdb_account.main
- azurerm_cosmosdb_sql_database.main
- azurerm_cosmosdb_sql_container.products
- azurerm_cosmosdb_sql_container.orders
- azurerm_private_endpoint.cosmosdb
- azurerm_role_assignment.aks_to_cosmosdb
(+ 2 more networking resources)

❌ NO CHANGES to existing resources:
- AKS cluster: UNTOUCHED ✅
- VNet/Subnets: UNTOUCHED ✅
- Log Analytics: UNTOUCHED ✅
- (All 15 existing resources unchanged!)

💰 Cost Estimate:
Dev: $0/month (free tier)
Prod: $24/month (400 RU/s per container)

✅ PIPELINE PASSED
```

---

#### 10:25 AM - 🤖 Bot Comments on PR

```
## 🛡️ DevSecOps Pipeline Results

### ✅ All Checks Passed

### 📊 Terraform Plan - INCREMENTAL DEPLOYMENT
**Plan: 8 to add, 0 to change, 0 to destroy**

🎯 **This is an incremental change!**

**New Resources (will be created):**
- ✨ Cosmos DB account
- ✨ Database: ecommerce
- ✨ Container: products
- ✨ Container: orders
- ✨ Private endpoint
- ✨ Role assignment (AKS → Cosmos)

**Existing Resources (unchanged):**
- ✅ AKS cluster (15 resources) - NO CHANGES
- ✅ Networking - NO CHANGES
- ✅ Monitoring - NO CHANGES

**Your AKS cluster will NOT be redeployed!** 🎉

💰 **Cost Impact:**
- Dev: $0/month (free tier enabled)
- Prod: +$24/month (estimated)

---
Ready for review and approval!
```

---

#### 10:30 AM - Tom: Reviews & Explains

```
Tom commented:

Perfect example of incremental deployment! 🎯

Sarah, notice the Terraform plan:
- **8 to add** ← New Cosmos DB resources
- **0 to change** ← AKS cluster untouched!
- **0 to destroy** ← Nothing removed

This is why Terraform is powerful:
- Your AKS cluster keeps running
- Pods don't restart
- No downtime
- Only new database is created

In the old manual world, we'd often:
- Re-deploy everything (risky!)
- Cause unnecessary downtime
- Risk breaking working systems

With Terraform:
- Surgical precision ✅
- Only what changed ✅
- Everything else stable ✅

Approved ✅

Great job using free tier for dev!
```

---

#### 10:45 AM - Alice: Approves

```
Alice commented:

Love seeing $0 cost for dev! 

Approved ✅

Let's see this incremental deployment in action!
```

---

#### 10:50 AM - Sarah: Merges PR

```
PR #45 merged → CD pipeline triggered
```

---

#### 10:52 AM - 🚀 CD Pipeline: Dev Deployment

```
Pipeline: Terraform-DevSecOps-CD-70
Environment: dev

Terraform Apply (watch what happens!):

📋 Reading existing state...
✅ Found 15 existing resources (AKS cluster, networking, etc.)

📋 Planning changes...
✅ Plan: 8 new resources (Cosmos DB)

🎬 Applying changes...

⏭️  Skipping: azurerm_kubernetes_cluster.main (unchanged)
⏭️  Skipping: azurerm_virtual_network.main (unchanged)
⏭️  Skipping: azurerm_subnet.aks (unchanged)
⏭️  Skipping: ... (all 15 AKS resources skipped!)

✨ Creating: azurerm_cosmosdb_account.main... (3 minutes)
✨ Creating: azurerm_cosmosdb_sql_database.ecommerce... (30 seconds)
✨ Creating: azurerm_cosmosdb_sql_container.products... (20 seconds)
✨ Creating: azurerm_cosmosdb_sql_container.orders... (20 seconds)
✨ Creating: azurerm_private_endpoint.cosmosdb... (1 minute)
✨ Creating: azurerm_role_assignment.aks_to_cosmosdb... (10 seconds)

✅ Apply complete!
- 8 resources added
- 0 resources changed  ← AKS UNTOUCHED!
- 0 resources destroyed
- 15 resources unchanged

Duration: 5 minutes 30 seconds

Outputs:
cosmosdb_endpoint: cosmos-ecom-dev.documents.azure.com
cosmosdb_connection_string: (stored in Key Vault)
```

---

#### 11:00 AM - Sarah: Verifies (Mind Blown 🤯)

```bash
# Check Terraform state
terraform state list

# Output shows ALL resources:
# (15 existing AKS resources - untouched)
azurerm_kubernetes_cluster.main
azurerm_virtual_network.main
... (AKS resources)

# (8 new Cosmos DB resources - just created)
azurerm_cosmosdb_account.main
azurerm_cosmosdb_sql_database.ecommerce
azurerm_cosmosdb_sql_container.products
azurerm_cosmosdb_sql_container.orders
...

# Check AKS cluster (still running!)
kubectl get pods
# NAME                          READY   STATUS    RESTARTS   AGE
# cart-service-xxx              1/1     Running   0          2d  ← Still running!
# checkout-service-xxx          1/1     Running   0          2d  ← No restart!
# inventory-service-xxx         1/1     Running   0          2d  ← Unchanged!

Sarah: "Wait... my pods didn't restart?!"
Tom: "Exactly! Terraform only touched Cosmos DB. AKS is completely unchanged."
Sarah: "🤯 This is amazing! No downtime!"

# Verify Cosmos DB created
az cosmosdb show --name cosmos-ecom-dev --resource-group rg-ecom-dev

# Output: Database exists!
# Free tier enabled ✅
# Containers created ✅

Sarah: "This is SO much better than manual deployments!"
```

---

#### 11:15 AM - Sarah: Tests Connectivity

```bash
# Deploy test pod with Cosmos SDK
kubectl run cosmos-test --image=mcr.microsoft.com/azure-cosmos/cosmosdb:latest --rm -it -- bash

# Inside pod: Test connection
az cosmosdb sql container show \
  --account-name cosmos-ecom-dev \
  --database-name ecommerce \
  --name products

# Connection successful! ✅

# Insert test document
{
  "id": "test-product-001",
  "category": "electronics",
  "name": "Laptop",
  "price": 999.99
}

# Query test
SELECT * FROM products WHERE category = 'electronics'
# Returns test document ✅

Sarah: "Everything working! AKS pods can connect to Cosmos!"
```

---

### Operational Scenario 2: Key Results

**Timeline: 30 minutes** (from PR to deployed and tested!)

**What Terraform Did:**
- ✅ Read existing state (15 AKS resources)
- ✅ Compared with new configuration
- ✅ Identified 8 new resources needed
- ✅ Created ONLY new resources
- ✅ Left existing resources completely untouched

**What Terraform Did NOT Do:**
- ❌ Did NOT re-deploy AKS
- ❌ Did NOT restart pods
- ❌ Did NOT touch networking
- ❌ Did NOT cause any downtime

**The Magic of Declarative Infrastructure:**
```
You declare the DESIRED STATE:
- I want AKS + Cosmos DB

Terraform figures out:
- AKS exists ✅ (do nothing)
- Cosmos missing ❌ (create it)

Result: Only creates what's needed!
```

**Benefits:**
| Aspect | Manual Deployment | Terraform (Framework) | Improvement |
|--------|-------------------|----------------------|-------------|
| Deployment scope | Everything (risky) | Only changes | 100% surgical |
| Downtime | 30-60 min | 0 minutes | Zero downtime |
| Risk | High (touch everything) | Low (only new) | 90% less risk |
| Time | 2-3 hours | 30 minutes | 75% faster |
| Confidence | Low (fingers crossed) | High (plan previewed) | Stress-free |

---

### Operational Scenario 3: New Team Adds Their App (Pattern 2)

**Goal:** Demonstrate Pattern 2 (Delegated) - multiple teams work independently  
**Timeline:** 2 hours  
**Key Learning:** Teams don't conflict, framework enables self-service

---

#### Week 3, Monday 9:00 AM - New Team Arrives!

```
Mark (CRM Team Lead): We're the new CRM team! We need infrastructure for our app.

Sarah (E-commerce): Oh no... will you affect our AKS cluster?

Tom (Platform): Not at all! You'll use Pattern 2 - completely isolated.

Mark: Pattern 2?

Tom: You get your own Terraform workspace, your own state file, your own resources.
      You can deploy anytime without affecting Sarah's team!

Sarah: Really? Last year, teams kept breaking each other's stuff...

Tom: Not anymore! Let me show you Pattern 2.
```

---

#### 9:30 AM - Tom: Explains Pattern 2 to CRM Team

```
Tom (whiteboard session):

PATTERN 1 (Centralized):
├── Platform team controls everything
├── All teams request via tickets
├── Single state file
└── Slower but more controlled

PATTERN 2 (Delegated): ← You'll use this!
├── Each app team has own workspace
├── Own state file (no conflicts!)
├── Use shared Landing Zone
├── Deploy independently
└── Platform team provides modules

Your folder structure:
infra/
├── global/           ← Shared (platform team)
├── envs/
│   └── dev/          ← Shared Landing Zone (platform team)
└── ...

examples/pattern-2-delegated/
├── dev-app-crm/      ← YOUR folder (CRM team)
│   ├── main.tf
│   ├── backend.tf    ← Your own state file!
│   └── terraform.tfvars
└── dev-app-ecommerce/   ← Sarah's folder (separate!)

Benefits:
- You can't break Sarah's infrastructure ✅
- Sarah can't break yours ✅
- Deploy anytime (no coordination) ✅
- Full git history for your team ✅
- Use same proven modules ✅
```

---

#### 10:00 AM - Mark: Sets Up CRM Infrastructure

```bash
# Copy Pattern 2 template
cp -r examples/pattern-2-delegated/template examples/pattern-2-delegated/dev-app-crm

cd examples/pattern-2-delegated/dev-app-crm
```

**Create:** `terraform.tfvars`

```hcl
# CRM Team Configuration
app_name    = "crm"
environment = "dev"
team_name   = "CRM"

# Backend Configuration (SEPARATE state file!)
backend_resource_group  = "rg-terraform-state-security"
backend_storage_account = "stterraformstate001"
backend_container       = "tfstate"
backend_key            = "apps/crm/dev.tfstate"  # ← CRM's own state!

# Landing Zone (shared with e-commerce)
landing_zone_vnet_id        = "/subscriptions/.../virtualNetworks/vnet-main-dev"
landing_zone_subnet_id      = "/subscriptions/.../subnets/subnet-apps-dev"
landing_zone_log_analytics  = "/subscriptions/.../workspaces/log-analytics-dev"

# CRM Application Resources
enable_app_service = true
app_service_config = {
  sku_name = "P1v2"
  always_on = true
}

enable_cosmosdb = true
cosmosdb_config = {
  database_name = "crm"
  consistency_level = "Session"
  
  containers = [
    {
      name = "customers"
      partition_key_path = "/companyId"
      throughput = 400
    },
    {
      name = "contacts"
      partition_key_path = "/customerId"
      throughput = 400
    }
  ]
}

# Tags
tags = {
  Team        = "CRM"
  Application = "CRM-System"
  CostCenter  = "Sales"
  ManagedBy   = "Terraform"
}
```

---

#### 10:30 AM - Mark: Verifies Isolation

```bash
# Check backend configuration
cat backend.tf

# Output:
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state-security"
    storage_account_name = "stterraformstate001"
    container_name       = "tfstate"
    key                  = "apps/crm/dev.tfstate"  # ← SEPARATE from e-commerce!
  }
}

# Compare with e-commerce team's state:
# E-commerce: tfstate/apps/ecommerce/dev.tfstate
# CRM:        tfstate/apps/crm/dev.tfstate
# ← DIFFERENT FILES! ✅ No conflicts possible!

Mark: "So we literally can't affect Sarah's infrastructure?"
Tom: "Correct! Different state files = complete isolation."
```

---

#### 10:45 AM - Mark: Commits CRM Infrastructure

```bash
git checkout -b feature/crm-infrastructure
git add .
git commit -m "feat: add CRM team infrastructure (Pattern 2)

Pattern 2 (Delegated) deployment:
- Separate state file: apps/crm/dev.tfstate
- Uses shared Landing Zone (networking, monitoring)
- CRM-specific resources: App Service + Cosmos DB

Resources:
- App Service (P1v2 plan)
- Cosmos DB (2 containers: customers, contacts)
- Private endpoints
- Managed identity

Cost: $145/month
Team: CRM
Pattern: 2 (Delegated/Self-Service)
"
git push origin feature/crm-infrastructure
```

---

#### 10:50 AM - Mark: Creates Pull Request

```
PR #48: CRM Team Infrastructure (Pattern 2)

## Summary
CRM team setting up infrastructure using Pattern 2 (Delegated).

## Pattern 2 Benefits
- ✅ Separate state file (apps/crm/dev.tfstate)
- ✅ No impact on e-commerce team
- ✅ Use shared Landing Zone (networking, monitoring)
- ✅ Self-service deployment

## Resources
- App Service (P1v2) for CRM app
- Cosmos DB for customer data
- 2 containers: customers, contacts

## Cost
$145/month (within approved budget)

## Independence Verification
- State file: apps/crm/dev.tfstate (separate! ✅)
- E-commerce state: apps/ecommerce/dev.tfstate (unaffected! ✅)
- Shared: Landing Zone only (VNet, Log Analytics)

cc: @tom-platform @alice-manager @sarah-ecommerce
```

---

#### 11:00 AM - 🔄 DevSecOps CI Pipeline

```
Pipeline: Terraform-DevSecOps-CI-48

SECURITY SCANNING:
✅ All security checks passed

TERRAFORM VALIDATION:
✅ Format, validate, plan successful

📊 Terraform Plan Summary:
Plan: 12 to add, 0 to change, 0 to destroy

Resources to create (CRM team):
- azurerm_app_service_plan.main
- azurerm_linux_web_app.main
- azurerm_cosmosdb_account.crm
- azurerm_cosmosdb_sql_database.crm
- azurerm_cosmosdb_sql_container.customers
- azurerm_cosmosdb_sql_container.contacts
... (6 more resources)

🎯 ISOLATION VERIFIED:
- CRM state: apps/crm/dev.tfstate ✅
- E-commerce state: apps/ecommerce/dev.tfstate ✅
- Landing Zone: shared (read-only) ✅

✅ No conflicts with e-commerce team!
✅ No changes to existing infrastructure!

💰 Cost: $145/month

✅ PIPELINE PASSED
```

---

#### 11:10 AM - Tom & Sarah: Review PR

```
Tom commented:

Perfect use of Pattern 2! 🎯

Verified:
- ✅ Separate state file (no conflicts)
- ✅ Uses shared Landing Zone correctly
- ✅ Proper tagging (Team=CRM)
- ✅ Security scans passed
- ✅ Cost within budget

This is exactly how team independence should work!

Approved ✅

---

Sarah commented:

I checked - this won't affect our AKS cluster or Cosmos DB at all! ✅

Different state file = complete isolation.

Welcome to the framework, CRM team! 🎉

Approved ✅
```

---

#### 11:20 AM - Alice: Approves

```
Alice commented:

Love seeing teams work independently! 

Two teams, two deployments, zero conflicts. 
This is the collaboration model we need.

Approved ✅
```

---

#### 11:25 AM - Mark: Merges PR

```
PR #48 merged → CD pipeline triggered
```

---

#### 11:27 AM - 🚀 CD Pipeline: Deploy CRM Infrastructure

```
Pipeline: Terraform-DevSecOps-CD-72
Team: CRM
State File: apps/crm/dev.tfstate

Terraform Apply:

📋 Initializing backend...
✅ Backend: apps/crm/dev.tfstate (CRM team's state)
✅ No existing resources (first deployment!)

📋 Planning...
✅ Plan: 12 new resources

🎬 Applying...

Reading shared resources:
✅ VNet: vnet-main-dev (from Landing Zone) - read-only
✅ Subnet: subnet-apps-dev (from Landing Zone) - read-only
✅ Log Analytics: (from Landing Zone) - read-only

Creating CRM resources:
✨ Creating App Service Plan... (2 minutes)
✨ Creating App Service... (3 minutes)
✨ Creating Cosmos DB... (4 minutes)
✨ Creating customer container... (30 seconds)
✨ Creating contacts container... (30 seconds)
✨ Creating private endpoints... (2 minutes)

✅ Apply complete!
- 12 resources created
- 3 shared resources used (read-only)

Duration: 12 minutes

CRM infrastructure deployed! ✅
```

---

#### 11:40 AM - Meanwhile... Sarah Deploys E-commerce Update!

```
AT THE SAME TIME:

Sarah (e-commerce team): "I need to update our AKS node count."

Sarah makes change in: infra/envs/dev/dev.tfvars
aks_node_count = 3  # increased from 2

Creates PR #49, gets approval, merges...

🚀 E-commerce CD Pipeline Running:
State File: apps/ecommerce/dev.tfstate

Terraform Apply:
✅ Backend: apps/ecommerce/dev.tfstate
✅ Reading existing resources (23 resources)

🎬 Applying:
✨ Modifying: azurerm_kubernetes_cluster.main (add 1 node)

✅ Apply complete!
- 1 resource modified (AKS)
- 22 resources unchanged

Duration: 8 minutes

---

🎯 RESULT: Both teams deployed simultaneously!

CRM team: Creating their infrastructure ✅
E-commerce team: Updating AKS ✅
No conflicts! ✅
No coordination needed! ✅

Different state files = Complete independence!
```

---

#### 11:45 AM - Tom: Celebrates Success

```
Tom (in #platform-team):

🎉 BIG WIN TODAY!

Two teams just deployed SIMULTANEOUSLY:
- CRM team: New infrastructure (12 resources)
- E-commerce team: AKS update (1 modification)

Timeline:
- CRM deploy: 11:27 AM - 11:39 AM (12 min)
- E-commerce deploy: 11:35 AM - 11:43 AM (8 min)
- Overlap: 4 minutes

Result:
✅ Zero conflicts
✅ Zero coordination needed
✅ Zero delays
✅ Zero errors

This is Pattern 2 working PERFECTLY!

Last year this would have required:
- 3 days of planning
- Coordination meetings
- Risk of conflicts
- Manual rollback plans

Today:
- 20 minutes total
- No meetings
- No conflicts
- Automatic safety

THIS is why we built the framework! 🚀
```

---

#### 12:00 PM - Mark & Sarah: Compare Notes

```
Slack conversation:

Mark (CRM): "Wait, were you deploying at the same time as us?"

Sarah (E-commerce): "Yeah! I updated AKS from 2 to 3 nodes."

Mark: "Did we conflict with each other?!"

Sarah: "Not at all! Different state files = complete isolation."

Mark: "🤯 At my last company, we had to schedule deployments weeks in advance!"

Sarah: "Same! We'd have 'deployment windows' and coordination meetings..."

Tom (Platform): "That's the OLD way. 
                 With Pattern 2 and proper state isolation, teams are independent!"

Mark: "I'm loving this framework already!"

Sarah: "Welcome to the team! Let me know if you need help. 
        Oh wait - you don't need help! You're self-service now! 😄"

Mark: "😂 True! But I'll still ask questions!"
```

---

### Operational Scenario 3: Key Results

**Timeline: 2 hours** (from onboarding to deployed)

**What Pattern 2 Enabled:**
- ✅ CRM team self-service (no platform team bottleneck)
- ✅ Separate state files (complete isolation)
- ✅ Shared Landing Zone (networking, monitoring)
- ✅ Simultaneous deployments (no conflicts)
- ✅ Full git history per team
- ✅ Independent lifecycle management

**Team Independence:**
| Aspect | Centralized (Pattern 1) | Delegated (Pattern 2) | Improvement |
|--------|-------------------------|----------------------|-------------|
| Deployment speed | 2-3 days (tickets) | 2 hours (self-service) | 90% faster |
| Coordination | Required (meetings) | None (isolated) | Zero overhead |
| Conflicts | Frequent (shared state) | Impossible (separate) | 100% eliminated |
| Autonomy | Low (wait for platform) | High (own deployments) | Full control |
| Risk | High (affect others) | Low (isolated blast radius) | 90% safer |

**Simultaneous Deployment Proof:**
```
11:27 - 11:39: CRM deploying (12 min)
11:35 - 11:43: E-commerce deploying (8 min)
         ^^^^
         4 minutes overlap!

Result: Both successful, zero conflicts! ✅
```

---

### Operational Scenario 4: Remove Resources (Safety Demo)

**Goal:** Demonstrate governance prevents accidental data loss  
**Timeline:** 15 minutes  
**Key Learning:** Framework protects you from mistakes!

---

#### Week 4, Friday 3:00 PM - Sarah: "Let's Clean Up Test Resources"

```
Sarah (e-commerce): "We have a test Cosmos DB container we don't need anymore.
                     Let me just remove it..."

Sarah opens dev.tfvars:

cosmosdb_config = {
  database_name = "ecommerce"
  
  containers = [
    {
      name = "products"
      partition_key_path = "/category"
      throughput = 400
    },
    {
      name = "orders"       # ← DELETE THIS
      partition_key_path = "/userId"
      throughput = 400
    },
    {
      name = "test-data"    # ← Just a test container
      partition_key_path = "/id"
      throughput = 400
    }
  ]
}

Sarah: "Let me remove 'orders' and 'test-data'..."
```

---

#### 3:05 PM - Sarah: Creates PR to Remove Containers

```bash
git checkout -b cleanup/remove-test-containers

# Edit dev.tfvars - removes orders and test-data containers
vim dev.tfvars

git add dev.tfvars
git commit -m "cleanup: remove unused Cosmos DB containers

Removing:
- test-data (no longer needed)
- orders (oops, actually we DO need this!)
"

git push origin cleanup/remove-test-containers
```

**PR #52: Cleanup Unused Cosmos DB Containers**

---

#### 3:07 PM - 🔄 DevSecOps CI Pipeline

```
Pipeline: Terraform-DevSecOps-CI-52

SECURITY SCANNING:
✅ Passed

TERRAFORM VALIDATION:
✅ Format, validate passed

📊 Terraform Plan:

Plan: 0 to add, 0 to change, 2 to destroy

🚨 Resources to be DESTROYED:
- azurerm_cosmosdb_sql_container.orders    # ← PRODUCTION DATA!
- azurerm_cosmosdb_sql_container.test-data # ← Test data (OK to delete)

⚠️  WARNING: Destructive changes detected!

Review carefully:
- 'orders' container has PRODUCTION data!
- 12,450 documents will be DELETED
- This action is IRREVERSIBLE

✅ Pipeline passed (but review destruction carefully!)
```

---

#### 3:08 PM - 🤖 Bot Comments with WARNING

```
## 🛡️ DevSecOps Pipeline Results

### ⚠️  DESTRUCTIVE CHANGES DETECTED!

**Plan: 0 to add, 0 to change, 2 to destroy**

### 🚨 Resources to be DESTROYED:

1. **azurerm_cosmosdb_sql_container.orders**
   - ⚠️  Contains 12,450 documents
   - ⚠️  PRODUCTION DATA
   - ⚠️  IRREVERSIBLE deletion!

2. **azurerm_cosmosdb_sql_container.test-data**
   - Contains 15 documents
   - Test data (safe to delete)

---

### ⚠️  REQUIRED ACTIONS:

Before approving this PR:

1. **Verify 'orders' container should be deleted**
   - Does it contain production data? (YES! ⚠️ )
   - Is there a backup? 
   - Is this intentional?

2. **Consider backup strategy**
   - Export data before deletion
   - Verify backup exists
   - Document deletion reason

3. **Notify stakeholders**
   - Alert teams using this data
   - Confirm no active dependencies

---

### 🛡️ SAFETY CHECKS:

- [ ] Verified 'orders' container is not needed
- [ ] Backup created (if needed)
- [ ] Stakeholders notified
- [ ] Manager approved data deletion

⚠️  **Destructive changes require extra scrutiny!**

---
[View Full Pipeline Results](#)
```

---

#### 3:10 PM - Tom (Platform): Reviews & ALERTS!

```
Tom commented:

🚨 WAIT! STOP! 🚨

Sarah, you're about to delete the ORDERS container!

I just checked - this container has:
- 12,450 customer orders
- $1.2M in order value
- PRODUCTION data being actively used!

This would be catastrophic! 😱

Questions:
1. Why are you deleting 'orders'?
2. Did you mean to only delete 'test-data'?
3. Was this a mistake?

**DO NOT MERGE THIS PR!** 

Please clarify intent before proceeding.

@sarah-ecommerce @alice-manager
```

---

#### 3:12 PM - Sarah: "OH NO! 😱"

```
Sarah responded:

OH MY GOD! 😱

I meant to ONLY delete 'test-data'!

I accidentally removed 'orders' too when editing the file!

Thank you for catching this Tom! This would have been a disaster!

Let me fix the PR immediately!
```

---

#### 3:15 PM - Sarah: Fixes the PR

```bash
# Fix the configuration - KEEP orders container!
vim dev.tfvars

cosmosdb_config = {
  database_name = "ecommerce"
  
  containers = [
    {
      name = "products"
      partition_key_path = "/category"
      throughput = 400
    },
    {
      name = "orders"       # ← KEEP THIS! (restored)
      partition_key_path = "/userId"
      throughput = 400
    }
    # test-data removed (intentional)
  ]
}

git add dev.tfvars
git commit -m "fix: restore 'orders' container - MUST NOT DELETE

Fixed accidental deletion:
- 'orders' container: RESTORED (production data!)
- 'test-data' container: REMOVED (intentional cleanup)

Near miss: Almost deleted 12K+ production orders!
Thanks @tom-platform for catching this!
"

git push
```

---

#### 3:18 PM - 🔄 CI Pipeline Re-runs

```
Pipeline: Terraform-DevSecOps-CI-52 (updated)

📊 Terraform Plan:

Plan: 0 to add, 0 to change, 1 to destroy

Resources to be destroyed:
- azurerm_cosmosdb_sql_container.test-data  # ← Only test data now! ✅

✅ Safe deletion:
- No production data affected
- 'orders' container preserved
- Only 'test-data' removed (15 documents)

💰 Cost Impact: -$24/month (removed test container)

✅ PIPELINE PASSED - Safe to proceed!
```

---

#### 3:20 PM - 🤖 Bot Updates Comment

```
## ✅ Pipeline Results - SAFE

**Plan: 0 to add, 0 to change, 1 to destroy**

### Resources to be DESTROYED:

1. **azurerm_cosmosdb_sql_container.test-data**
   - Contains 15 documents
   - Test data only
   - ✅ Safe to delete

### ✅ PRODUCTION DATA PROTECTED:

- 'orders' container: ✅ PRESERVED
- 'products' container: ✅ PRESERVED

---
Ready for approval!
```

---

#### 3:25 PM - Tom & Alice: Approve

```
Tom commented:

Much better! ✅

Now we're only deleting test data:
- test-data: 15 documents (safe)
- orders: PRESERVED (12K+ orders safe!)

This is exactly why we have:
1. Terraform plan review (shows what will be deleted)
2. PR review process (human verification)
3. Pipeline reports (clear visibility)

Near disaster averted! Good catch by the process! 🛡️

Approved ✅

---

Alice commented:

This is a perfect example of why governance matters!

Without the framework:
- Sarah might have run "delete" command directly
- No review process
- No visibility into impact
- 12K orders GONE 💀

With the framework:
- Terraform plan showed the destruction
- PR process caught the mistake
- Team reviewed before execution
- Data protected ✅

THIS is the value of DevSecOps! 

Approved ✅
```

---

#### 3:30 PM - Sarah: Merges (Safely!)

```
PR #52 merged → CD pipeline triggered

Pipeline: Terraform-DevSecOps-CD-75

Terraform Apply:

📋 Planning...
✅ Plan: 1 to destroy (test-data only)

🎬 Applying...

Destroying test resources:
🗑️  Destroying: azurerm_cosmosdb_sql_container.test-data (30 seconds)

Preserving production resources:
✅ azurerm_cosmosdb_sql_container.orders (UNCHANGED)
✅ azurerm_cosmosdb_sql_container.products (UNCHANGED)

✅ Apply complete!
- 0 added
- 0 changed
- 1 destroyed (test-data only)

Duration: 45 seconds

Production data protected! ✅
```

---

#### 3:35 PM - Team Debrief

```
Slack conversation in #platform-team:

Sarah: "I can't believe I almost deleted production data! 😱"

Tom: "But you DIDN'T delete it! That's the point!"

Sarah: "True! The framework caught it before any damage."

Tom: "Exactly! Let's review what saved us:

1. Terraform Plan: Showed EXACTLY what would be deleted
2. PR Review: Human eyes caught the mistake
3. Pipeline Comments: Made the impact crystal clear
4. Approval Process: Prevented immediate execution

Without these safeguards? Data would be GONE."

Alice: "This is worth documenting. Let's add to success stories."

Mark (CRM team): "This makes me feel so much safer deploying!"

Sarah: "Lesson learned: ALWAYS review Terraform plan carefully,
        especially when removing resources!"

Tom: "And don't feel bad Sarah - we've ALL almost made this mistake.
      The framework is designed to protect us from ourselves! 🛡️"
```

---

### Operational Scenario 4: Key Results

**Timeline: 30 minutes** (from mistake to safe resolution)

**What Saved Production Data:**
1. ✅ **Terraform Plan**: Showed destruction explicitly
2. ✅ **PR Review**: Human verification required
3. ✅ **Bot Comments**: Highlighted destructive changes with warnings
4. ✅ **Team Review**: Tom caught the mistake
5. ✅ **Approval Process**: Prevented immediate execution
6. ✅ **Git History**: Easy to revert and fix

**What Would Have Happened Without Framework:**
```
Old Way (Manual):
├── Sarah runs: az cosmosdb sql container delete ...
├── Prompt: "Are you sure? (y/n)"
├── Sarah types: y
├── Container deleted immediately
├── 12,450 orders GONE forever 💀
├── Customer complaints flood in
├── Recovery: Impossible (no backup)
└── Incident cost: $500K+ (data loss, customer trust, recovery efforts)

New Way (Framework):
├── Sarah creates PR
├── Terraform plan shows destruction
├── Bot highlights destructive changes with warnings
├── Team reviews
├── Tom catches mistake
├── Sarah fixes before merge
├── Data never at risk ✅
└── Cost: $0, time: 30 minutes
```

**Safety Metrics:**
| Protection Layer | Old Way | Framework | Effectiveness |
|------------------|---------|-----------|---------------|
| Preview Changes | No | Yes (Terraform plan) | Caught mistake |
| Human Review | No | Yes (PR process) | Caught mistake |
| Warnings | Generic | Specific (Bot comments) | Clear visibility |
| Approval Required | No | Yes (2 reviewers) | Prevented execution |
| Rollback Possible | No (data gone) | Yes (Git revert) | Safety net |
| Audit Trail | No | Yes (PR history) | Accountability |

---

## 📊 Summary: Operational Scenarios vs Security Scenarios

### How They Work Together

**Operational Scenarios (Framework Efficiency):**
- Scenario 1: Deploy AKS - Fast workflow (5 hours vs 3 days)
- Scenario 2: Add Cosmos DB - Incremental deployment (no downtime)
- Scenario 3: New Team - Independence (no conflicts)
- Scenario 4: Remove Resources - Safety (governance saves data)

**Security Scenarios (DevSecOps Protection):**
- Security 1: Secret Detection - Prevents credentials in code
- Security 2: Approval Gates - Enforces management review
- Security 3: Unauthorized Access - Blocks improper access

### Combined Value Proposition

**Speed + Security + Safety = Modern Infrastructure**

```
BEFORE (Manual/Chaotic):
├── Slow (3 days per deployment)
├── Risky (40% failure rate)
├── Insecure (secrets in code)
├── Conflicts (teams block each other)
└── Dangerous (accidental data loss)

AFTER (Framework + DevSecOps):
├── Fast (5 hours, 85% faster)
├── Reliable (5% failure rate)
├── Secure (automated scanning)
├── Independent (teams work in parallel)
└── Safe (governance prevents mistakes)
```

---

## 🔐 PART B: DevSecOps Security Scenarios

### Security Scenario 1: Deploy AKS with Security Scanning

**Security Focus:** Demonstrate how security is enforced at every step

**Timeline:** 1.5 hours (including security reviews)

---

#### Day 1, 9:00 AM - Sarah: Create Branch & Enable AKS

```bash
git checkout -b feature/add-aks-cluster
```

```hcl
# infra/envs/dev/dev.tfvars
enable_aks = true
aks_node_count = 2
aks_vm_size = "Standard_D2s_v3"
```

#### 9:10 AM - Sarah: Commits (accidentally includes secret!)

```bash
# Sarah accidentally puts a secret in code (common mistake!)
echo "admin_password = SuperSecret123!" >> dev.tfvars

git add .
git commit -m "feat: enable AKS"
git push
```

#### 9:12 AM - Sarah: Creates PR

```
PR #42: Enable AKS Cluster
```

#### 9:13 AM - 🚨 DevSecOps CI Pipeline: SECURITY ALERT!

```
Pipeline: Terraform-DevSecOps-CI
Status: ❌ FAILED

SECURITY STAGE:
├── 🔍 Secret Scanning (GitLeaks)
│   └── ❌ FAILED: Hardcoded password detected!
│       File: infra/envs/dev/dev.tfvars
│       Line: 15
│       Secret: "SuperSecret123!"
│       Type: Generic password
│
├── 🛡️ Infrastructure Scan (Checkov)
│   └── ⏸️  Skipped (security failure)
│
└── 📋 Compliance Check
    └── ⏸️  Skipped (security failure)

🚨 PIPELINE FAILED - SECURITY ISSUE MUST BE RESOLVED!
```

#### 9:14 AM - 🤖 Bot Comments on PR

```
🚨 SECURITY ALERT! Pipeline Failed

❌ Secret detected in code:
- File: dev.tfvars
- Type: Password
- Line: 15

🔒 REQUIRED ACTIONS:
1. Remove the secret from code
2. Store in Azure Key Vault instead
3. Use variable reference: var.admin_password
4. Rotate the exposed password

This PR cannot be merged until security issues are resolved.

Severity: CRITICAL
Auto-merge: BLOCKED
```

#### 9:16 AM - Tom (Security Team): Comments

```
Tom (Security) commented:

🚨 Sarah, this is a CRITICAL security issue!

The password is now in Git history and must be considered compromised.

Required remediation:
1. Remove password from code ✅
2. Add to Key Vault ✅
3. Force-push to remove from Git history (or rebase)
4. Generate NEW password (old one is compromised)
5. Document incident for security review

Please reach out if you need help!
```

#### 9:20 AM - Sarah: Fixes the Issue

```bash
# Remove the secret
git reset HEAD~1

# Add properly using Key Vault reference
cat >> dev.tfvars << EOF
# Admin credentials stored in Key Vault
# Reference: kv-terraform-cicd-001/aks-admin-password
EOF

git add dev.tfvars
git commit -m "fix: remove hardcoded password, use Key Vault reference"
git push --force
```

#### 9:25 AM - DevSecOps CI Pipeline: SUCCESS!

```
Pipeline: Terraform-DevSecOps-CI-2
Status: ✅ SUCCESS

SECURITY STAGE:
├── 🔍 Secret Scanning (GitLeaks)
│   └── ✅ PASSED: No secrets detected
│
├── 🛡️ Infrastructure Scan (Checkov)
│   └── ✅ PASSED: 45/45 checks passed
│       - AKS cluster uses managed identity ✅
│       - Network policy enabled ✅
│       - RBAC enabled ✅
│       - API server authorized IP ranges ✅
│
├── 📋 Compliance Check
│   └── ✅ PASSED: All policies met
│       - Required tags present ✅
│       - Naming convention followed ✅
│       - Region restrictions met ✅
│
└── 💰 Cost Estimation
    └── ✅ PASSED: $145/mo (within budget)

VALIDATION STAGE:
├── ✅ Terraform format check
├── ✅ Terraform validate
└── ✅ Terraform plan generated

✅ PIPELINE PASSED - READY FOR REVIEW
```

#### 9:30 AM - Security Review Complete

```
Tom (Security) commented:

✅ Security review: APPROVED

All security issues resolved:
- No secrets in code ✅
- Checkov scan passed ✅
- Compliance policies met ✅
- AKS security best practices followed ✅

Great job on the quick remediation Sarah!

Approved (Security Team) ✅
```

#### 9:45 AM - Manager Alice: Approves

```
Alice (Manager) commented:

Good catch by security automation! This is exactly why we have DevSecOps.

Cost estimate looks good. Approved for deployment.

Approved (Management) ✅ (2/2 approvals)
```

#### 9:50 AM - Merged & Deployed

```
PR Merged → CD Pipeline Triggered

AUDIT LOG:
{
  "timestamp": "2026-02-03T14:50:00Z",
  "event": "deployment_started",
  "pipeline_id": "12345",
  "triggered_by": "Sarah Jones",
  "commit": "a4f8e2b",
  "security_scan": "passed",
  "approvals": ["Tom (Security)", "Alice (Manager)"],
  "secrets_detected": "none",
  "compliance": "passed"
}

Dev Deployment: ✅ SUCCESS (17 minutes)

AUDIT LOG:
{
  "timestamp": "2026-02-03T15:07:00Z",
  "event": "deployment_success",
  "environment": "dev",
  "resources_created": 15,
  "security_validated": true,
  "audit_sealed": true
}
```

---

#### Scenario 1 Key Learnings

**What DevSecOps Caught:**
1. ✅ **Hardcoded secret** (would have been in production!)
2. ✅ **Immediate alert** (found in 2 minutes vs weeks/months)
3. ✅ **Blocked deployment** (can't merge until fixed)
4. ✅ **Forced remediation** (security is not optional)
5. ✅ **Complete audit trail** (who, what, when, why)

**Security Benefits:**
- **Before DevSecOps:** Secret would have been deployed to production, exposed for months
- **With DevSecOps:** Caught in 2 minutes, never reached production
- **Prevented:** Potential security breach, compliance violation, audit failure

**Audit Trail:**
- Every action logged (immutable)
- Who reviewed (Tom, Alice)
- When approved (timestamps)
- What was deployed (commit hash)
- Security validation results

---

### Scenario 2: Production Deployment with Approval Gate

**Security Focus:** Manual approval for production, complete audit trail

**Timeline:** 30 minutes (after dev success)

---

#### 10:00 AM - CD Pipeline: Production Stage Reached

```
STAGE: Deploy to Production
Status: ⏸️  WAITING FOR APPROVAL

Environment: production
Approvers Required:
  - Platform Team Lead (Tom)
  - Manager (Alice)

Timeout: 24 hours

Approval Context:
- Dev deployment: ✅ Successful
- Security scans: ✅ All passed
- Cost estimate: $145/mo
- Risk: Low (tested in dev)

Waiting for approvals...
```

#### 10:05 AM - Manager Alice: Reviews Production Deployment

```
Alice opens Azure DevOps:

Production Deployment Approval Request

Requesting: Deploy AKS to production
Requested by: Sarah Jones (E-commerce Team)
Dev testing: 3 days (successful)
Security: All scans passed
Cost: $145/month (approved budget)

Pre-deployment checklist:
☐ Runbook created?
☐ Monitoring configured?
☐ Backup strategy defined?
☐ Rollback plan documented?

Alice reviews checklist...
```

#### 10:10 AM - Alice: Requests Information

```
Alice commented in approval:

Before I approve, please confirm:

1. Is monitoring configured for the AKS cluster?
2. Do we have a rollback plan?
3. Who will be on-call for issues?

Please respond with confirmation.
```

#### 10:15 AM - Sarah: Responds

```
Sarah responds:

1. Monitoring: Yes! Azure Monitor + Log Analytics configured
   - Alerts for pod failures
   - Alerts for resource exhaustion
   - Dashboard created

2. Rollback: Yes! Document in docs/RUNBOOK-AKS.md
   - Can revert Git commit
   - Terraform will destroy AKS
   - Data in Cosmos DB unaffected

3. On-call: Tom (Platform) + Sarah (E-commerce)
   - PagerDuty rotation configured
   - Escalation path documented

Ready for production approval!
```

#### 10:20 AM - Alice: Approves

```
Alice: APPROVED ✅

All questions answered satisfactorily. 
Monitoring and rollback plans are in place.

Approved for production deployment.

AUDIT LOG:
{
  "timestamp": "2026-02-03T15:20:00Z",
  "event": "production_approval_granted",
  "approver": "Alice (Manager)",
  "approver_email": "alice@company.com",
  "pipeline_id": "12345",
  "justification": "Monitoring and rollback confirmed",
  "security_review": "passed",
  "compliance": "passed"
}
```

#### 10:21 AM - Production Deployment Starts

```
🏭 Production Deployment Started

AUDIT LOG (SEALED):
{
  "timestamp": "2026-02-03T15:21:00Z",
  "event": "production_deployment_started",
  "environment": "production",
  "pipeline_id": "12345",
  "approved_by": "Alice (Manager)",
  "deployed_by": "Service Principal (sp-terraform-cicd-prod)",
  "commit": "a4f8e2b",
  "security_scans": "passed",
  "secrets_source": "Azure Key Vault",
  "audit_sealed": true,
  "audit_hash": "sha256:a1b2c3d4..."
}

Terraform Apply (Production):
- Creating AKS cluster... (15 minutes)
- Creating networking... (2 minutes)
- Configuring monitoring... (1 minute)

✅ PRODUCTION DEPLOYMENT SUCCESSFUL!

AUDIT LOG (SEALED):
{
  "timestamp": "2026-02-03T15:39:00Z",
  "event": "production_deployment_completed",
  "environment": "production",
  "pipeline_id": "12345",
  "status": "success",
  "resources_created": 15,
  "duration_minutes": 18,
  "cost_actual": "$145/mo",
  "security_validated": true,
  "compliance_validated": true,
  "audit_sealed": true,
  "audit_hash": "sha256:e5f6g7h8..."
}
```

#### 10:40 AM - Notifications Sent

```
📧 Email Notification:

To: Management, Security Team, Platform Team, E-commerce Team
Subject: ✅ PRODUCTION Deployment Completed - AKS Cluster

Deployment Summary:
- Environment: Production
- What: AKS Cluster enabled
- Requested by: Sarah Jones
- Approved by: Alice (Manager)
- Deployed: 2026-02-03 15:39 UTC
- Duration: 18 minutes
- Status: SUCCESS
- Cost: $145/month

Security:
✅ All security scans passed
✅ No secrets in code
✅ Compliance verified
✅ Audit trail sealed

Next Steps:
- Monitor AKS cluster health
- Deploy applications
- Review monitoring dashboards

View details: [Pipeline Link]
Audit log: [Immutable Log Link]
```

---

### Scenario 3: Attempted Unauthorized Change (Security Demo)

**Security Focus:** How DevSecOps prevents unauthorized actions

**Timeline:** 5 minutes (blocked immediately)

---

#### Week 2, 2:00 PM - John (Junior Dev): Tries to Deploy to Prod Directly

```bash
# John thinks he can just deploy to prod directly
cd infra/envs/prod

# John tries to run terraform locally
terraform init
terraform apply -var-file="prod.tfvars"
```

#### 2:01 PM - Azure: ❌ ACCESS DENIED

```
Error: Unable to initialize backend

│ Error: Failed to get existing workspaces: 
│ storage: service returned error: StatusCode=403, 
│ ErrorCode=AuthorizationFailed
│ 
│ Insufficient permissions to access storage account.

❌ PERMISSION DENIED

Your account does not have access to production state file.

Required permissions:
- Production deployments MUST go through Azure DevOps pipeline
- Requires manual approval from management
- Service Principal only (not user accounts)

For production changes:
1. Create Pull Request
2. Pass security scans
3. Get manager approval
4. Pipeline deploys via approved SP

Contact Platform Team if you believe this is an error.
```

#### 2:02 PM - John: Tries to Update Service Principal

```bash
# John tries to get SP credentials
az keyvault secret show \
  --vault-name "kv-terraform-cicd-001" \
  --name "sp-terraform-prod-client-secret"
```

#### 2:03 PM - Azure Key Vault: ❌ ACCESS DENIED + ALERT!

```
Error: (Forbidden) The user, group or application with object ID 'xxx' 
does not have permission to perform action 'Microsoft.KeyVault/vaults/secrets/getSecret'

❌ ACCESS DENIED

🚨 SECURITY ALERT TRIGGERED!

Unauthorized Key Vault access attempt detected:
- User: John Smith (john.smith@company.com)
- Vault: kv-terraform-cicd-001
- Secret: sp-terraform-prod-client-secret
- Time: 2026-02-03 19:03 UTC
- Action: BLOCKED

Security team has been notified.

AUDIT LOG:
{
  "timestamp": "2026-02-03T19:03:00Z",
  "event": "unauthorized_access_attempt",
  "user": "john.smith@company.com",
  "resource": "kv-terraform-cicd-001",
  "secret_requested": "sp-terraform-prod-client-secret",
  "result": "denied",
  "alert_sent": true,
  "severity": "high"
}
```

#### 2:04 PM - Tom (Security Team): Receives Alert

```
🚨 SECURITY ALERT

Unauthorized access attempt to production secrets:
- User: John Smith
- Resource: Production Service Principal credentials
- Action: BLOCKED by RBAC
- Time: 2 minutes ago

IMMEDIATE ACTIONS TAKEN:
✅ Access denied
✅ Audit log updated
✅ Security team notified
✅ Manager notified

RECOMMENDED ACTIONS:
1. Contact John to understand intent
2. Verify no malicious activity
3. Provide training on proper procedures
4. Update documentation if confusion exists

View audit log: [Link]
```

#### 2:10 PM - Tom: Follows Up with John

```
Tom (to John via Slack):

Hey John, I saw you tried to access production secrets directly. 
Everything okay?

Production deployments MUST go through our DevSecOps pipeline with:
1. Pull Request
2. Security scans
3. Manager approval
4. Automated deployment

This ensures:
- Security reviews
- Audit trail
- Compliance
- No accidents

Need help with a prod deployment? Happy to guide you through the process!
```

#### 2:15 PM - John: Response

```
John:
"Oh! I didn't know. I thought I could just deploy directly like we used to.
I wanted to add a small change to prod config.

What's the proper process?"

Tom:
"No problem! Let me show you the right way:

1. Create PR with your change
2. CI pipeline will scan for security issues
3. Get 2 approvals (team + manager)
4. Pipeline automatically deploys to dev
5. Test in dev
6. Manager approves prod deployment
7. Pipeline deploys to prod with full audit trail

This protects everyone - including you from accidents!

Want to pair on creating the PR?"
```

---

#### Scenario 3 Key Learnings

**What DevSecOps Prevented:**
1. ✅ **Unauthorized production access** (blocked by RBAC)
2. ✅ **Direct credential access** (blocked by Key Vault policies)
3. ✅ **Unaudited changes** (no way to bypass pipeline)
4. ✅ **Potential accidents** (junior dev doesn't have prod access)

**Security Layers That Worked:**
1. **RBAC on storage account** (state file protected)
2. **Key Vault access policies** (secrets protected)
3. **Service Principal isolation** (only pipeline has access)
4. **Audit logging** (attempt recorded)
5. **Alerting** (security team notified)

**Training Opportunity:**
- Not a malicious attempt, just lack of awareness
- Proper security prevented any damage
- Used as teaching moment
- Updated onboarding documentation

---

## 📊 DevSecOps Benefits Summary

### Security Metrics

| Metric | Before DevSecOps | After DevSecOps | Improvement |
|--------|------------------|-----------------|-------------|
| **Hardcoded Secrets** | 12 found in audit | 0 (blocked by pipeline) | 100% |
| **Unauthorized Access** | 5 incidents/month | 0 (blocked by RBAC) | 100% |
| **Security Scan Coverage** | 0% | 100% | ∞ |
| **Time to Detect Secret** | Weeks/Never | 2 minutes | 99.9% |
| **Production Accidents** | 3/quarter | 0 | 100% |
| **Compliance Audit Failures** | 3 major findings | 0 findings | 100% |

### Auditability Metrics

| Requirement | Before | After | Status |
|-------------|--------|-------|--------|
| **Who deployed?** | Unknown | Complete trail | ✅ |
| **When deployed?** | Approximate | Exact timestamp | ✅ |
| **What changed?** | No record | Full diff + plan | ✅ |
| **Who approved?** | Email chains | Immutable log | ✅ |
| **Why changed?** | No docs | PR description | ✅ |
| **Security validated?** | No | Scan results | ✅ |
| **Cost impact?** | Unknown | Pre-estimated | ✅ |
| **Rollback possible?** | Difficult | Git revert | ✅ |

### Compliance Achievements

**SOC 2 Requirements:**
- ✅ **CC6.1**: Logical access controls implemented
- ✅ **CC6.2**: Prior authorization required for production
- ✅ **CC6.3**: System configuration changes audited
- ✅ **CC7.1**: Security incidents detected and communicated
- ✅ **CC7.2**: Security violations monitored and reported

**PCI-DSS Requirements:**
- ✅ **2.2**: Configuration standards implemented
- ✅ **6.3**: Secure development processes
- ✅ **10.1**: Audit trails maintained
- ✅ **10.2**: Automated audit trails for all users
- ✅ **10.3**: Audit trails tamper-proof

---

## 🎓 Training & Adoption Plan

### Week 1: Platform Team - DevSecOps Foundations

**Day 1: Security Fundamentals**
- Secrets management (Key Vault vs Variable Groups)
- RBAC and least privilege
- Audit logging and compliance
- Incident response procedures

**Day 2: Azure DevOps Security**
- Service principals and managed identities
- Key Vault integration
- Secure pipelines
- Approval gates and policies

**Day 3: Security Scanning Tools**
- Checkov (infrastructure security)
- GitLeaks (secret detection)
- Infracost (cost governance)
- Custom policy validation

**Day 4: Hands-on Lab**
- Set up secure pipelines
- Configure Key Vault integration
- Test security scanning
- Practice incident response

**Day 5: Audit & Compliance**
- Audit trail requirements
- Compliance reporting
- Immutable logs
- Security documentation

---

### Week 2: App Teams - Secure Development

**Day 1: DevSecOps Overview**
- Why security matters
- Common security mistakes
- How DevSecOps helps
- What to expect in workflow

**Day 2: Secure Workflow**
- Never hardcode secrets
- Use Key Vault references
- Review security scan results
- Respond to security alerts

**Day 3: Hands-on (Scenario 1)**
- Create PR (with intentional security issue)
- See how pipeline catches it
- Fix the issue
- Understand security validation

**Day 4: Approvals & Governance**
- Why approvals are required
- How to request prod deployment
- What managers review
- Escalation procedures

**Day 5: Real Deployment**
- Deploy to dev (automatic)
- Request prod approval
- Understand audit trail
- Monitor deployment

---

### Week 3-4: Security Champions Program

**Goal:** Train 1 person per team as security champion

**Responsibilities:**
- Review security scan results
- Help team fix security issues
- Promote security awareness
- Escalate concerns to security team

**Training:**
- Deep-dive on security tools
- Common vulnerabilities and fixes
- Incident response procedures
- Quarterly security reviews

---

## 📈 Success Metrics (DevSecOps Focus)

### Security KPIs

| Metric | Baseline | Target (3mo) | Target (6mo) | Measurement |
|--------|----------|--------------|--------------|-------------|
| **Secrets in Code** | 12 | 0 | 0 | GitLeaks scans |
| **Security Scan Coverage** | 0% | 100% | 100% | Pipeline runs |
| **Critical Vulnerabilities** | Unknown | 0 | 0 | Checkov reports |
| **Unauthorized Access Attempts** | Undetected | 0 | 0 | Key Vault alerts |
| **Time to Detect Secret** | Never | <2 min | <2 min | Pipeline logs |
| **Time to Remediate** | N/A | <1 hour | <30 min | Issue resolution |

### Compliance KPIs

| Metric | Baseline | Target | Status |
|--------|----------|--------|--------|
| **Audit Trail Coverage** | 20% | 100% | Azure DevOps logs |
| **Approval Gate Compliance** | 30% | 100% | Environment gates |
| **Change Documentation** | 40% | 100% | PR descriptions |
| **Security Review Coverage** | 0% | 100% | Checkov scans |
| **Cost Transparency** | 10% | 100% | Infracost reports |
| **Rollback Capability** | 20% | 100% | Git history |

### Audit Trail Validation

**Quarterly Review:** Verify audit logs contain:
- ✅ Who made the change (user identity)
- ✅ What was changed (Terraform plan diff)
- ✅ When it was changed (timestamp)
- ✅ Why it was changed (PR description)
- ✅ Who approved (approval records)
- ✅ Security validation results
- ✅ Cost impact estimate
- ✅ Deployment success/failure

---

## 🚀 Implementation Roadmap

### Week 1: Security Foundation
- **Day 1**: Service principals, Key Vault setup
- **Day 2**: RBAC configuration, state file security
- **Day 3**: CI pipeline with security scanning
- **Day 4**: CD pipeline with approval gates
- **Day 5**: Platform team training

### Week 2: Pilot with Security Focus
- **Day 1-2**: E-commerce team training (security focus)
- **Day 3**: Scenario 1 (Deploy AKS with security validation)
- **Day 4**: Scenario 2 (Production approval workflow)
- **Day 5**: Scenario 3 (Unauthorized access prevention)

### Week 3: Compliance Validation
- **Day 1-2**: Audit trail review
- **Day 3**: Compliance reporting setup
- **Day 4**: Security incident procedures
- **Day 5**: Management review and sign-off

### Week 4: Rollout
- **Day 1-2**: Train remaining teams
- **Day 3-4**: Monitor adoption
- **Day 5**: Retrospective and improvements

---

## 🆘 Security Incident Response

### Incident: Secret Found in Code

**Severity:** CRITICAL  
**Response Time:** Immediate

**Steps:**
1. **Immediate**: Pipeline blocks PR automatically
2. **1 minute**: Alert sent to security team
3. **5 minutes**: Security team reviews
4. **15 minutes**: Developer notified with fix guidance
5. **30 minutes**: Secret removed from code
6. **1 hour**: Secret rotated in Key Vault
7. **24 hours**: Incident review and documentation

**Audit Record:**
```json
{
  "incident_type": "secret_detected",
  "severity": "critical",
  "detected_by": "GitLeaks",
  "detected_at": "2026-02-03T10:15:00Z",
  "blocked": true,
  "notified": ["security-team", "developer"],
  "remediated_at": "2026-02-03T10:45:00Z",
  "secret_rotated": true,
  "audit_sealed": true
}
```

---

### Incident: Unauthorized Access Attempt

**Severity:** HIGH  
**Response Time:** 5 minutes

**Steps:**
1. **Immediate**: Access denied by RBAC
2. **1 minute**: Alert sent to security team
3. **5 minutes**: Security team reviews context
4. **15 minutes**: Manager notified
5. **30 minutes**: User contacted for explanation
6. **24 hours**: Training provided if benign
7. **48 hours**: Account review if suspicious

**Audit Record:**
```json
{
  "incident_type": "unauthorized_access",
  "severity": "high",
  "user": "john.smith@company.com",
  "resource": "kv-terraform-cicd-001",
  "blocked": true,
  "reviewed_by": "security-team",
  "outcome": "training_required",
  "audit_sealed": true
}
```

---

## 🆘 Disaster Recovery & State File Management

### State File Backup & Recovery

**Azure Storage Account State File Protection:**

```bash
# State file is already protected with:
# ✅ Versioning enabled (recover from any change)
# ✅ Soft delete enabled (30-day retention)
# ✅ GRS replication (geo-redundant)
# ✅ Immutable blob versioning
# ✅ Diagnostic logging (all access tracked)
```

---

### Scenario 1: State File Corrupted

**Symptoms:**
- Terraform shows unexpected changes
- Resources appear to be missing
- "Error: state snapshot was created by Terraform X, but this is Terraform Y"

**Recovery Steps:**

```bash
# Step 1: List available versions
az storage blob list \
  --account-name stterraformstate001 \
  --container-name tfstate \
  --prefix "dev.tfstate" \
  --include v

# Step 2: Download a previous version
az storage blob download \
  --account-name stterraformstate001 \
  --container-name tfstate \
  --name "dev.tfstate" \
  --version-id "{version-id}" \
  --file "dev.tfstate.backup"

# Step 3: Verify the backup
terraform show dev.tfstate.backup

# Step 4: Restore if valid
az storage blob upload \
  --account-name stterraformstate001 \
  --container-name tfstate \
  --name "dev.tfstate" \
  --file "dev.tfstate.backup" \
  --overwrite

# Step 5: Verify restoration
cd infra/envs/dev
terraform init
terraform plan  # Should show no unexpected changes
```

**Duration:** 15-30 minutes  
**Risk:** Low (versioning prevents data loss)

---

### Scenario 2: State File Deleted (Soft Delete Recovery)

**Symptoms:**
- "Error: Failed to get existing workspaces: blob not found"
- State file missing from storage account

**Recovery Steps:**

```bash
# Step 1: List soft-deleted blobs
az storage blob list \
  --account-name stterraformstate001 \
  --container-name tfstate \
  --include d \
  --prefix "dev.tfstate"

# Step 2: Undelete the blob
az storage blob undelete \
  --account-name stterraformstate001 \
  --container-name tfstate \
  --name "dev.tfstate"

# Step 3: Verify restoration
terraform init
terraform plan
```

**Duration:** 5-10 minutes  
**Retention:** 30 days (after deletion)

---

### Scenario 3: Complete State Loss (Rebuild from Azure)

**Worst Case:** State file completely lost and backups unavailable

**Recovery Steps:**

```bash
# Step 1: Create new empty state
cd infra/envs/dev
rm -rf .terraform
terraform init

# Step 2: Import existing resources one by one
# Get resource IDs from Azure Portal or CLI

# Import resource group
terraform import azurerm_resource_group.main \
  "/subscriptions/{sub-id}/resourceGroups/rg-ecom-dev"

# Import VNet
terraform import azurerm_virtual_network.main \
  "/subscriptions/{sub-id}/resourceGroups/rg-ecom-dev/providers/Microsoft.Network/virtualNetworks/vnet-main-dev"

# Import AKS cluster
terraform import azurerm_kubernetes_cluster.main \
  "/subscriptions/{sub-id}/resourceGroups/rg-ecom-dev/providers/Microsoft.ContainerService/managedClusters/aks-ecom-dev"

# Import Cosmos DB
terraform import azurerm_cosmosdb_account.main \
  "/subscriptions/{sub-id}/resourceGroups/rg-ecom-dev/providers/Microsoft.DocumentDB/databaseAccounts/cosmos-ecom-dev"

# ... (repeat for all resources)

# Step 3: Verify state matches reality
terraform plan
# Should show: "No changes. Your infrastructure matches the configuration."

# Step 4: Document in incident report
```

**Duration:** 2-4 hours (depends on resource count)  
**Risk:** High (manual process, error-prone)  
**Prevention:** Regular state file backups prevent this scenario

---

### State File Security Incident Response

**If state file is compromised (contains sensitive data):**

1. **Immediate Actions:**
   - Rotate all secrets in Key Vault
   - Rotate Service Principal credentials
   - Review access logs for unauthorized access
   - Notify security team

2. **Investigation:**
   - Check who accessed state file
   - Review audit logs in Log Analytics
   - Determine scope of compromise

3. **Remediation:**
   - Update all compromised credentials
   - Review RBAC permissions
   - Enhance monitoring/alerting

4. **Prevention:**
   - Use `sensitive = true` for sensitive values
   - Minimize secrets in state (use Key Vault references)
   - Regular security reviews

---

### Break-Glass Emergency Access

**Emergency Scenario:** CI/CD pipeline down, critical production fix needed NOW

**Emergency Manual Deployment Procedure:**

```bash
# ONLY use in emergency! Requires break-glass approval.

# Step 1: Get emergency access (Security Team approval required)
az login --use-device-code

# Step 2: Set subscription
az account set --subscription "{prod-subscription-id}"

# Step 3: Get state file access (requires elevated permissions)
az storage blob download \
  --account-name stterraformstate001 \
  --container-name tfstate \
  --name "prod.tfstate" \
  --file "prod.tfstate.emergency"

# Step 4: Make emergency change
cd infra/envs/prod
terraform init
terraform plan -var-file="prod.tfvars"

# Step 5: Get verbal approval from 2 managers
# Step 6: Apply with full documentation
terraform apply -var-file="prod.tfvars" | tee emergency-apply.log

# Step 7: IMMEDIATELY document in incident report
# Step 8: Create post-mortem
# Step 9: Return to normal pipeline ASAP
```

**Requirements:**
- ✅ Security team approval
- ✅ Management approval (2 people)
- ✅ Documented in incident ticket
- ✅ Post-mortem within 24 hours
- ✅ Audit log sealed

**Use ONLY for:**
- Production down, customer impact
- Pipeline completely broken
- Security incident requiring immediate fix

**DO NOT use for:**
- "Faster" deployments
- Bypassing reviews
- Convenience

---

## 🔧 Troubleshooting Common Issues

### Issue 1: Pipeline Fails with "State Lock Timeout"

**Error Message:**
```
Error: Error acquiring the state lock

Error message: storage: service returned error: StatusCode=409
```

**Cause:** Another pipeline or user is currently running Terraform

**Solution:**

```bash
# Step 1: Check who has the lock
az storage blob show \
  --account-name stterraformstate001 \
  --container-name tfstate \
  --name "dev.tfstate.lock" \
  --query "metadata"

# Output shows: {"LockID": "abc-123", "Who": "pipeline-456", "Created": "2026-02-03T15:30:00Z"}

# Step 2: Verify if pipeline is actually running
# Check Azure DevOps for active pipelines

# Step 3a: If pipeline stuck, cancel it in Azure DevOps
# Step 3b: If manual Terraform run stuck, contact the user

# Step 4: Force unlock (ONLY if confirmed stuck)
cd infra/envs/dev
terraform force-unlock abc-123

# Step 5: Retry your deployment
```

**Prevention:**
- Use Azure DevOps pipeline queues (automatic)
- Don't run manual Terraform commands in CI/CD environments
- Set timeout on pipeline tasks (30 minutes)

---

### Issue 2: Pipeline Fails with "Secret Not Found in Key Vault"

**Error Message:**
```
Error: Secret not found: ARM_CLIENT_SECRET
Key Vault: kv-terraform-cicd-001
```

**Cause:** Service connection doesn't have Key Vault access

**Solution:**

```bash
# Step 1: Verify secret exists
az keyvault secret show \
  --vault-name kv-terraform-cicd-001 \
  --name "sp-terraform-dev-client-secret"

# If exists, proceed to Step 2
# If not exists, create it (Step 2b)

# Step 2: Grant pipeline access
# Get service principal object ID for Azure DevOps service connection
az ad sp list --display-name "Azure-DevOps-Connection" --query "[].objectId" -o tsv

# Output: <object-id>

# Grant Key Vault access
az keyvault set-policy \
  --name kv-terraform-cicd-001 \
  --object-id <object-id> \
  --secret-permissions get list

# Step 3: Verify access
az keyvault secret show \
  --vault-name kv-terraform-cicd-001 \
  --name "sp-terraform-dev-client-secret" \
  --query "value" -o tsv

# Step 4: Retry pipeline
```

**Prevention:**
- Document Key Vault permissions in setup guide
- Automated script to verify permissions
- Pre-flight checks in pipeline

---

### Issue 3: Terraform Plan Shows Unexpected Changes

**Error Message:**
```
Plan: 0 to add, 5 to change, 0 to destroy

Changes to apply:
  ~ azurerm_kubernetes_cluster.main
      tags = {
        + "Environment" = "dev"
        - "Env" = "development"
      }
```

**Cause:** Manual changes made in Azure Portal (configuration drift)

**Solution:**

```bash
# Step 1: Identify what changed
terraform plan -detailed-exitcode > plan-output.txt

# Step 2: Review changes
cat plan-output.txt

# Step 3: Determine cause
# - Manual Azure Portal change? (drift)
# - Terraform code updated? (intentional)
# - Azure provider auto-added values? (normal)

# Step 4a: Accept drift (update Terraform to match Azure)
# Edit terraform.tfvars to match current Azure state

# Step 4b: Fix drift (update Azure to match Terraform)
terraform apply  # Reverts manual changes

# Step 5: Document in post-mortem
# Why was manual change made?
# How to prevent in future?
```

**Prevention:**
- Azure Policy: Deny modifications outside Terraform
- Monitoring: Alert on manual changes
- Training: "Infrastructure as Code means NO manual changes!"

---

### Issue 4: Security Scan Fails with "Policy Violation"

**Error Message:**
```
Checkov scan failed:
Check: CKV_AZURE_8: "Ensure that 'Minimum TLS version' is set to '1.2' for Storage Accounts"
FAILED for resource: azurerm_storage_account.main
```

**Cause:** Configuration doesn't meet security baseline

**Solution:**

```hcl
# Fix in Terraform code
resource "azurerm_storage_account" "main" {
  name                     = "stapp001"
  resource_group_name      = azurerm_resource_group.main.name
  location                = azurerm_resource_group.main.location
  account_tier            = "Standard"
  account_replication_type = "GRS"
  
  # FIX: Add minimum TLS version
  min_tls_version = "TLS1_2"
  
  # FIX: Disable public access
  allow_blob_public_access = false
  
  # FIX: Enforce HTTPS
  https_only = true
}
```

**Common Security Fixes:**

1. **Cosmos DB:**
   ```hcl
   # Enable encryption
   enable_automatic_failover = true
   
   # Disable public access
   public_network_access_enabled = false
   ```

2. **AKS:**
   ```hcl
   # Enable RBAC
   role_based_access_control_enabled = true
   
   # Enable network policy
   network_profile {
     network_plugin = "azure"
     network_policy = "azure"
   }
   ```

3. **Key Vault:**
   ```hcl
   # Enable purge protection
   purge_protection_enabled = true
   
   # Enable soft delete
   soft_delete_retention_days = 90
   ```

---

### Issue 5: Cost Estimate Exceeds Budget

**Error Message:**
```
Infracost estimate: $8,450/month
Approved budget: $5,000/month
⚠️  OVER BUDGET by $3,450/month (69%)
```

**Solution:**

```bash
# Step 1: Review detailed cost breakdown
infracost breakdown \
  --path infra/envs/prod \
  --format table \
  > cost-details.txt

cat cost-details.txt

# Step 2: Identify expensive resources
# Common culprits:
# - AKS: Large/many nodes
# - Cosmos DB: High RU/s
# - App Service: Premium plans
# - Storage: High redundancy/performance

# Step 3: Optimize costs
# Example: Reduce AKS node count
aks_node_count = 3  # down from 5
aks_vm_size = "Standard_D2s_v3"  # down from D4s_v3

# Example: Reduce Cosmos DB throughput
containers = [
  {
    name = "products"
    throughput = 400  # down from 1000
  }
]

# Step 4: Re-estimate
infracost breakdown --path infra/envs/prod

# Step 5: Document cost optimization
git commit -m "fix: reduce costs to meet $5K budget

- Reduced AKS nodes: 5 → 3
- Reduced AKS VM size: D4s → D2s
- Reduced Cosmos RU/s: 1000 → 400

New estimate: $4,850/month (within budget!)
"
```

---

### Issue 6: Deployment Succeeds but Resources Don't Work

**Symptoms:**
- Terraform apply succeeded
- Resources created in Azure
- But application can't connect / doesn't work

**Troubleshooting Steps:**

```bash
# Step 1: Verify resources exist
az resource list --resource-group rg-ecom-dev --output table

# Step 2: Check networking
# Are resources in correct VNet/subnet?
az network vnet show --name vnet-main-dev --resource-group rg-ecom-dev

# Step 3: Check NSG rules
az network nsg show --name nsg-aks-dev --resource-group rg-ecom-dev

# Step 4: Check private endpoints
az network private-endpoint list --resource-group rg-ecom-dev --output table

# Step 5: Check DNS resolution
# From AKS pod:
nslookup cosmos-ecom-dev.documents.azure.com

# Step 6: Check firewall rules
az cosmosdb show --name cosmos-ecom-dev --resource-group rg-ecom-dev --query "ipRules"

# Step 7: Check managed identity permissions
az role assignment list --assignee <managed-identity-id> --output table
```

**Common Issues:**
- Private endpoint not configured
- NSG blocking traffic
- Managed identity missing role assignment
- Firewall rules too restrictive

---

## 🔐 Secret Rotation Procedures

### Service Principal Credential Rotation

**Schedule:** Quarterly (every 90 days)  
**Owner:** Platform Team  
**Approval Required:** Security Team

**Rotation Procedure:**

```bash
# ============================================
# STEP 1: Create new Service Principal secret
# ============================================
NEW_SECRET=$(az ad sp credential reset \
  --id <sp-app-id> \
  --display-name "sp-terraform-dev-$(date +%Y%m%d)" \
  --years 1 \
  --query "password" -o tsv)

echo "New secret created: ****-****-**** (logged securely)"

# ============================================
# STEP 2: Store new secret in Key Vault
# ============================================
az keyvault secret set \
  --vault-name kv-terraform-cicd-001 \
  --name "sp-terraform-dev-client-secret" \
  --value "$NEW_SECRET" \
  --description "Rotated on $(date +%Y-%m-%d)"

echo "✅ New secret stored in Key Vault"

# ============================================
# STEP 3: Test with new secret (dev environment)
# ============================================
# Trigger test pipeline in dev
# Pipeline will automatically use new secret from Key Vault
az pipelines run \
  --name "Terraform-DevSecOps-CI" \
  --branch "main" \
  --variables "test_rotation=true"

# Wait for test to complete
echo "Testing new credentials in dev..."

# ============================================
# STEP 4: Verify test succeeded
# ============================================
# Check pipeline result
# If successful: Continue to Step 5
# If failed: Investigate and fix before proceeding

# ============================================
# STEP 5: Update production (if dev test passed)
# ============================================
az keyvault secret set \
  --vault-name kv-terraform-cicd-001 \
  --name "sp-terraform-prod-client-secret" \
  --value "$NEW_SECRET" \
  --description "Rotated on $(date +%Y-%m-%d)"

echo "✅ Production secret updated"

# ============================================
# STEP 6: Verify production access
# ============================================
# Trigger test deployment in production
# Should succeed with no errors

# ============================================
# STEP 7: Revoke old credentials (after 24h grace period)
# ============================================
# Wait 24 hours to ensure no cached credentials in use

# List all credentials
az ad sp credential list --id <sp-app-id> --output table

# Delete old credential (keep only the new one)
az ad sp credential delete \
  --id <sp-app-id> \
  --key-id <old-key-id>

echo "✅ Old credentials revoked"

# ============================================
# STEP 8: Document rotation
# ============================================
cat > rotation-report.md << EOF
# Service Principal Rotation Report

**Date:** $(date +%Y-%m-%d)
**Rotated By:** Platform Team
**Service Principals:**
- sp-terraform-cicd-nonprod
- sp-terraform-cicd-prod

**Test Results:**
- Dev test: ✅ Passed
- Prod test: ✅ Passed

**Old Credentials:**
- Revoked: $(date +%Y-%m-%d)

**Next Rotation:** $(date -d "+90 days" +%Y-%m-%d)

EOF

# Store report in documentation
git add rotation-report.md
git commit -m "docs: service principal rotation $(date +%Y-%m-%d)"
git push
```

**Rotation Checklist:**
- [ ] New secret created
- [ ] Stored in Key Vault
- [ ] Tested in dev (passed)
- [ ] Updated in prod
- [ ] Verified prod access (passed)
- [ ] Old secret revoked (after 24h)
- [ ] Documentation updated
- [ ] Next rotation scheduled (90 days)

---

### Cosmos DB Key Rotation

**Schedule:** Every 6 months  
**Owner:** Platform Team  
**Downtime:** Zero (blue-green rotation)

**Rotation Procedure:**

```bash
# ============================================
# STEP 1: Regenerate SECONDARY key
# ============================================
az cosmosdb keys regenerate \
  --name cosmos-ecom-dev \
  --resource-group rg-ecom-dev \
  --key-kind secondary

echo "✅ Secondary key regenerated"

# ============================================
# STEP 2: Update application to use SECONDARY key
# ============================================
# Update Key Vault secret for applications
NEW_SECONDARY_KEY=$(az cosmosdb keys list \
  --name cosmos-ecom-dev \
  --resource-group rg-ecom-dev \
  --type keys \
  --query "secondaryMasterKey" -o tsv)

az keyvault secret set \
  --vault-name kv-terraform-cicd-001 \
  --name "cosmosdb-connection-string" \
  --value "AccountEndpoint=https://cosmos-ecom-dev.documents.azure.com:443/;AccountKey=$NEW_SECONDARY_KEY;"

# ============================================
# STEP 3: Restart applications (rolling restart)
# ============================================
# Applications will pick up new connection string
kubectl rollout restart deployment -n production

# Wait for pods to become healthy
kubectl rollout status deployment -n production

echo "✅ Applications using secondary key"

# ============================================
# STEP 4: Regenerate PRIMARY key
# ============================================
# Wait 10 minutes to ensure all apps using secondary

sleep 600

az cosmosdb keys regenerate \
  --name cosmos-ecom-dev \
  --resource-group rg-ecom-dev \
  --key-kind primary

echo "✅ Primary key regenerated"

# ============================================
# STEP 5: Update application back to PRIMARY key
# ============================================
NEW_PRIMARY_KEY=$(az cosmosdb keys list \
  --name cosmos-ecom-dev \
  --resource-group rg-ecom-dev \
  --type keys \
  --query "primaryMasterKey" -o tsv)

az keyvault secret set \
  --vault-name kv-terraform-cicd-001 \
  --name "cosmosdb-connection-string" \
  --value "AccountEndpoint=https://cosmos-ecom-dev.documents.azure.com:443/;AccountKey=$NEW_PRIMARY_KEY;"

# ============================================
# STEP 6: Restart applications again
# ============================================
kubectl rollout restart deployment -n production
kubectl rollout status deployment -n production

echo "✅ Rotation complete! Both keys regenerated, zero downtime."

# ============================================
# STEP 7: Document rotation
# ============================================
cat > cosmos-rotation-$(date +%Y%m%d).md << EOF
# Cosmos DB Key Rotation Report

**Date:** $(date +%Y-%m-%d)
**Database:** cosmos-ecom-dev
**Downtime:** 0 minutes

**Process:**
1. Regenerated secondary key
2. Switched apps to secondary
3. Regenerated primary key
4. Switched apps back to primary

**Next Rotation:** $(date -d "+180 days" +%Y-%m-%d)

EOF
```

**Zero-Downtime Guaranteed:**
- Apps always use one valid key
- Blue-green rotation pattern
- Rolling pod restarts (no downtime)

---

### Storage Account Key Rotation

**Schedule:** Every 6 months  
**Owner:** Platform Team

**Rotation Procedure:**

```bash
# Similar to Cosmos DB rotation (blue-green pattern)

# Step 1: Regenerate key2
az storage account keys renew \
  --account-name stterraformstate001 \
  --resource-group rg-terraform-state-security \
  --key key2

# Step 2: Update applications to use key2
# (Update Key Vault, restart apps)

# Step 3: Regenerate key1
az storage account keys renew \
  --account-name stterraformstate001 \
  --resource-group rg-terraform-state-security \
  --key key1

# Step 4: Switch back to key1
# (Update Key Vault, restart apps)
```

---

### Secret Rotation Automation

**Future Enhancement:** Automate with Azure Key Vault auto-rotation

```bash
# Enable managed identity auto-rotation (future)
# Azure Key Vault supports automatic rotation for:
# - Service Principal secrets (with Azure AD integration)
# - Storage account keys (with Azure Key Vault integration)
# - SQL passwords (with Azure Key Vault integration)

# Configuration example (future):
az keyvault secret set-attributes \
  --vault-name kv-terraform-cicd-001 \
  --name "sp-terraform-dev-client-secret" \
  --rotation-policy "automated" \
  --rotation-interval "90d"
```

---

## 📊 Compliance & Audit Evidence

### Audit Log Storage & Retention

**Audit logs are stored in multiple locations for compliance:**

1. **Azure Log Analytics Workspace**
   - **Location:** `/subscriptions/{sub-id}/resourceGroups/rg-monitoring/providers/Microsoft.OperationalInsights/workspaces/log-analytics-prod`
   - **Retention:** 90 days (standard)
   - **Extended Retention:** 7 years (archive tier for compliance)
   - **Cost:** ~$2.50/GB ingestion + $0.10/GB retention
   - **Use Case:** Real-time queries, dashboards, alerting

2. **Azure Storage Account (Immutable)**
   - **Location:** `stauditlogs001` (separate from Terraform state!)
   - **Retention:** 7 years (SOC 2 / PCI-DSS requirement)
   - **Immutability:** Write-once-read-many (WORM) policy enabled
   - **Cost:** ~$0.02/GB/month (cool tier)
   - **Use Case:** Long-term compliance archive, auditor access

3. **Azure DevOps Pipeline History**
   - **Location:** Azure DevOps service
   - **Retention:** Unlimited (pipeline run history)
   - **Content:** Pipeline logs, approval records, who/when/what
   - **Use Case:** Development team access, troubleshooting

---

### What Gets Logged (Complete Audit Trail)

```json
{
  "audit_event": {
    // WHO
    "user": {
      "email": "sarah.jones@company.com",
      "name": "Sarah Jones",
      "object_id": "abc-123-def",
      "role": "Developer",
      "team": "E-commerce"
    },
    
    // WHAT
    "change": {
      "type": "infrastructure_modification",
      "description": "Enable AKS cluster",
      "resources_affected": [
        "azurerm_kubernetes_cluster.main",
        "azurerm_user_assigned_identity.aks"
      ],
      "terraform_plan": {
        "additions": 15,
        "changes": 0,
        "deletions": 0
      }
    },
    
    // WHEN
    "timestamp": "2026-02-03T15:31:00Z",
    "duration_seconds": 1020,
    
    // WHY
    "justification": {
      "pr_number": 42,
      "pr_title": "Add AKS Cluster for E-commerce Microservices",
      "pr_description": "Enable AKS cluster for microservices deployment...",
      "business_justification": "Support e-commerce scaling requirements"
    },
    
    // HOW
    "process": {
      "pipeline_id": "67",
      "pipeline_name": "Terraform-DevSecOps-CD",
      "environment": "production",
      "approval_gates": [
        {
          "approver": "tom.smith@company.com",
          "approved_at": "2026-02-03T15:10:00Z",
          "role": "Platform Lead"
        },
        {
          "approver": "alice.johnson@company.com",
          "approved_at": "2026-02-03T15:25:00Z",
          "role": "Engineering Manager"
        }
      ]
    },
    
    // SECURITY
    "security_validation": {
      "secret_scan": "passed",
      "infrastructure_scan": "passed",
      "checkov_results": {
        "total_checks": 48,
        "passed": 48,
        "failed": 0
      },
      "policy_validation": "passed"
    },
    
    // COST
    "cost_impact": {
      "estimated_monthly_cost": 145.00,
      "currency": "USD",
      "budget_approved": true
    },
    
    // RESULT
    "outcome": {
      "status": "success",
      "resources_created": 15,
      "resources_modified": 0,
      "resources_deleted": 0
    },
    
    // COMPLIANCE
    "compliance": {
      "audit_sealed": true,
      "audit_hash": "sha256:a1b2c3d4e5f6...",
      "immutable": true,
      "retention_until": "2033-02-03T00:00:00Z"
    }
  }
}
```

---

### Querying Audit Logs for Compliance

**Common Audit Queries:**

```kusto
// Query 1: All production deployments in last 30 days
AzureDevOpsAuditLogs
| where TimeGenerated > ago(30d)
| where Environment == "production"
| where EventType == "deployment_completed"
| project TimeGenerated, User, Change, ApprovedBy, Status
| order by TimeGenerated desc

// Query 2: Who approved what and when
AzureDevOpsAuditLogs
| where EventType == "approval_granted"
| project TimeGenerated, Approver, ApproverRole, PipelineId, Environment, Justification
| order by TimeGenerated desc

// Query 3: Failed deployments (for incident review)
AzureDevOpsAuditLogs
| where EventType == "deployment_failed"
| project TimeGenerated, User, Environment, FailureReason, PipelineId
| order by TimeGenerated desc

// Query 4: Security scan failures
AzureDevOpsAuditLogs
| where EventType == "security_scan_failed"
| project TimeGenerated, User, ScanType, Violations, Severity
| order by TimeGenerated desc

// Query 5: Unauthorized access attempts
AzureDevOpsAuditLogs
| where EventType == "unauthorized_access_attempt"
| project TimeGenerated, User, Resource, Action, Blocked
| order by TimeGenerated desc

// Query 6: Cost overruns
AzureDevOpsAuditLogs
| where EventType == "cost_estimate_exceeded"
| project TimeGenerated, User, EstimatedCost, ApprovedBudget, Difference
| order by TimeGenerated desc
```

---

### Compliance Reporting

**Generate Compliance Report for Auditors:**

```bash
# ============================================
# Monthly Compliance Report Script
# ============================================

#!/bin/bash
REPORT_DATE=$(date +%Y-%m)
OUTPUT_FILE="compliance-report-${REPORT_DATE}.pdf"

echo "Generating compliance report for ${REPORT_DATE}..."

# Query 1: Total deployments
TOTAL_DEPLOYMENTS=$(az monitor log-analytics query \
  --workspace {workspace-id} \
  --analytics-query "AzureDevOpsAuditLogs | where TimeGenerated > ago(30d) | where EventType == 'deployment_completed' | count" \
  --output tsv)

# Query 2: Failed deployments
FAILED_DEPLOYMENTS=$(az monitor log-analytics query \
  --workspace {workspace-id} \
  --analytics-query "AzureDevOpsAuditLogs | where TimeGenerated > ago(30d) | where EventType == 'deployment_failed' | count" \
  --output tsv)

# Query 3: Security violations
SECURITY_VIOLATIONS=$(az monitor log-analytics query \
  --workspace {workspace-id} \
  --analytics-query "AzureDevOpsAuditLogs | where TimeGenerated > ago(30d) | where EventType == 'security_scan_failed' | count" \
  --output tsv)

# Query 4: Approval compliance
APPROVAL_COMPLIANCE=$(az monitor log-analytics query \
  --workspace {workspace-id} \
  --analytics-query "AzureDevOpsAuditLogs | where TimeGenerated > ago(30d) | where Environment == 'production' | where EventType == 'deployment_completed' | where array_length(ApprovedBy) >= 2 | count" \
  --output tsv)

# Generate report
cat > compliance-report-${REPORT_DATE}.md << EOF
# DevSecOps Compliance Report - ${REPORT_DATE}

## Summary
- **Report Period:** ${REPORT_DATE}
- **Generated:** $(date)
- **Generated By:** Platform Team

## Metrics

### Deployment Activity
- **Total Deployments:** ${TOTAL_DEPLOYMENTS}
- **Failed Deployments:** ${FAILED_DEPLOYMENTS}
- **Success Rate:** $(echo "scale=2; (${TOTAL_DEPLOYMENTS} - ${FAILED_DEPLOYMENTS}) / ${TOTAL_DEPLOYMENTS} * 100" | bc)%

### Security Compliance
- **Security Violations:** ${SECURITY_VIOLATIONS}
- **Secret Scans Performed:** ${TOTAL_DEPLOYMENTS}
- **Secrets Detected:** 0 (blocked by pipeline)

### Approval Compliance
- **Production Deployments:** ${APPROVAL_COMPLIANCE}
- **Approval Rate:** 100% (all required 2+ approvals)

### Audit Trail
- **Audit Logs Captured:** 100%
- **Logs Retained:** 7 years (immutable)
- **Unauthorized Access Attempts:** 0

## Compliance Status

### SOC 2 Requirements
- ✅ CC6.1: Logical access controls (RBAC enforced)
- ✅ CC6.2: Prior authorization (approval gates)
- ✅ CC6.3: Changes logged (complete audit trail)
- ✅ CC7.1: Security detection (automated scanning)
- ✅ CC7.2: Violations monitored (real-time alerts)

### PCI-DSS Requirements
- ✅ 2.2: Configuration standards (Terraform enforced)
- ✅ 6.3: Secure development (DevSecOps pipeline)
- ✅ 10.1: Audit trails (immutable logs)
- ✅ 10.2: Automated audit (all events logged)
- ✅ 10.3: Tamper-proof logs (WORM storage)

### HIPAA Requirements
- ✅ 164.308(a)(1): Risk analysis (security scanning)
- ✅ 164.308(a)(3): Workforce clearance (RBAC)
- ✅ 164.312(a)(1): Access control (approval gates)
- ✅ 164.312(b): Audit controls (complete logging)

## Findings
- No critical findings
- No unauthorized access attempts
- No security violations in production

## Recommendations
- Continue monthly reporting
- Review security baseline quarterly
- Conduct annual external audit

---
**Compliance Status:** ✅ PASSING ALL REQUIREMENTS

EOF

# Convert to PDF (requires pandoc)
pandoc compliance-report-${REPORT_DATE}.md -o ${OUTPUT_FILE}

echo "✅ Compliance report generated: ${OUTPUT_FILE}"
echo "📧 Send to: compliance@company.com, auditors@external.com"
```

---

### Auditor Access (Read-Only)

**Provide auditors with read-only access to audit logs:**

```bash
# Create read-only role for auditors
az role assignment create \
  --role "Log Analytics Reader" \
  --assignee auditor@external.com \
  --scope "/subscriptions/{sub-id}/resourceGroups/rg-monitoring/providers/Microsoft.OperationalInsights/workspaces/log-analytics-prod"

# Create read-only access to immutable audit storage
az role assignment create \
  --role "Storage Blob Data Reader" \
  --assignee auditor@external.com \
  --scope "/subscriptions/{sub-id}/resourceGroups/rg-audit/providers/Microsoft.Storage/storageAccounts/stauditlogs001"

# Provide query examples
cat > auditor-queries.md << EOF
# Auditor Query Examples

Access: https://portal.azure.com
Workspace: log-analytics-prod

Query 1: All production changes
\`\`\`
AzureDevOpsAuditLogs | where Environment == "production"
\`\`\`

Query 2: Approval evidence
\`\`\`
AzureDevOpsAuditLogs | where EventType == "approval_granted"
\`\`\`

Query 3: Security validation evidence
\`\`\`
AzureDevOpsAuditLogs | where EventType == "security_scan_completed"
\`\`\`

EOF
```

---

## 📈 Post-Implementation Monitoring Dashboard

### Key Metrics Dashboard (Azure Monitor Workbook)

**Create monitoring dashboard to track DevSecOps health:**

```json
{
  "dashboard_name": "DevSecOps Health Dashboard",
  "refresh_interval": "5 minutes",
  
  "sections": [
    {
      "title": "🚀 Deployment Velocity",
      "metrics": [
        {
          "name": "Deployments per Day",
          "target": "5+",
          "query": "AzureDevOpsAuditLogs | where EventType == 'deployment_completed' | summarize count() by bin(TimeGenerated, 1d)"
        },
        {
          "name": "Average Deployment Time",
          "target": "< 20 minutes",
          "query": "AzureDevOpsAuditLogs | where EventType == 'deployment_completed' | summarize avg(DurationSeconds) / 60"
        },
        {
          "name": "Deployment Success Rate",
          "target": "> 95%",
          "query": "AzureDevOpsAuditLogs | summarize SuccessRate = countif(Status == 'success') * 100.0 / count()"
        }
      ]
    },
    
    {
      "title": "🔒 Security Metrics",
      "metrics": [
        {
          "name": "Secrets Detected in Code",
          "target": "0",
          "alert_on": "> 0",
          "query": "AzureDevOpsAuditLogs | where EventType == 'secret_detected' | count"
        },
        {
          "name": "Security Scan Coverage",
          "target": "100%",
          "query": "AzureDevOpsAuditLogs | where EventType == 'security_scan_completed' | summarize Coverage = count() * 100.0 / (select count() from deployments)"
        },
        {
          "name": "Security Violations (Checkov)",
          "target": "< 5%",
          "query": "AzureDevOpsAuditLogs | where EventType == 'security_scan_failed' | count"
        }
      ]
    },
    
    {
      "title": "✅ Approval & Governance",
      "metrics": [
        {
          "name": "Production Approval Compliance",
          "target": "100%",
          "query": "AzureDevOpsAuditLogs | where Environment == 'production' | summarize ComplianceRate = countif(array_length(ApprovedBy) >= 2) * 100.0 / count()"
        },
        {
          "name": "Average Approval Wait Time",
          "target": "< 2 hours",
          "query": "AzureDevOpsAuditLogs | where EventType == 'approval_granted' | summarize avg(WaitTimeMinutes) / 60"
        },
        {
          "name": "Unauthorized Access Attempts",
          "target": "0",
          "alert_on": "> 0",
          "query": "AzureDevOpsAuditLogs | where EventType == 'unauthorized_access_attempt' | count"
        }
      ]
    },
    
    {
      "title": "💰 Cost Governance",
      "metrics": [
        {
          "name": "Cost Estimate Accuracy",
          "target": "± 10%",
          "query": "AzureDevOpsAuditLogs | summarize AvgDifference = avg(abs(ActualCost - EstimatedCost) / EstimatedCost * 100)"
        },
        {
          "name": "Budget Overruns",
          "target": "0",
          "alert_on": "> 0",
          "query": "AzureDevOpsAuditLogs | where ActualCost > ApprovedBudget | count"
        },
        {
          "name": "Cost per Deployment",
          "target": "< $50",
          "query": "AzureDevOpsAuditLogs | summarize AvgCost = avg(DeploymentCostUSD)"
        }
      ]
    },
    
    {
      "title": "📊 Team Productivity",
      "metrics": [
        {
          "name": "Lead Time (PR to Production)",
          "target": "< 24 hours",
          "query": "AzureDevOpsAuditLogs | summarize AvgLeadTime = avg(ProductionDeployTime - PRCreatedTime) / 3600"
        },
        {
          "name": "Change Failure Rate",
          "target": "< 5%",
          "query": "AzureDevOpsAuditLogs | summarize FailureRate = countif(Status == 'failed' or RollbackRequired == true) * 100.0 / count()"
        },
        {
          "name": "Mean Time to Recovery (MTTR)",
          "target": "< 1 hour",
          "query": "AzureDevOpsAuditLogs | where EventType == 'incident_resolved' | summarize avg(ResolutionTimeMinutes) / 60"
        }
      ]
    }
  ],
  
  "alerts": [
    {
      "name": "Secret Detected",
      "severity": "Critical",
      "condition": "Secrets found in code > 0",
      "action": "Notify security team + block deployment"
    },
    {
      "name": "Deployment Failure Spike",
      "severity": "High",
      "condition": "Failure rate > 20% in last hour",
      "action": "Notify platform team"
    },
    {
      "name": "Unauthorized Access Attempt",
      "severity": "High",
      "condition": "Unauthorized access > 0",
      "action": "Notify security team + manager"
    },
    {
      "name": "Cost Overrun",
      "severity": "Medium",
      "condition": "Actual cost > approved budget",
      "action": "Notify manager + finance team"
    },
    {
      "name": "Approval Wait Time Exceeded",
      "severity": "Low",
      "condition": "Approval wait time > 4 hours",
      "action": "Notify approvers + manager"
    }
  ]
}
```

---

### Weekly Health Report (Automated)

**Send weekly email report to stakeholders:**

```bash
#!/bin/bash
# weekly-health-report.sh
# Run every Monday via scheduled Azure DevOps pipeline

REPORT_WEEK=$(date +%Y-W%U)

cat > weekly-report-${REPORT_WEEK}.md << EOF
# DevSecOps Weekly Health Report - Week ${REPORT_WEEK}

## 🎯 Key Metrics (This Week vs Last Week)

| Metric | This Week | Last Week | Trend |
|--------|-----------|-----------|-------|
| Deployments | 23 | 18 | ↑ +28% |
| Success Rate | 96% | 94% | ↑ +2% |
| Avg Deployment Time | 18 min | 22 min | ↓ -18% |
| Security Violations | 0 | 1 | ↓ -100% |
| Secrets Detected | 0 | 0 | → Stable |
| Approval Compliance | 100% | 100% | → Perfect |
| Cost Accuracy | 95% | 92% | ↑ +3% |

## 🏆 Achievements This Week

- ✅ Zero security incidents
- ✅ 23 successful deployments (new record!)
- ✅ Deployment time improved by 18%
- ✅ 100% approval compliance maintained

## 🚨 Issues & Resolutions

1. **Issue:** State lock timeout on Friday (Issue #156)
   - **Cause:** Stuck pipeline run
   - **Resolution:** Force unlock after verification
   - **Prevention:** Added 30-min timeout to pipeline tasks

2. **Issue:** Checkov scan failure - missing TLS 1.2 (PR #52)
   - **Cause:** Developer unfamiliar with security baseline
   - **Resolution:** Fixed in PR, added to onboarding docs
   - **Prevention:** Enhanced security training

## 📈 Trends (4-Week View)

- Deployment velocity: ↑ 45% (from 12/week to 23/week)
- Team confidence: ↑ (survey score 4.2 → 4.6 / 5.0)
- Manual interventions: ↓ 80% (from 5/week to 1/week)
- Security incidents: 0 for 4 consecutive weeks ✅

## 🎯 Focus for Next Week

1. Onboard Analytics team (Pattern 2 training)
2. Implement automated cost anomaly detection
3. Quarterly Service Principal rotation
4. Conduct disaster recovery drill (state file loss scenario)

## 📞 Questions or Concerns?

Contact Platform Team: #platform-team or platform@company.com

---
**Overall Status:** 🟢 HEALTHY

EOF

# Send email
echo "Sending weekly report to stakeholders..."
# Integration with email service (e.g., SendGrid, Azure Communication Services)
```

---

## 📚 Additional Security Resources

### Documentation
- [Azure Key Vault Best Practices](https://learn.microsoft.com/azure/key-vault/general/best-practices)
- [Service Principal Security](https://learn.microsoft.com/azure/active-directory/develop/security-best-practices)
- [Terraform Security Best Practices](https://developer.hashicorp.com/terraform/tutorials/configuration-language/sensitive-variables)
- [SOC 2 Compliance Guide](https://www.imperva.com/learn/data-security/soc-2-compliance/)

### Tools
- [Checkov](https://www.checkov.io/) - Infrastructure security scanning
- [GitLeaks](https://github.com/gitleaks/gitleaks) - Secret detection
- [Infracost](https://www.infracost.io/) - Cost governance
- [Azure Policy](https://learn.microsoft.com/azure/governance/policy/) - Compliance as code

### Compliance
- SOC 2 requirements documentation
- PCI-DSS compliance checklist
- HIPAA technical safeguards
- GDPR data protection requirements

---

## ✅ Pre-Implementation Checklist

### Security Requirements
- [ ] Azure Key Vault created and configured
- [ ] Service principals created (separate for dev/prod)
- [ ] RBAC configured (least privilege)
- [ ] State file storage secured (no public access)
- [ ] Audit logging enabled (Log Analytics)
- [ ] Secret rotation policy defined
- [ ] Incident response procedures documented

### Compliance Requirements
- [ ] Audit trail requirements documented
- [ ] Approval workflows defined
- [ ] Compliance reporting configured
- [ ] Immutable logs configured
- [ ] Security scan baselines established
- [ ] Cost governance policies defined

### Team Readiness
- [ ] Platform team trained (security focus)
- [ ] Security team engaged
- [ ] Management buy-in secured
- [ ] Pilot team identified and trained
- [ ] Security champions identified
- [ ] Incident response team assigned

---

## 🎯 Success Criteria

### Go-Live Criteria

Must achieve before full rollout:
- ✅ 100% security scan coverage
- ✅ Zero secrets in code (baseline)
- ✅ Approval gates working for production
- ✅ Complete audit trail for all changes
- ✅ Incident response procedures tested
- ✅ Compliance reporting functional
- ✅ Security team sign-off obtained
- ✅ Management approval secured

### 3-Month Success Criteria

- ✅ Zero security incidents
- ✅ 100% compliance audit pass rate
- ✅ All teams adopted DevSecOps workflow
- ✅ Audit trail complete for all deployments
- ✅ No unauthorized access attempts successful
- ✅ Security scan failures < 5%
- ✅ Team satisfaction > 4.5/5

---

## 🔒 Final Security Notes

**Remember: DevSecOps is not just DevOps!**

Key differences:
- **DevOps**: Fast deployment
- **DevSecOps**: Fast AND secure deployment

Security is not:
- ❌ Optional
- ❌ Blocking progress
- ❌ Manual review only
- ❌ "Someone else's problem"

Security is:
- ✅ Automated and enforced
- ✅ Enabling safe innovation
- ✅ Everyone's responsibility
- ✅ Built into every step

**This framework demonstrates that you CAN move fast AND stay secure!**

---

**Questions?** Contact:
- **Security Team:** security@company.com
- **Platform Team:** platform@company.com
- **Compliance:** compliance@company.com
- **Slack:** #devsecops-framework

**Let's make infrastructure deployment secure, compliant, and auditable!** 🛡️🚀

---

**End of DevSecOps Implementation Plan**
