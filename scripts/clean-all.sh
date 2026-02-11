#!/bin/bash
# Clean All Terraform Working Directories
# Removes .terraform/ directories and lock files across the codebase

set -e

echo "=========================================="
echo "Terraform Cleanup - All Directories"
echo "=========================================="
echo ""

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

CLEANED=0

echo "Searching for Terraform working directories..."
echo ""

# Find and remove .terraform directories
while IFS= read -r -d '' dir; do
  echo "  Removing: $dir"
  rm -rf "$dir"
  CLEANED=$((CLEANED + 1))
done < <(find "$REPO_ROOT" -type d -name ".terraform" -print0 2>/dev/null)

# Find and remove lock files
while IFS= read -r -d '' file; do
  echo "  Removing: $file"
  rm -f "$file"
  CLEANED=$((CLEANED + 1))
done < <(find "$REPO_ROOT" -name ".terraform.lock.hcl" -print0 2>/dev/null)

# Find and remove plan files
while IFS= read -r -d '' file; do
  echo "  Removing: $file"
  rm -f "$file"
  CLEANED=$((CLEANED + 1))
done < <(find "$REPO_ROOT" -name "*.tfplan" -o -name "tfplan" -print0 2>/dev/null)

# Find and remove crash logs
while IFS= read -r -d '' file; do
  echo "  Removing: $file"
  rm -f "$file"
  CLEANED=$((CLEANED + 1))
done < <(find "$REPO_ROOT" -name "crash.log" -print0 2>/dev/null)

echo ""
if [ "$CLEANED" -gt 0 ]; then
  echo "✓ Cleaned $CLEANED items"
else
  echo "✓ Nothing to clean — workspace is already clean"
fi
