resource "spotinst_ocean_ecs_launch_spec" "launchspec" {
  name = var.name
  ocean_id = var.ocean_id

  ## Block Device Mappings ##
  block_device_mappings {
    device_name = var.device_name
    ebs {
      delete_on_termination = var.delete_on_termination
      encrypted = var.encrypted
      iops = var.iops
      kms_key_id = var.kms_key_id
      snapshot_id = var.snapshot_id
      volume_type = var.volume_type
      volume_size = var.volume_size
      throughput = var.throughput
      dynamic_volume_size {
        base_size = var.base_size
        resource = var.resource
        size_per_resource_unit = var.size_per_resource_unit
      }
      no_device = var.no_device
    }
  }


}