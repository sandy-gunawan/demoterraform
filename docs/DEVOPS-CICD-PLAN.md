# 🚀 DevOps CI/CD Plan for Terraform Infrastructure

**Purpose:** Document how Azure DevOps CI/CD applies to Terraform infrastructure deployment, meeting BSI's requirements for standardized IaC with governance gates and DevSecOps baseline.

**Status:** ⚠️ Partially Implemented (CI pipeline with DevSecOps stages ready, CD pipeline ready)  
**Created:** 2026-02-03  
**Priority:** Medium (implement after core framework is stable)

---

## 🎯 BSI's Requirements

> "Accelerate BSI's provisioning of Landing Zone and AKS by standardizing Terraform (IaC) and Azure DevOps pipelines (plan/apply with governance gates), establishing a practical DevSecOps baseline (secrets, approvals, auditability, scanning where applicable)"

**Key Requirements:**
1. ✅ Standardized Terraform (IaC)
2. ✅ Azure DevOps pipelines for plan/apply
3. ✅ Governance gates (approvals)
4. ⚠️ DevSecOps baseline (needs enhancement)
   - ✅ Secrets management
   - ✅ Approvals
   - ✅ Auditability
   - ⚠️ Security scanning (TO ADD)

---

## 💡 Key Concept: Infrastructure CI/CD vs Application CI/CD

You have **TWO separate CI/CD pipelines**:

### 1. Infrastructure CI/CD (This Framework)
- **What:** Deploy Terraform infrastructure (AKS, VNet, Cosmos DB)
- **Tool:** Azure DevOps Pipelines + Terraform
- **Location:** `pipelines/` in this repo
- **Secrets:** Service Principal, state storage keys
- **Approvals:** Before production infrastructure changes

### 2. Application CI/CD (Your App Repos)
- **What:** Deploy application code to AKS
- **Tool:** Azure DevOps Pipelines + kubectl/helm
- **Location:** Your application repositories (separate)
- **Secrets:** Database connection strings, API keys
- **Approvals:** Before production app deployments

**This plan focuses on #1 (Infrastructure CI/CD)**

---

## ✅ What's Already Implemented

| Feature | Status | Location | Notes |
|---------|--------|----------|-------|
| **CI Pipeline** | ✅ Done | `.azuredevops/pipelines/terraform-ci.yml` | Runs on PR: validate, plan |
| **CD Pipeline** | ✅ Done | `.azuredevops/pipelines/terraform-cd.yml` | Runs on merge: apply |
| **Reusable Templates** | ✅ Done | `.azuredevops/pipelines/templates/` | DRY principle |
| **OIDC Authentication** | ✅ Done | Uses workload identity | No stored secrets |
| **Multi-Environment** | ✅ Done | dev, staging, prod stages | Separate stages |
| **State Management** | ✅ Done | Azure Storage backend | Remote state |
| **Approval Gates** | ✅ Documented | Environment protection | Need to configure |
| **Secrets Management** | ✅ Documented | Variable groups | Need to create |
| **Audit Trail** | ✅ Automatic | Azure DevOps logs | Built-in |

---

## ⚠️ What Needs to Be Added

### 1. Security Scanning (HIGH PRIORITY)

**Why:** BSI requirement mentions "scanning where applicable"

**Tools to integrate:**
- **Checkov**: Terraform security scanner (Python-based)
- **tfsec**: Terraform security scanner (Go-based, faster)
- **Terrascan**: Policy-as-code scanner

**What it checks:**
- ❌ Publicly accessible storage accounts
- ❌ Missing encryption at rest
- ❌ Weak network security rules
- ❌ Hardcoded secrets in code
- ❌ Non-compliant resource configurations

**Implementation:** See [Security Scanning Implementation](#security-scanning-implementation) section below

---

### 2. Cost Estimation (MEDIUM PRIORITY)

**Why:** Know cost impact before deploying

**Tool:** Infracost

**What it does:**
- Shows estimated monthly cost of changes
- Posts comment on Pull Request with cost diff
- Helps prevent unexpected cost increases

**Example output:**
```
💰 Cost Estimate

Monthly cost will increase by $450 (+15%)

+ azurerm_kubernetes_cluster.main: $350/mo
+ azurerm_cosmosdb_account.main: $100/mo

Total: $3,450/mo → $3,900/mo
```

**Implementation:** See [Cost Estimation Implementation](#cost-estimation-implementation) section below

---

### 3. Policy-as-Code (LOW PRIORITY)

**Why:** Enforce organizational standards

**Tool:** Azure Policy / OPA (Open Policy Agent)

**Examples:**
- All resources must have required tags
- Only specific VM sizes allowed
- All storage must be in specific regions
- No public IP addresses in production

**Implementation:** See [Policy-as-Code Implementation](#policy-as-code-implementation) section below

---

## 🔄 Complete DevSecOps Flow

```
┌─────────────────────────────────────────────────────────────────┐
│ Developer: Update Terraform (enable_cosmosdb = true)           │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│ Create Pull Request                                             │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│ CI Pipeline Triggers (Automatic)                                │
│  ├── terraform fmt -check                                       │
│  ├── terraform validate                                         │
│  ├── Security scan (Checkov) ⚠️ TO ADD                         │
│  ├── Cost estimate (Infracost) ⚠️ TO ADD                       │
│  ├── terraform plan                                             │
│  └── Post results as PR comment                                 │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│ Team Reviews                                                    │
│  ├── Code quality check                                         │
│  ├── Security scan results                                      │
│  ├── Cost impact review                                         │
│  └── Terraform plan output                                      │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     ▼
                ┌────┴────┐
                │ Approve? │
                └────┬─┬──┘
                     │ │
            No ◄─────┘ └─────► Yes
            │                   │
            ▼                   ▼
    ┌─────────────┐    ┌──────────────┐
    │ Fix Issues  │    │  Merge PR    │
    └──────┬──────┘    └──────┬───────┘
           │                   │
           └───────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│ CD Pipeline Triggers (Automatic)                                │
└────────────────────┬────────────────────────────────────────────┘
                     │
         ┌───────────┴───────────┐
         │                       │
         ▼                       ▼
┌─────────────────┐    ┌─────────────────┐
│ Dev Environment │    │ Prod Environment│
│ Auto Deploy     │    │ Wait Approval   │
└────────┬────────┘    └────────┬────────┘
         │                      │
         │                      ▼
         │             ┌─────────────────┐
         │             │ Manager Reviews │
         │             │ Approves        │
         │             └────────┬────────┘
         │                      │
         └──────────┬───────────┘
                    │
                    ▼
         ┌──────────────────────┐
         │ terraform apply      │
         │ Update state         │
         │ Notify team (Teams)  │
         │ Update audit log     │
         └──────────────────────┘
```

---

## 📋 Implementation Plan

### Phase 1: Security Scanning (Week 1-2)

**Goal:** Add Checkov security scanning to CI pipeline

**Steps:**
1. Create security scan template: `.azuredevops/pipelines/templates/terraform-security-scan.yml`
2. Integrate into CI pipeline: `.azuredevops/pipelines/terraform-ci.yml`
3. Configure baseline security rules
4. Test with known violations
5. Document how to interpret results

**Acceptance Criteria:**
- ✅ Checkov runs on every PR
- ✅ Results posted as PR comment
- ✅ Team knows how to fix violations
- ✅ Documentation updated

---

### Phase 2: Cost Estimation (Week 3-4)

**Goal:** Show cost impact on Pull Requests

**Steps:**
1. Sign up for Infracost (free tier)
2. Create cost estimation template
3. Integrate into CI pipeline
4. Configure cost policies (fail if > $X increase)
5. Document cost optimization tips

**Acceptance Criteria:**
- ✅ Cost estimate shown on every PR
- ✅ Alerts if cost increases > 20%
- ✅ Team understands cost impact before merge
- ✅ Documentation updated

---

### Phase 3: Enhanced Governance (Week 5-6)

**Goal:** Add policy-as-code and enhanced approvals

**Steps:**
1. Define organizational policies
2. Implement Azure Policy or OPA
3. Create approval matrix (who approves what)
4. Add break-glass procedure
5. Document governance process

**Acceptance Criteria:**
- ✅ Policies enforced automatically
- ✅ Clear approval workflows
- ✅ Emergency process documented
- ✅ Team trained on policies

---

### Phase 4: Monitoring & Alerting (Week 7-8)

**Goal:** Monitor infrastructure deployments

**Steps:**
1. Set up Teams/Slack notifications
2. Create deployment dashboard
3. Add deployment success metrics
4. Set up alerts for failures
5. Document troubleshooting

**Acceptance Criteria:**
- ✅ Team notified of all deployments
- ✅ Dashboard shows deployment health
- ✅ Failures trigger alerts
- ✅ Troubleshooting guide available

---

## 🔧 Detailed Implementation Guides

### Security Scanning Implementation

#### Step 1: Create Security Scan Template

**File:** `.azuredevops/pipelines/templates/terraform-security-scan.yml`

```yaml
# Security scanning template for Terraform
parameters:
  - name: terraformDirectory
    type: string
    default: 'infra/'
  - name: failOnViolations
    type: boolean
    default: false  # Warning mode initially

steps:
  - task: Bash@3
    displayName: 'Install Checkov'
    inputs:
      targetType: 'inline'
      script: |
        pip install checkov
        checkov --version

  - task: Bash@3
    displayName: 'Run Checkov Security Scan'
    inputs:
      targetType: 'inline'
      workingDirectory: $(System.DefaultWorkingDirectory)
      script: |
        echo "Scanning Terraform code in ${{ parameters.terraformDirectory }}"
        
        checkov \
          --directory ${{ parameters.terraformDirectory }} \
          --framework terraform \
          --output cli \
          --output junitxml \
          --output-file-path $(System.DefaultWorkingDirectory)/checkov-results.xml \
          ${{ eq(parameters.failOnViolations, false) && '--soft-fail' || '' }}
        
        # Generate summary for PR comment
        checkov \
          --directory ${{ parameters.terraformDirectory }} \
          --framework terraform \
          --output json \
          > $(System.DefaultWorkingDirectory)/checkov-summary.json

  - task: PublishTestResults@2
    displayName: 'Publish Security Scan Results'
    inputs:
      testResultsFormat: 'JUnit'
      testResultsFiles: '**/checkov-results.xml'
      testRunTitle: 'Terraform Security Scan (Checkov)'
      failTaskOnFailedTests: ${{ parameters.failOnViolations }}
    condition: always()

  - task: Bash@3
    displayName: 'Generate Scan Summary'
    inputs:
      targetType: 'inline'
      script: |
        echo "## 🔒 Security Scan Results" > $(System.DefaultWorkingDirectory)/scan-summary.md
        echo "" >> $(System.DefaultWorkingDirectory)/scan-summary.md
        
        # Parse JSON and create markdown summary
        python3 << 'EOF'
        import json
        with open('checkov-summary.json') as f:
            data = json.load(f)
        
        summary = data.get('summary', {})
        passed = summary.get('passed', 0)
        failed = summary.get('failed', 0)
        skipped = summary.get('skipped', 0)
        
        with open('scan-summary.md', 'a') as f:
            f.write(f"- ✅ Passed: {passed}\n")
            f.write(f"- ❌ Failed: {failed}\n")
            f.write(f"- ⏭️ Skipped: {skipped}\n")
            f.write(f"\n")
            
            if failed > 0:
                f.write(f"### ⚠️ Failed Checks\n\n")
                for result in data.get('results', {}).get('failed_checks', [])[:5]:
                    f.write(f"- **{result['check_id']}**: {result['check_name']}\n")
                    f.write(f"  - File: `{result['file_path']}`\n")
                    f.write(f"  - Severity: {result.get('severity', 'UNKNOWN')}\n\n")
        EOF

  - task: PublishBuildArtifacts@1
    displayName: 'Publish Scan Summary'
    inputs:
      PathtoPublish: '$(System.DefaultWorkingDirectory)/scan-summary.md'
      ArtifactName: 'security-scan'
    condition: always()
```

---

#### Step 2: Integrate into CI Pipeline

**File:** `.azuredevops/pipelines/terraform-ci.yml`

```yaml
# Add after terraform validate stage
stages:
  # ... existing validation stages ...

  - stage: SecurityScan
    displayName: 'Security Scanning'
    dependsOn: Validate
    jobs:
      - job: Checkov
        displayName: 'Run Checkov Security Scan'
        pool:
          vmImage: 'ubuntu-latest'
        steps:
          - checkout: self

          - template: templates/terraform-security-scan.yml
            parameters:
              terraformDirectory: 'infra/'
              failOnViolations: false  # Start with warnings only

          # Post results to PR
          - task: GitHubComment@0
            displayName: 'Post Scan Results to PR'
            inputs:
              gitHubConnection: 'github-connection'
              repositoryName: '$(Build.Repository.Name)'
              commentType: 'file'
              commentFile: '$(System.DefaultWorkingDirectory)/scan-summary.md'
            condition: and(succeeded(), eq(variables['Build.Reason'], 'PullRequest'))
```

---

#### Step 3: Configure Security Baseline

**File:** `.checkov.yml` (root of repo)

```yaml
# Checkov configuration for BSI's Terraform framework

# Skip specific checks that are known false positives
skip-check:
  # Dev environment can have public access (documented exception)
  - CKV_AZURE_35  # Storage account allows public access (dev only)
  
# Enable specific frameworks
framework:
  - terraform
  
# Output format
output: cli

# Severity threshold (fail on HIGH and CRITICAL)
check:
  - severity: HIGH
  - severity: CRITICAL

# Custom policies directory (if we create custom rules)
external-checks-dir:
  - .checkov-policies/

# Ignore specific directories
skip-path:
  - .terraform/
  - examples/
```

---

### Cost Estimation Implementation

#### Step 1: Sign Up for Infracost

1. Go to https://www.infracost.io/
2. Sign up with GitHub (free tier)
3. Get API key
4. Add to Azure DevOps Variable Group: `INFRACOST_API_KEY`

---

#### Step 2: Create Cost Estimation Template

**File:** `.azuredevops/pipelines/templates/terraform-cost-estimate.yml`

```yaml
# Cost estimation template for Terraform
parameters:
  - name: terraformDirectory
    type: string
  - name: varFile
    type: string

steps:
  - task: Bash@3
    displayName: 'Install Infracost'
    inputs:
      targetType: 'inline'
      script: |
        curl -fsSL https://raw.githubusercontent.com/infracost/infracost/master/scripts/install.sh | sh

  - task: Bash@3
    displayName: 'Generate Cost Estimate'
    env:
      INFRACOST_API_KEY: $(INFRACOST_API_KEY)
    inputs:
      targetType: 'inline'
      workingDirectory: ${{ parameters.terraformDirectory }}
      script: |
        # Generate cost breakdown
        infracost breakdown \
          --path . \
          --terraform-var-file ${{ parameters.varFile }} \
          --format json \
          --out-file infracost-base.json

        # Generate cost diff (if comparing to existing)
        if [ -f "previous-cost.json" ]; then
          infracost diff \
            --path infracost-base.json \
            --compare-to previous-cost.json \
            --format github-comment \
            --out-file cost-comment.md
        else
          infracost output \
            --path infracost-base.json \
            --format github-comment \
            --out-file cost-comment.md
        fi

        # Save for next comparison
        cp infracost-base.json previous-cost.json

  - task: PublishBuildArtifacts@1
    displayName: 'Publish Cost Report'
    inputs:
      PathtoPublish: '${{ parameters.terraformDirectory }}/cost-comment.md'
      ArtifactName: 'cost-estimate'

  - task: GitHubComment@0
    displayName: 'Post Cost to PR'
    inputs:
      gitHubConnection: 'github-connection'
      repositoryName: '$(Build.Repository.Name)'
      commentType: 'file'
      commentFile: '${{ parameters.terraformDirectory }}/cost-comment.md'
    condition: and(succeeded(), eq(variables['Build.Reason'], 'PullRequest'))
```

---

### Policy-as-Code Implementation

**Coming later - to be defined based on BSI's specific policies**

---

## 🔐 Secrets Management Setup

### Variable Groups to Create in Azure DevOps

#### 1. `terraform-secrets` (for Service Principal)

```yaml
# Library > Variable Groups > Create "terraform-secrets"

Variables:
  ARM_CLIENT_ID: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  ARM_CLIENT_SECRET: "*********************" (mark as secret)
  ARM_SUBSCRIPTION_ID: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  ARM_TENANT_ID: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  
  # For state storage
  TF_STATE_RESOURCE_GROUP: "rg-contoso-tfstate"
  TF_STATE_STORAGE_ACCOUNT: "stcontosotfstate001"
  TF_STATE_CONTAINER: "tfstate"
```

#### 2. `infracost-secrets` (for cost estimation)

```yaml
Variables:
  INFRACOST_API_KEY: "ico-*********************" (mark as secret)
```

---

## 👥 Approval Gates Setup

### Environment Configuration in Azure DevOps

#### Dev Environment
```yaml
Name: dev
Approvals: None (auto-deploy)
Branch policy: Any branch
```

#### Staging Environment
```yaml
Name: staging
Approvals: 
  - Any 1 person from: Platform Team
Branch policy: main only
```

#### Production Environment
```yaml
Name: production
Approvals:
  - Required: Platform Team Lead
  - Optional: Security Team (for high-risk changes)
Branch policy: main only
Wait time: 0 hours
Timeout: 24 hours
```

---

## 📊 Success Metrics

Track these to measure effectiveness:

| Metric | Target | Current | Tracking |
|--------|--------|---------|----------|
| **Security Scan Coverage** | 100% of PRs | - | Azure DevOps reports |
| **Failed Security Checks** | < 5 per PR | - | Checkov reports |
| **Cost Overruns** | < 10% of estimate | - | Infracost reports |
| **Approval Time (Prod)** | < 4 hours | - | Azure DevOps analytics |
| **Failed Deployments** | < 5% | - | Pipeline success rate |
| **Time to Deploy** | < 30 minutes | - | Pipeline duration |

---

## 📚 Documentation to Create

When implementing, create these docs:

1. **SECURITY-SCANNING.md**
   - How to interpret Checkov results
   - Common violations and fixes
   - How to suppress false positives

2. **COST-MANAGEMENT.md**
   - How to read Infracost reports
   - Cost optimization tips
   - Budget approval process

3. **GOVERNANCE-POLICY.md**
   - Approval matrix (who approves what)
   - Break-glass procedures
   - Compliance requirements

4. **PIPELINE-TROUBLESHOOTING.md**
   - Common pipeline failures
   - How to debug Terraform in CI/CD
   - Emergency rollback procedures

---

## 🎓 Training Required

### For Platform Team
- [ ] Terraform CI/CD best practices (4 hours)
- [ ] Azure DevOps pipelines advanced (4 hours)
- [ ] Security scanning interpretation (2 hours)
- [ ] Cost optimization strategies (2 hours)

### For App Teams
- [ ] How to create infrastructure PR (1 hour)
- [ ] Reading Terraform plans (1 hour)
- [ ] Understanding security scan results (1 hour)
- [ ] Cost awareness (30 minutes)

---

## 🚧 Known Limitations & Future Enhancements

### Current Limitations
- Security scanning in warning-only mode (not blocking)
- No automated drift detection
- Manual approval process (not integrated with ticketing)
- No automatic rollback on failure

### Future Enhancements (v2.0)
- Automated drift detection and remediation
- Integration with ServiceNow for approvals
- Automatic rollback on failed health checks
- Multi-region deployment orchestration
- Disaster recovery automation

---

## 📞 Getting Help

**Questions about this plan?**
- **Platform Team:** #platform-team Slack
- **Security Team:** security@bsi.com
- **Azure DevOps Support:** devops-admins@bsi.com

**Want to implement a phase?**
1. Create Jira epic for the phase
2. Review plan with Platform Team Lead
3. Schedule team training
4. Start implementation
5. Document as you go

---

## 🔄 Review Schedule

This plan should be reviewed:
- **Monthly:** Progress check during platform sync
- **Quarterly:** Full review and priority adjustment
- **Annually:** Major revision based on lessons learned

**Next Review:** 2026-05-03

---

## ✅ Quick Reference

**When starting implementation:**

1. **Phase 1 (Security Scanning)**
   ```bash
   # Create template
   touch .azuredevops/pipelines/templates/terraform-security-scan.yml
   
   # Create config
   touch .checkov.yml
   
   # Update CI pipeline
   # Edit: .azuredevops/pipelines/terraform-ci.yml
   ```

2. **Phase 2 (Cost Estimation)**
   ```bash
   # Sign up: https://www.infracost.io/
   # Add API key to Variable Group
   # Create template
   touch .azuredevops/pipelines/templates/terraform-cost-estimate.yml
   ```

3. **Test in Dev First**
   ```bash
   # Always test pipeline changes in dev environment
   git checkout -b feature/add-security-scanning
   # Make changes
   # Create PR
   # Verify pipeline runs successfully
   ```

**Remember:** Start small, iterate, improve! 🚀

---

**End of Plan**
