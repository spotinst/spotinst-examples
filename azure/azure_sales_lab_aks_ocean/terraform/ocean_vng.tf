resource "spotinst_ocean_aks_np_virtual_node_group" "vng" {
  name      = var.ocean_vng_name
  ocean_id  = module.ocean_aks_np.ocean_id
  min_count = var.ocean_vng_min_count
  max_count = var.ocean_vng_max_count

  availability_zones         = ["1", "2", "3"]
  os_type                    = "Linux"
  os_sku                     = "Ubuntu"
  spot_percentage            = var.ocean_vng_spot_percentage
  fallback_to_ondemand       = true
  should_utilize_commitments = true
}