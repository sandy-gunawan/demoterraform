#!/bin/bash
# Format all Terraform files in the repository

set -e

echo "=========================================="
echo "Formatting Terraform Files"
echo "=========================================="
echo ""

# Get repository root
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Repository: $REPO_ROOT"
echo ""

# Format all Terraform files
echo "Running terraform fmt -recursive..."
cd "$REPO_ROOT"

terraform fmt -recursive

echo ""
echo "✓ All Terraform files formatted successfully!"
echo ""
echo "Files modified:"
git diff --name-only | grep '\.tf$' || echo "  No files were modified"
echo ""
