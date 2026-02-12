organization_name = "contoso"
project_name      = "contoso"
environment       = "prod"
location          = "indonesiacentral"
tenant_id         = "00000000-0000-0000-0000-000000000000"
cost_center       = "Engineering-Production"
owner_email       = "devops@contoso.com"
repository_url    = "https://dev.azure.com/contoso/terraform-infrastructure"

enable_nat_gateway         = true
enable_key_vault           = true
enable_private_endpoints   = true
enable_ddos_protection     = true
key_vault_purge_protection = true
network_acl_default_action = "Deny"
log_retention_days         = 90
