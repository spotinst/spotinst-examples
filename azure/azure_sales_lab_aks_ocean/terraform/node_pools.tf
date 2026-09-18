resource "azurerm_kubernetes_cluster_node_pool" "vmss" {
  for_each = var.vmss_node_pools

  kubernetes_cluster_id = azurerm_kubernetes_cluster.k8s.id
  name                  = each.value.name
  vm_size               = each.value.vm_size
  mode                  = "User"
  os_type               = "Linux"
  os_sku                = "Ubuntu"
  node_count            = each.value.node_count
  auto_scaling_enabled  = false
  min_count             = each.value.min_count
  max_count             = each.value.max_count

  upgrade_settings {
    max_surge                     = "10%"
    drain_timeout_in_minutes      = 0
    node_soak_duration_in_minutes = 0
  }
}