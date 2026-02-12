organization_name = "contoso"
project_name      = "contoso"
environment       = "staging"
location          = "indonesiacentral"
tenant_id         = "00000000-0000-0000-0000-000000000000"
cost_center       = "Engineering-Staging"
owner_email       = "devops@contoso.com"
repository_url    = "https://dev.azure.com/contoso/terraform-infrastructure"

enable_nat_gateway         = false
enable_key_vault           = true
key_vault_purge_protection = true
network_acl_default_action = "Deny"
log_retention_days         = 60
