# Pattern 1 Multi-Team Sandbox (Parallel Setup)

This folder is a **separate root module** for experimenting with centralized multi-team Pattern 1.

- Existing setup remains at `infra/envs/dev` (unchanged)
- This sandbox uses a different state key: `dev.multiapp.terraform.tfstate`
- Platform layer dependency is still required: `infra/platform/dev`

## How to run

1. Deploy platform first (once):
   - `cd infra/platform/dev`
   - `terraform apply -var-file="dev.tfvars"`

2. Run this sandbox (split tfvars):
   - `cd infra/envs-multiapp/dev`
   - `terraform init`
   - `terraform plan -var-file="base.dev.tfvars" -var-file="ecommerce.dev.tfvars"`
   - `terraform apply -var-file="base.dev.tfvars" -var-file="ecommerce.dev.tfvars"`

3. Add CRM later (no code change needed):
   - `terraform plan -var-file="base.dev.tfvars" -var-file="ecommerce.dev.tfvars" -var-file="crm.dev.tfvars"`
   - `terraform apply -var-file="base.dev.tfvars" -var-file="ecommerce.dev.tfvars" -var-file="crm.dev.tfvars"`

4. Legacy mode (still supported):
   - `terraform plan -var-file="dev.tfvars"`
   - `terraform apply -var-file="dev.tfvars"`

## Team onboarding flow (example)

- Base config is in `base.dev.tfvars`
- Team overlays are in `ecommerce.dev.tfvars` and `crm.dev.tfvars`
- Add a new team by creating another overlay file and passing another `-var-file`
- Terraform merges files from left to right; last file wins on duplicates

This demonstrates multi-team usage while staying centralized (Pattern 1).
