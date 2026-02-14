# Document 07: Pattern 1 Multi-App (Newbie Guide)

> **Purpose**: Explain the new `infra/envs-multiapp/dev` scenario in beginner language.
> You will learn **who does what**, **what to run first**, **how files connect**, and **how multiple teams work together** in centralized Pattern 1.

---

## Executive Summary (30 seconds)

- Platform Team builds and controls shared foundation first (network, logging, security baseline).
- Application Teams request infrastructure; Platform Team provisions app resources in a central, consistent way.
- Use order: **Platform layer first**, then **App layer**; update platform again only when shared foundation must change.

---

## 0) Non-Technical Quick Explanation (For Managers / Product Owners)

If you are not technical, use this section first.

### What is happening here?

- Your company has one central **Platform Team**.
- Multiple application teams (Ecommerce, CRM, etc.) ask for infrastructure.
- Platform Team prepares and controls infrastructure in a safe order.

### Why this model exists

- Keep governance and security consistent.
- Avoid every team creating infrastructure differently.
- Make onboarding faster with standard templates.

### Real-life analogy

- **Platform layer** = roads, electricity, security gates (shared city infrastructure).
- **App layer** = buildings for each business unit (Ecommerce building, CRM building).

If a new building can use existing roads, only building work is needed.
If new roads are required, city infrastructure must be updated first.

### Who does what (non-technical view)

- **Platform Team**
  - Builds and maintains shared foundation
  - Approves and executes infra changes
- **Application Teams**
  - Request what they need (AKS, DB, Web App, etc.)
  - Deploy their application code after infra is ready

### Simple business workflow

1. Team requests infrastructure
2. Platform checks if existing foundation is enough
3. If yes: create app resources
4. If no: update foundation first, then create app resources

### One-picture summary

```mermaid
flowchart LR
    A[Application Team Request\n"Need AKS + DB"] --> B{Platform Foundation\nAlready Enough?}
    B -- Yes --> C[Platform Team\nCreate App Resources]
    B -- No --> D[Platform Team\nUpdate Shared Foundation First]
    D --> C
    C --> E[Application Team\nDeploy App Code]
```

---

## 1) The Big Idea (Super Simple)

Think of your setup like this:

- **Platform Team** builds shared roads/utilities first (VNet, subnets, logging, security baseline).
- **Application Teams** request app infrastructure (AKS, Cosmos DB).
- In **Pattern 1**, only Platform Team runs Terraform for infra changes.

So the model is:

1. Build shared foundation once (and update only when needed)
2. Add app resources many times

---

## 2) Who Owns What

### Platform Team owns
- `infra/platform/dev/` (shared network + shared monitoring + shared security baseline)
- `infra/envs-multiapp/dev/` (central app onboarding and toggles)

### Application Teams own
- Requirements only (example: “CRM needs AKS + Cosmos DB”)
- Application code deployment into infra after Platform provides it

### Important
Application teams in this scenario do **not** directly provision infra with Terraform.

---

## 3) Folder Roles in This New Scenario

### A. Shared foundation (run first)
- `infra/platform/dev/main.tf`
  - Calls networking module(s)
  - Creates VNet/subnets and log analytics

### B. Central multi-app onboarding (run second)
- `infra/envs-multiapp/dev/main.tf`
  - Reads shared platform resources using `data` blocks
  - Creates app resources using module calls:
    - `module "aks_ecommerce"`
    - `module "cosmosdb_ecommerce"`
    - `module "aks_crm"`
    - `module "cosmosdb_crm"`

### C. Input values (toggles and settings)
- `infra/envs-multiapp/dev/variables.tf`
  - Declares expected inputs (`enable_crm_aks`, etc.)
- `infra/envs-multiapp/dev/base.dev.tfvars`
  - Common baseline values
- `infra/envs-multiapp/dev/ecommerce.dev.tfvars`
  - Ecommerce toggles
- `infra/envs-multiapp/dev/crm.dev.tfvars`
  - CRM toggles

### D. State files
- Platform state: `platform-dev.tfstate`
- Multiapp app-layer state: `dev.multiapp.terraform.tfstate`

> This means platform and app-layer are separated (safer), but all apps in `envs-multiapp/dev` still share one app-layer state.

---

## 4) Why `data "azurerm_subnet" "aks"` Exists

In `infra/envs-multiapp/dev/main.tf`, this block:

```hcl
data "azurerm_subnet" "aks" {
  name                 = "aks-subnet"
  virtual_network_name = data.azurerm_virtual_network.platform.name
  resource_group_name  = data.azurerm_virtual_network.platform.resource_group_name
}
```

means:

- “Do not create subnet here.”
- “Read existing subnet created by platform layer.”

Then this value is used in AKS modules:

```hcl
vnet_subnet_id = data.azurerm_subnet.aks.id
```

So app-layer AKS depends on platform-layer subnet.

---

## 5) Execution Order (What To Run, In Order)

## Step 0 — One-time backend setup (if not done yet)

### What is "backend init script"?

Terraform needs a place to store its **state file** (the record of what it created).
In this framework, state is stored in Azure Storage (remote backend), not local disk.

The backend init script creates these Azure resources:

- Resource Group: `contoso-tfstate-rg`
- Storage Account: `stcontosotfstate001`
- Blob Container: `tfstate`

Without this storage, `terraform init` for remote backend will fail.

### When do I run it?

- Run once when setting up a new subscription/project.
- Run again only if backend storage was deleted or changed.

### Which script to run?

Windows PowerShell:

```powershell
cd scripts
./init-backend.ps1
```

Linux/macOS:

```bash
cd scripts
./init-backend.sh
```

After backend exists, continue with Step 1 (platform layer), then Step 2 (app layer).

## Step 0.5 — Confirm Azure subscription and tenant context

Before `terraform plan`, verify you are targeting the intended Azure subscription.

```powershell
az account show --query "{subscription:id, tenant:tenantId, name:name}" -o table
az account set --subscription "<YOUR_SUBSCRIPTION_ID_OR_NAME>"
```

Also make sure `subscription_id` and `tenant_id` in your tfvars are correct:

- `infra/platform/dev/dev.tfvars`
- `infra/envs-multiapp/dev/base.dev.tfvars` (or `dev.tfvars` in legacy mode)

## Step 1 — Deploy Platform Layer first

```powershell
cd infra/platform/dev
terraform init
terraform plan -var-file="dev.tfvars"
terraform apply -var-file="dev.tfvars"
```

Why first?
- Because app-layer uses data sources to read platform resources.
- If platform not created, app-layer data source lookup fails.

## Step 2 — Deploy Multi-App App Layer

Example: Ecommerce first

```powershell
cd infra/envs-multiapp/dev
terraform init
terraform plan -var-file="base.dev.tfvars" -var-file="ecommerce.dev.tfvars"
terraform apply -var-file="base.dev.tfvars" -var-file="ecommerce.dev.tfvars"
```

## Step 3 — Onboard CRM later (no structural code change)

```powershell
cd infra/envs-multiapp/dev
terraform plan -var-file="base.dev.tfvars" -var-file="ecommerce.dev.tfvars" -var-file="crm.dev.tfvars"
terraform apply -var-file="base.dev.tfvars" -var-file="ecommerce.dev.tfvars" -var-file="crm.dev.tfvars"
```

Terraform will add only missing CRM resources.

---

## 6) How Terraform Decides Create vs Skip

Each module uses this pattern:

```hcl
count = var.enable_crm_aks ? 1 : 0
```

- If variable is `true` → module instance is created.
- If variable is `false` → module instance is skipped.

So `crm.dev.tfvars` is “just toggles”, but those toggles directly control module creation in `main.tf`.

---

## 7) How `*.tfvars` Files Work Together

Terraform merges var files from left to right.

Example:

```powershell
terraform plan -var-file="base.dev.tfvars" -var-file="ecommerce.dev.tfvars" -var-file="crm.dev.tfvars"
```

- `base` loads common defaults.
- `ecommerce` overrides Ecommerce toggles.
- `crm` overrides CRM toggles.
- If same variable appears multiple times, the **last file wins**.

---

## 8) Team Flow (Human Process)

### Business-friendly version

- Ecommerce and CRM do not fight over infrastructure changes.
- Platform team coordinates changes and timing.
- This reduces operational risk and improves auditability.

### Day 1 (Ecommerce only)
1. Ecommerce team requests AKS + Cosmos DB.
2. Platform team enables Ecommerce toggles (`ecommerce.dev.tfvars`).
3. Platform team applies in `envs-multiapp/dev`.
4. Ecommerce app team receives endpoints/cluster info and deploys app code.

### Day 30 (CRM joins)
1. CRM team requests AKS + Cosmos DB.
2. Platform team enables CRM toggles (`crm.dev.tfvars`).
3. Platform team applies again.
4. Terraform adds CRM resources without recreating existing Ecommerce resources (unless changed).

---

## 9) When To Re-run Platform Layer

You do **not** re-run platform for every app onboarding.

Re-run platform only when shared foundation changes, for example:
- new subnet needed
- new NSG rule needed
- shared logging/security settings change

If app can use existing platform subnet/logging, only app-layer apply is needed.

### New requirement example: "Need Web App + PostgreSQL"

If a team asks for new services (for example Web App + PostgreSQL), check this first:

1. Can they use existing shared subnets/security from platform?
2. Do they need new subnet/NSG/private endpoint/DNS rules?

#### Case A — Existing platform is enough

- No platform change needed.
- Add module blocks/toggles in app layer (`infra/envs-multiapp/dev`).
- Apply app layer only.

#### Case B — New network/security is needed

- Update platform layer first (`infra/platform/dev`) to add required foundation:
  - new subnet(s)
  - NSG rules
  - private endpoint subnet / DNS links (if required)
  - any shared monitoring/security dependency
- Apply platform layer first.
- Then update/apply app layer.

### Rule of thumb for newbies

- **Platform layer** = shared roads and security gates
- **App layer** = houses (AKS/WebApp/PostgreSQL/CosmosDB)

If a new house needs a new road or new gate, update platform first.

---

## 10) Common Newbie Mistakes

1. **Running app-layer before platform-layer**
   - causes data source errors (subnet/vnet not found)

2. **Turning toggle from true to false without understanding impact**
   - Terraform will plan to destroy that app’s infra in this root module

3. **Thinking modules are executed directly**
   - modules are templates; root module (`envs-multiapp/dev/main.tf`) calls them

4. **Confusing multiple tfvars with multiple states**
   - many tfvars files can still map to one state file

---

## 11) Quick Reference Cheat Sheet

- Foundation first: `infra/platform/dev`
- App onboarding second: `infra/envs-multiapp/dev`
- Modules = reusable templates in `infra/modules/*`
- Toggles live in tfvars, logic lives in `main.tf`
- Pattern 1 here = centralized infra operation by Platform Team

### 30-second summary (for non-technical users)

- Platform team controls infrastructure lifecycle.
- App teams request; platform provisions.
- Shared foundation is reused across many apps.
- Foundation changes are occasional; app onboarding changes are frequent.

---

## 12) If You Need 1 State per App Later

Current `envs-multiapp/dev` keeps one app-layer state for centralized operation.

If later you want stronger isolation:
- create one root folder per app (or move to Pattern 2 per team)
- each root gets its own backend key/state file

That is a maturity evolution, not a failure of current design.

---

## 13) Production Best Practice (Super Beginner, Non-Technical)

This section explains **the production standard** in plain language for non-technical readers.

### Executive summary (1 minute)

- Keep **platform** and **app** infrastructure as separate layers.
- Keep separate Terraform state files for each layer.
- Use approval flow: **plan → review → apply**.
- Put secrets/identity in pipeline or secure identity flow, not in plain repository files.

This is the common enterprise approach because it is safer, easier to audit, and easier to scale.

### Easy analogy

Think of a city:

- Platform layer (`infra/platform/dev`) = roads, electricity, water, security gates
- App layer (`infra/envs-multiapp/dev`) = houses/shops built by business teams

If one shop changes, you should not risk breaking city roads.
That is why production systems separate these layers.

### Why some values look repeated (normal behavior)

You may see same fields in both roots:

- `organization_name`, `project_name`, `environment`, `location`
- `subscription_id`, `tenant_id`

Reason:

- Terraform variables are read **per root module**.
- `platform/dev` and `envs-multiapp/dev` are separate roots.
- So each root needs input values.

This is expected behavior, not an architecture mistake.

### Decision guide (non-technical)

Use this quick rule:

1. Does the request need new shared network/security/foundation?
   - **Yes** → run platform first, then app layer.
   - **No** → run app layer only.

2. Is this just onboarding a new app/team using existing foundation?
   - **Yes** → app layer only.

3. Is this a compliance/security baseline update?
   - **Yes** → platform first.

### Real use-case examples

#### Example A — Fast onboarding (no platform change)

Request:
- New team needs AKS + Cosmos DB.
- Existing subnet and monitoring are already enough.

Action:
- Skip platform deployment.
- Update app toggles/module inputs.
- Run app-layer plan/apply.

Result:
- Faster delivery.
- Lower risk to shared foundation.

#### Example B — Security enhancement (platform first)

Request:
- Need new subnet, NSG rule, or private endpoint policy.

Action:
- Update and apply platform first.
- Then apply app layer.

Result:
- Correct dependency order.
- Better audit trail and rollback control.

#### Example C — Deployment incident isolation

Situation:
- App-layer deployment fails.

Result with this model:
- Platform remains stable because state is separate.

Business impact:
- Smaller outage risk.
- Faster recovery.

### Advantages (why enterprises choose this)

- **Safety**: app failures are less likely to impact shared platform baseline.
- **Governance**: approvals and audit evidence are cleaner by layer.
- **Scalability**: one platform can support many app teams.
- **Reusability**: standard modules and patterns are reused consistently.
- **Operational clarity**: everyone knows what is platform change vs app change.

### Trade-offs (acceptable in production)

- More files and commands than a single all-in-one root.
- Teams must follow execution order rules.
- Some common values appear in multiple inputs unless centralized.

Why still best practice:

- In production, safety, control, and auditability are more important than fewer commands.

### Recommended operating model (simple)

- Keep two layers and two state files.
- Keep one shared non-secret environment input source (common vars).
- Keep layer-specific toggles in each root.
- Use secure identity and CI/CD variables for auth values.

### Final takeaway

- Separation is intentional and professional.
- It reduces risk while keeping delivery fast.
- Best mental model: **stable foundation, flexible app onboarding**.

---

*Related files for this guide:*
- `infra/platform/dev/main.tf`
- `infra/envs-multiapp/dev/main.tf`
- `infra/envs-multiapp/dev/variables.tf`
- `infra/envs-multiapp/dev/base.dev.tfvars`
- `infra/envs-multiapp/dev/ecommerce.dev.tfvars`
- `infra/envs-multiapp/dev/crm.dev.tfvars`
