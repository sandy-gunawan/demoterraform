# Container App Module
# =============================================================================
# 🎓 WHAT IS THIS MODULE? Creates a Container Apps Environment.
#    The "environment" is like a shared hosting space for multiple container apps.
#    Individual apps are deployed LATER (via CI/CD or az containerapp create).
#
# 🎓 ANALOGY: This creates the "apartment building" (environment).
#    Your team deploys "apartments" (container apps) into it later.
#
# 🎓 WHY CONTAINER APPS vs AKS?
#    Container Apps: Serverless, auto-scale to zero, simpler, pay-per-use
#    AKS: Full Kubernetes control, larger scale, more complex
# =============================================================================

resource "azurerm_container_app_environment" "env" {
  name                       = var.environment_name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  log_analytics_workspace_id = var.log_analytics_workspace_id
  infrastructure_subnet_id   = var.infrastructure_subnet_id

  tags = var.tags
}

# Note: Container apps are created separately when you deploy your application
# This module just creates the environment (the "home" for your apps)
