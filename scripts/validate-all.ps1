# Validate All Terraform Configurations
# Runs terraform init (no backend) + terraform validate in every environment

$ErrorActionPreference = "Continue"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Terraform Validation - All Environments" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

$RepoRoot = Split-Path -Parent $PSScriptRoot
$EnvsDir = Join-Path $RepoRoot "infra\envs"

$Pass = 0
$Fail = 0
$Errors = @()

foreach ($envDir in Get-ChildItem -Path $EnvsDir -Directory) {
    $envName = $envDir.Name
    Write-Host "--- Validating: $envName ---"

    Push-Location $envDir.FullName

    # Initialize without backend (for validation only)
    $initResult = terraform init -backend=false -input=false -no-color 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ Init succeeded" -ForegroundColor Green
    } else {
        Write-Host "  ✗ Init FAILED" -ForegroundColor Red
        $Fail++
        $Errors += "  - ${envName}: terraform init failed"
        Pop-Location
        continue
    }

    # Validate configuration
    $validateResult = terraform validate -no-color 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ Validation passed" -ForegroundColor Green
        $Pass++
    } else {
        Write-Host "  ✗ Validation FAILED" -ForegroundColor Red
        $validateResult | ForEach-Object { Write-Host "    $_" }
        $Fail++
        $Errors += "  - ${envName}: terraform validate failed"
    }

    Pop-Location
    Write-Host ""
}

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "RESULTS" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Passed: $Pass"
Write-Host "  Failed: $Fail"

if ($Fail -gt 0) {
    Write-Host ""
    Write-Host "Errors:" -ForegroundColor Red
    $Errors | ForEach-Object { Write-Host $_ -ForegroundColor Red }
    exit 1
}

Write-Host ""
Write-Host "✓ All environments validated successfully!" -ForegroundColor Green
