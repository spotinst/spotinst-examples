module "ocean_aks_np" {
  source  = "spotinst/ocean-aks-np-k8s/spotinst"
  version = "0.18.0"

  spotinst_token                         = var.spotinst_token
  spotinst_account                       = var.spotinst_account
  ocean_cluster_name                     = var.cluster_name
  controller_cluster_id                  = var.cluster_name
  aks_cluster_name                       = azurerm_kubernetes_cluster.k8s.name
  aks_region                             = azurerm_resource_group.rg.location
  aks_resource_group_name                = azurerm_resource_group.rg.name
  aks_infrastructure_resource_group_name = azurerm_kubernetes_cluster.k8s.node_resource_group
  availability_zones                     = ["1", "2", "3"]
  node_min_count                         = var.ocean_node_min_count
  node_max_count                         = var.ocean_node_max_count
  spot_percentage                        = var.ocean_spot_percentage
  fallback_to_ondemand                   = true
}

resource "spotinst_ocean_right_sizing_cluster_config" "automatic" {
  cluster_identifier = var.cluster_name
  ocean_id           = module.ocean_aks_np.ocean_id

  config {
    adjust_limit_on_downsize          = true
    downside_only                     = true
    recommendations_cpu_percentile    = var.ocean_rightsizing_cpu_percentile
    recommendations_memory_percentile = var.ocean_rightsizing_memory_percentile
  }
}