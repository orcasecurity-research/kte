provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

resource "azurerm_resource_group" "aks" {
  name     = var.resource_group_name
  location = var.location
}

module "aks" {
  depends_on = [azurerm_resource_group.aks]
  source     = "Azure/aks/azurerm"
  version    = "8.0.0"

  cluster_name        = var.cluster_name
  resource_group_name = var.resource_group_name
  prefix              = var.prefix

  rbac_aad                        = false
  log_analytics_workspace_enabled = false

  node_pools = {
    node_pool_1 = {
      name    = "nodepool"
      vm_size = "Standard_D2s_v3"
      enable_auto_scaling = true
    }
  }
}