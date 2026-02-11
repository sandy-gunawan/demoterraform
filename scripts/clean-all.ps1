# Clean All Terraform Working Directories
# Removes .terraform/ directories and lock files across the codebase

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Terraform Cleanup - All Directories" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

$RepoRoot = Split-Path -Parent $PSScriptRoot
$Cleaned = 0

Write-Host "Searching for Terraform working directories..."
Write-Host ""

# Remove .terraform directories
Get-ChildItem -Path $RepoRoot -Recurse -Directory -Filter ".terraform" -ErrorAction SilentlyContinue | ForEach-Object {
    Write-Host "  Removing: $($_.FullName)"
    Remove-Item -Path $_.FullName -Recurse -Force
    $Cleaned++
}

# Remove lock files
Get-ChildItem -Path $RepoRoot -Recurse -File -Filter ".terraform.lock.hcl" -ErrorAction SilentlyContinue | ForEach-Object {
    Write-Host "  Removing: $($_.FullName)"
    Remove-Item -Path $_.FullName -Force
    $Cleaned++
}

# Remove plan files
Get-ChildItem -Path $RepoRoot -Recurse -File -Filter "*.tfplan" -ErrorAction SilentlyContinue | ForEach-Object {
    Write-Host "  Removing: $($_.FullName)"
    Remove-Item -Path $_.FullName -Force
    $Cleaned++
}
Get-ChildItem -Path $RepoRoot -Recurse -File -Filter "tfplan" -ErrorAction SilentlyContinue | ForEach-Object {
    Write-Host "  Removing: $($_.FullName)"
    Remove-Item -Path $_.FullName -Force
    $Cleaned++
}

# Remove crash logs
Get-ChildItem -Path $RepoRoot -Recurse -File -Filter "crash.log" -ErrorAction SilentlyContinue | ForEach-Object {
    Write-Host "  Removing: $($_.FullName)"
    Remove-Item -Path $_.FullName -Force
    $Cleaned++
}

Write-Host ""
if ($Cleaned -gt 0) {
    Write-Host "✓ Cleaned $Cleaned items" -ForegroundColor Green
} else {
    Write-Host "✓ Nothing to clean — workspace is already clean" -ForegroundColor Green
}
