# Landing Zone Configuration Values

organization_name  = "contoso"
location           = "indonesiacentral"
secondary_location = "eastasia"
tenant_id          = "12345678-1234-1234-1234-123456789012" # Replace with your tenant ID

# Hub network configuration
hub_address_space = "10.0.0.0/16"

# Define spoke networks for different applications/teams
spoke_networks = {
  # Production AKS workloads
  "prod-aks" = {
    address_space = "10.1.0.0/16"
    environment   = "production"
    application   = "aks-workloads"
  }

  # Production web services
  "prod-web" = {
    address_space = "10.2.0.0/16"
    environment   = "production"
    application   = "web-services"
  }

  # Production API services
  "prod-api" = {
    address_space = "10.3.0.0/16"
    environment   = "production"
    application   = "api-services"
  }

  # Staging environment
  "staging" = {
    address_space = "10.4.0.0/16"
    environment   = "staging"
    application   = "all-services"
  }

  # Development and testing
  "dev-test" = {
    address_space = "10.10.0.0/16"
    environment   = "development"
    application   = "dev-test"
  }
}

# Centralized logging
log_retention_days = 90

# Tags
tags = {
  CostCenter  = "Platform"
  Owner       = "platform-team@contoso.com"
  Criticality = "High"
  Compliance  = "ISO27001"
  Purpose     = "Landing Zone"
}
