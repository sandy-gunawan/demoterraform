# Global Module Outputs
# =============================================================================
# 🎓 THESE OUTPUTS are consumed by every environment (dev/staging/prod).
#    When an environment does: module "global_standards" { source = "../../global" }
#    It can access these via: module.global_standards.common_tags
#
# 🎓 MOST IMPORTANT OUTPUT: common_tags
#    Every resource in the framework uses this for consistent tagging.
#    Tags help with: cost tracking, ownership, compliance, resource grouping.
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
