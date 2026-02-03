# Azure Kubernetes Service (AKS) Module
# =============================================================================
# Simplified AKS module that uses the provided resource group.
# Auto-scaling and node configuration are controlled via environment toggles.
# =============================================================================

resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix
  kubernetes_version  = var.kubernetes_version

  default_node_pool {
    name                = "default"
    node_count          = var.enable_auto_scaling ? null : var.node_count
    vm_size             = var.vm_size
    enable_auto_scaling = var.enable_auto_scaling
    min_count           = var.enable_auto_scaling ? var.node_count : null
    max_count           = var.enable_auto_scaling ? var.max_node_count : null
    vnet_subnet_id      = var.vnet_subnet_id
    
    upgrade_settings {
      max_surge = "10%"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    load_balancer_sku = "standard"
    service_cidr      = var.service_cidr
    dns_service_ip    = var.dns_service_ip
  }

  # Security configurations based on environment
  azure_policy_enabled = var.enable_azure_policy

  oms_agent {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  # Only enable AAD RBAC if tenant_id is provided
  dynamic "azure_active_directory_role_based_access_control" {
    for_each = var.tenant_id != "" ? [1] : []
    content {
      managed                = true
      azure_rbac_enabled     = true
      tenant_id              = var.tenant_id
      admin_group_object_ids = var.admin_group_object_ids
    }
  }

  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count
    ]
  }
}
