#!/bin/bash
# Validate All Terraform Configurations
# Runs terraform init (no backend) + terraform validate in every environment

set -e

echo "=========================================="
echo "Terraform Validation - All Environments"
echo "=========================================="
echo ""

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
ENVS_DIR="$REPO_ROOT/infra/envs"

PASS=0
FAIL=0
ERRORS=""

for env_dir in "$ENVS_DIR"/*/; do
  env_name=$(basename "$env_dir")
  echo "─── Validating: $env_name ───"

  cd "$env_dir"

  # Initialize without backend (for validation only)
  if terraform init -backend=false -input=false -no-color > /dev/null 2>&1; then
    echo "  ✓ Init succeeded"
  else
    echo "  ✗ Init FAILED"
    FAIL=$((FAIL + 1))
    ERRORS="$ERRORS\n  - $env_name: terraform init failed"
    continue
  fi

  # Validate configuration
  if terraform validate -no-color > /dev/null 2>&1; then
    echo "  ✓ Validation passed"
    PASS=$((PASS + 1))
  else
    echo "  ✗ Validation FAILED"
    terraform validate -no-color 2>&1 | sed 's/^/    /'
    FAIL=$((FAIL + 1))
    ERRORS="$ERRORS\n  - $env_name: terraform validate failed"
  fi

  echo ""
done

echo "=========================================="
echo "RESULTS"
echo "=========================================="
echo "  Passed: $PASS"
echo "  Failed: $FAIL"

if [ "$FAIL" -gt 0 ]; then
  echo ""
  echo "Errors:"
  echo -e "$ERRORS"
  exit 1
fi

echo ""
echo "✓ All environments validated successfully!"
