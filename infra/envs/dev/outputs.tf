# =============================================================================
# OUTPUTS - Values displayed after "terraform apply"
# =============================================================================
# 🎓 WHAT ARE OUTPUTS? After Terraform creates resources, these values are
#    printed to the screen and stored in state. Useful for:
#    1. Seeing what was created (resource names, IDs, URLs)
#    2. Other Terraform configs can READ these (terraform_remote_state)
#    3. CI/CD pipelines can capture these values
# =============================================================================

output "resource_group_name" {
  description = "Resource group name (used by Pattern 2 teams to find Platform resources)"
  value       = azurerm_resource_group.main.name
}

output "vnet_id" {
  description = "Virtual network ID"
  value       = module.networking.vnet_id
}

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID"
  value       = azurerm_log_analytics_workspace.main.id
}

output "deployment_info" {
  description = "Deployment information"
  value = {
    environment    = "Development"
    resource_group = azurerm_resource_group.main.name
    location       = var.location
    vnet_name      = module.networking.vnet_name
    log_analytics  = azurerm_log_analytics_workspace.main.name
  }
}

# =============================================================================
# PATTERN 2 NETWORKING OUTPUTS
# =============================================================================
# 🎓 WHO READS THESE? Pattern 2 teams (CRM, E-commerce) need to know:
#    - What VNet was created for them (name, ID)
#    - What subnets are available (IDs for connecting their resources)
#    They use data sources in their own Terraform configs to read these VNets.
#    See: examples/pattern-2-delegated/dev-app-crm/main.tf (data sources)
# =============================================================================

output "pattern2_crm_vnet" {
  description = "CRM team's VNet information (Pattern 2)"
  value = {
    vnet_id    = module.networking_crm.vnet_id
    vnet_name  = module.networking_crm.vnet_name
    subnet_ids = module.networking_crm.subnet_ids
  }
}

output "pattern2_ecommerce_vnet" {
  description = "E-commerce team's VNet information (Pattern 2)"
  value = {
    vnet_id    = module.networking_ecommerce.vnet_id
    vnet_name  = module.networking_ecommerce.vnet_name
    subnet_ids = module.networking_ecommerce.subnet_ids
  }
}
