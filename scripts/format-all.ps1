# Format all Terraform files in the repository
# PowerShell version

$ErrorActionPreference = "Stop"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Formatting Terraform Files" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Get repository root
$REPO_ROOT = Split-Path -Parent $PSScriptRoot

Write-Host "Repository: $REPO_ROOT"
Write-Host ""

# Format all Terraform files
Write-Host "Running terraform fmt -recursive..." -ForegroundColor Green
Set-Location $REPO_ROOT

terraform fmt -recursive

Write-Host ""
Write-Host "✓ All Terraform files formatted successfully!" -ForegroundColor Green
Write-Host ""
