output "environment_id" {
  description = "Container App Environment ID"
  value       = azurerm_container_app_environment.env.id
}

output "environment_name" {
  description = "Container App Environment name"
  value       = azurerm_container_app_environment.env.name
}

output "default_domain" {
  description = "Default domain for the Container App Environment"
  value       = azurerm_container_app_environment.env.default_domain
}
