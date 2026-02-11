# Azure Policies Directory
# =============================================================================
# This directory contains policy-as-code definitions for governance.
#
# Structure:
#   policies/
#   ├── README.md              (this file)
#   ├── azure-policy/          (Azure Policy definitions)
#   │   ├── allowed-locations.json
#   │   ├── require-tags.json
#   │   └── deny-public-ip.json
#   ├── opa/                   (Open Policy Agent / Conftest)
#   │   ├── terraform.rego
#   │   └── naming.rego
#   └── sentinel/              (HashiCorp Sentinel - if using TFC/TFE)
#       └── restrict-vm-sizes.sentinel
#
# USAGE:
# These policies are enforced at different stages:
# 1. Pre-commit: OPA policies run locally and in CI
# 2. CI Pipeline: Checkov + tfsec scan Terraform code
# 3. Azure Policy: Enforced at the Azure resource level
# 4. Approval Gates: CD pipeline requires human approval for prod
# =============================================================================
