# Global Module Outputs
# =============================================================================
# These outputs expose the standardized naming and tagging values to all
# environments that consume this module via:
#   module "global_standards" { source = "../../global" }
# =============================================================================

output "common_tags" {
  description = "Common tags to apply to all resources (standard + additional)"
  value       = local.common_tags
}

output "standard_tags" {
  description = "Standard tags only (without additional environment-specific tags)"
  value       = local.standard_tags
}

output "resource_names" {
  description = "Standardized resource names based on naming convention"
  value       = local.resource_names
}

output "naming" {
  description = "Naming components (organization, project, environment, location)"
  value       = local.naming
}

output "location_short" {
  description = "Location abbreviations for resources with length limits"
  value       = local.location_short
}
