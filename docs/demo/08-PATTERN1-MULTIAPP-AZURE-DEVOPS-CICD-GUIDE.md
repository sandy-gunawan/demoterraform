# Document 08: Pattern 1 Multi-App + Azure DevOps CI/CD (Beginner to Expert)

> **Purpose**: Explain how to run the new `infra/envs-multiapp/dev` model with Azure DevOps CI/CD for non-technical, beginner, and technical audiences.

---

## Executive Summary (Non-Technical)

- Platform team operates one standard delivery process for all app teams.
- Shared foundation is deployed first (`infra/platform/dev`), then app resources (`infra/envs-multiapp/dev`).
- Azure DevOps automates checks, approvals, and deployment so teams move faster with lower risk.

---

## 1) Audience Guide

### For Non-Technical (Manager / Product Owner)
- This process standardizes how teams request and receive infrastructure.
- It reduces deployment errors and gives approval/audit control.
- New apps are onboarded by toggles/inputs, not by reinventing Terraform each time.

### For Newbies (Terraform/Azure DevOps beginner)
- You will mostly interact with:
  - `infra/platform/dev`
  - `infra/envs-multiapp/dev`
  - `*.tfvars` files for app onboarding
  - Azure DevOps pipelines for plan/apply

### For Technical Readers
- This guide maps root modules, backend/state separation, pipeline stages, OIDC auth, approvals, and profile-based var-file execution.

---

## 2) What "Good" Looks Like in This Scenario

You have **2 root modules** in dev:

1. **Platform Layer** (shared foundation)
   - Folder: `infra/platform/dev`
   - Own state: `platform-dev.tfstate`
   - Creates VNet/subnets/NSGs/Log Analytics/Key Vault baseline

2. **App Layer (Multi-App Pattern 1)**
   - Folder: `infra/envs-multiapp/dev`
   - Own state: `dev.multiapp.terraform.tfstate`
   - Creates app resources (AKS/CosmosDB/etc.) based on team toggles/profile tfvars

This separation means:
- Platform is stable and shared.
- App onboarding can iterate faster.
- Failing app change does not corrupt platform state.

---

## 3) End-to-End Flow (Business + Technical)

```mermaid
flowchart TB
    R[App Team Request\n"Need AKS + CosmosDB"] --> A[Platform Team Triage]
    A --> B{Need new shared\nnetwork/security?}

    B -- Yes --> P1[Update infra/platform/dev]
    P1 --> P2[CI: validate/plan/security/cost]
    P2 --> P3[Approval + CD apply\nplatform-dev.tfstate]

    B -- No --> M1[Update envs-multiapp tfvars/profile]
    P3 --> M1
    M1 --> M2[CI: validate/plan/security/cost]
    M2 --> M3[Approval + CD apply\ndev.multiapp.terraform.tfstate]
    M3 --> D[App Team deploys app code]
```

---

## 4) Who Does What

### Platform Team
- Maintains Terraform framework and shared modules
- Owns `infra/platform/dev` and `infra/envs-multiapp/dev`
- Reviews/approves infra change requests
- Runs/owns CI/CD pipelines and service connections

### Application Teams (Ecommerce/CRM/etc.)
- Submit infra requirements (AKS, DB, networking constraints)
- Validate plan output for business impact
- Deploy application code after infra is ready

### Governance Team / Security Team (optional but recommended)
- Reviews security scan findings
- Owns approval policy for staging/prod environments

---

## 5) Azure DevOps CI/CD Model for This Setup

## 5.1 Recommended Pipeline Split

Use separate pipelines per layer:

- **Platform CI/CD**
  - Working directory: `infra/platform/dev`
  - State: `platform-dev.tfstate`

- **Multi-App CI/CD**
  - Working directory: `infra/envs-multiapp/dev`
  - State: `dev.multiapp.terraform.tfstate`

Why split?
- Clear ownership and approvals
- Smaller plans
- Lower blast radius

## 5.2 Existing Pipeline Files in This Repo

Current templates already include good foundations:

- `pipelines/ci-terraform-plan.yml`
  - Secret scanning (GitLeaks)
  - Terraform fmt/validate/plan
  - Security scanning (Checkov)
  - Cost estimation (Infracost)

- `pipelines/cd-terraform-apply.yml`
  - Prepare + validation
  - Approval-gated deployment
  - Post-deployment verification

## 5.3 What to Adjust for `envs-multiapp`

Current CI/CD YAML defaults to `infra/envs/<environment>`. For multi-app, point pipeline to:

- `infra/envs-multiapp/dev`

And use profile-based var files, for example:

- `base.dev.tfvars + ecommerce.dev.tfvars`
- `base.dev.tfvars + ecommerce.dev.tfvars + crm.dev.tfvars`

## 5.4 New Pipeline Parameters (Already Added in YAML)

Both CI and CD now support:

- `environment` (dev/staging/prod)
- `deploymentTarget`:
  - `infra/envs` (old Pattern 1)
  - `infra/platform` (platform layer)
  - `infra/envs-multiapp` (new multi-app Pattern 1)
- `varFiles` (optional, comma-separated)

Examples:

- Platform run:
  - `deploymentTarget=infra/platform`
  - `environment=dev`
  - `varFiles=dev.tfvars`

- Multi-app Ecommerce only:
  - `deploymentTarget=infra/envs-multiapp`
  - `environment=dev`
  - `varFiles=base.dev.tfvars,ecommerce.dev.tfvars`

- Multi-app Ecommerce + CRM:
  - `deploymentTarget=infra/envs-multiapp`
  - `environment=dev`
  - `varFiles=base.dev.tfvars,ecommerce.dev.tfvars,crm.dev.tfvars`

---

## 6) Azure DevOps UI Steps (Menu-by-Menu for Beginners)

### 6.1 Create CI Pipeline (Plan/Scan)

1. Open Azure DevOps project
2. Left menu → **Pipelines** → **Pipelines**
3. Click **New pipeline**
4. Choose source: **Azure Repos Git**
5. Select repository
6. Choose **Existing Azure Pipelines YAML file**
7. Select file: `pipelines/ci-terraform-plan.yml`
8. Click **Continue**
9. Click dropdown next to **Run** → **Save** (or **Save and run**)

### 6.2 Create CD Pipeline (Apply)

Repeat same menu path with file:

- `pipelines/cd-terraform-apply.yml`

### 6.3 Configure Service Connection Permissions

1. **Project Settings** (bottom-left)
2. **Service connections**
3. Open `sc-azure-oidc-or-mi`
4. Ensure:
  - connection works (Verify)
  - pipeline has access (Grant access or authorize on first run)

### 6.4 Configure Environment Approval Gate (for CD)

1. Left menu → **Pipelines** → **Environments**
2. Create/select environment (e.g., `dev`)
3. Environment page → **Approvals and checks**
4. Add **Approvals** check
5. Add approvers (Platform Lead / Security Lead)
6. Save

Now CD deployment job pauses for manual approval.

---

## 7) Exactly When To Execute Which Pipeline

### Trigger CI (Plan) when:
- Pull Request is opened/updated
- You changed Terraform code, tfvars, pipeline YAML

### Trigger CD (Apply) when:
- PR already merged
- Plan reviewed and approved
- You are ready to change real Azure resources

### Platform vs App execution timing

1. Run **Platform** first if shared infra changed (subnet/NSG/logging/security)
2. Then run **Multi-app** for onboarding/update app resources

If no platform change, run only multi-app pipeline.

---

## 8) Manual Run Instructions in Azure DevOps (Click-by-Click)

### 8.1 Run CI for Multi-App Ecommerce only

1. Pipelines → open CI pipeline
2. Click **Run pipeline**
3. Fill parameters:
  - `environment`: `dev`
  - `deploymentTarget`: `infra/envs-multiapp`
  - `varFiles`: `base.dev.tfvars,ecommerce.dev.tfvars`
4. Click **Run**

### 8.2 Run CD for Multi-App Ecommerce only

1. Pipelines → open CD pipeline
2. Click **Run pipeline**
3. Fill parameters same as CI:
  - `environment`: `dev`
  - `deploymentTarget`: `infra/envs-multiapp`
  - `varFiles`: `base.dev.tfvars,ecommerce.dev.tfvars`
4. Click **Run**
5. Wait for approval prompt in Environment
6. Approver clicks **Approve**
7. Pipeline applies infrastructure

### 8.3 Run Multi-App with CRM onboarded

Use:

- `varFiles=base.dev.tfvars,ecommerce.dev.tfvars,crm.dev.tfvars`

---

## 9) What Each CI Stage Does (Beginner Friendly)

In `ci-terraform-plan.yml`:

1. **SecretScan**
  - Finds leaked secrets/keys in repo
2. **Validate**
  - Terraform formatting + syntax correctness
3. **Plan**
  - Shows what Azure changes will happen
4. **SecurityScan (Checkov)**
  - Checks IaC security misconfigurations
5. **CostEstimation (Infracost)**
  - Estimates monthly cost impact

If any critical stage fails, stop and fix before merge.

---

## 10) What CD Does (Apply + Verify)

In `cd-terraform-apply.yml`:

1. **PrepareApply**
  - Validates folder and required files exist
2. **DeployInfrastructure**
  - `terraform init`
  - fresh pre-apply plan
  - approval-gated `terraform apply`
3. **PostDeployment**
  - validates resource existence from Terraform outputs

This gives control + proof that deployment actually worked.

---

## 11) Operator Playbook (Who clicks what)

### Platform Engineer
- Updates Terraform/tfvars
- Runs CI on PR
- Reviews plan/security/cost outputs

### Reviewer / Tech Lead
- Reviews PR and plan summary
- Checks drift, risk, and impact

### Approver (Manager/Security/Platform Lead)
- Approves CD environment gate

### App Team
- Validates requested infra is provisioned
- Deploys app code after infra is ready

---

## 12) Troubleshooting Quick Guide

### Error: "Environment directory not found"
- Check `deploymentTarget` and `environment` parameters
- Confirm folder exists in repo

### Error: "Required file missing"
- Check `varFiles` names and commas
- Ensure files exist in selected target directory

### Error: Data source not found (VNet/Subnet)
- Platform layer not applied yet
- Run platform deployment first

### Error: Service connection unauthorized
- Re-authorize `sc-azure-oidc-or-mi`
- Check service connection permission for pipeline

### Error: CD stuck waiting
- Expected behavior if approval gate enabled
- Approver must approve in Environments page

---

## 13) Practical Newbie Runbook (Manual + CI/CD)

## Step 0 — One-time prerequisites
- Azure backend exists (state storage)
- OIDC service connection works in Azure DevOps
- Dev environment approval gate configured

## Step 1 — Platform deployment (if needed)

Local/manual:

```powershell
cd infra/platform/dev
terraform init
terraform plan -var-file="dev.tfvars"
terraform apply -var-file="dev.tfvars"
```

CI/CD equivalent:
- Run Platform CI on PR
- Approve Platform CD apply for dev

## Step 2 — Multi-app onboarding (Ecommerce first)

Local/manual:

```powershell
cd infra/envs-multiapp/dev
terraform init
terraform plan -var-file="base.dev.tfvars" -var-file="ecommerce.dev.tfvars"
terraform apply -var-file="base.dev.tfvars" -var-file="ecommerce.dev.tfvars"
```

CI/CD equivalent:
- Run Multi-App CI on PR
- Review plan + security + cost
- Approve Multi-App CD apply

## Step 3 — Add CRM later

```powershell
cd infra/envs-multiapp/dev
terraform plan -var-file="base.dev.tfvars" -var-file="ecommerce.dev.tfvars" -var-file="crm.dev.tfvars"
terraform apply -var-file="base.dev.tfvars" -var-file="ecommerce.dev.tfvars" -var-file="crm.dev.tfvars"
```

Terraform adds only missing CRM resources.

---

## 14) Minimal Pipeline Parameter Strategy (Recommended)

Use a `profile` parameter in Azure DevOps to choose var-file combinations.

Example profiles:
- `ecommerce-only`
- `ecommerce-crm`
- `all-enabled`

Then map profile to var files in script:

- always include `base.dev.tfvars`
- append profile overlays

This keeps one central pipeline while supporting staged onboarding.

---

## 15) Technical Flow: How Files Execute

1. Terraform loads `variables.tf` schema.
2. Terraform merges `-var-file` values (left to right; last wins).
3. Terraform evaluates `main.tf`:
   - reads data sources from platform resources
   - evaluates `count` expressions for each module
4. Terraform creates/updates only modules with `count = 1`.
5. Terraform writes final result to app-layer state file.

Important:
- `data` blocks are read-only lookups.
- `module` blocks are template calls to `infra/modules/*`.

---

## 16) What Teams Can / Cannot Do

### Can do
- Request new app infrastructure in standard format
- Review plan output before approval
- Onboard gradually by profile/toggles

### Cannot do (in this Pattern 1 model)
- Directly run production infra changes without platform approval
- Bypass shared governance/security controls
- Change shared platform foundation from app-layer pipelines

---

## 17) Benefits vs Risks (Honest View)

### Benefits
- Standardized team behavior
- Better auditability and approvals
- Faster onboarding after foundation is stable
- Reuse of shared modules and policies

### Risks / Tradeoffs
- App-layer still shares one state in `envs-multiapp/dev`
- Platform team remains a central gate (possible bottleneck)
- Toggle off can destroy resources if not controlled by change policy

Mitigation:
- Strict approval gates
- Protected branches
- Plan review checklist
- Decommission process (2-step approval)

---

## 18) Non-Technical Demo Script (Client-Friendly)

Use this story during demo:

1. "Platform team builds safe shared foundation once."
2. "Ecommerce team requests AKS + DB, platform enables profile, pipeline plans and deploys."
3. "CRM joins later, we add CRM profile and deploy only incremental change."
4. "Everything is approved, logged, and repeatable in Azure DevOps."

---

## 19) Implementation Checklist

- [ ] Platform folder deployed: `infra/platform/dev`
- [ ] Multi-app folder validated: `infra/envs-multiapp/dev`
- [ ] Service connection (OIDC) configured
- [ ] CI pipeline points to right working directory
- [ ] CD environment approval gate enabled
- [ ] Profile-based var-file strategy documented for operators
- [ ] Plan/security/cost checks required before apply

---

## Related Repository Files

- `infra/platform/dev/main.tf`
- `infra/envs-multiapp/dev/main.tf`
- `infra/envs-multiapp/dev/variables.tf`
- `infra/envs-multiapp/dev/base.dev.tfvars`
- `infra/envs-multiapp/dev/ecommerce.dev.tfvars`
- `infra/envs-multiapp/dev/crm.dev.tfvars`
- `pipelines/ci-terraform-plan.yml`
- `pipelines/cd-terraform-apply.yml`
- `docs/AZURE-DEVOPS-SETUP.md`
