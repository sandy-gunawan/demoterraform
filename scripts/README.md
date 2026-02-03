# Helper Scripts for Terraform Operations

This folder contains utility scripts to simplify common Terraform operations.

## Available Scripts

### `init-backend.sh` / `init-backend.ps1`
Initializes the Terraform backend (Azure Storage Account) for storing state files.

**Usage**:
```bash
# Linux/Mac
./scripts/init-backend.sh

# Windows PowerShell
.\scripts\init-backend.ps1
```

### `format-all.sh` / `format-all.ps1`
Formats all Terraform files in the repository to ensure consistency.

**Usage**:
```bash
# Linux/Mac
./scripts/format-all.sh

# Windows PowerShell
.\scripts\format-all.ps1
```

### `validate-all.sh` / `validate-all.ps1`
Validates all Terraform configurations across all environments.

**Usage**:
```bash
# Linux/Mac
./scripts/validate-all.sh

# Windows PowerShell
.\scripts\validate-all.ps1
```

### `clean-all.sh` / `clean-all.ps1`
Cleans up Terraform temporary files (.terraform, tfstate, etc.)

**Usage**:
```bash
# Linux/Mac
./scripts/clean-all.sh

# Windows PowerShell
.\scripts\clean-all.ps1
```

## Usage Guidelines

1. **Always run from the repository root** - Scripts expect to be in the scripts/ folder
2. **Check prerequisites** - Ensure Azure CLI and Terraform are installed
3. **Review before executing** - Read the script to understand what it does
4. **Use in development** - These are primarily for local development, CI/CD pipelines have their own processes
