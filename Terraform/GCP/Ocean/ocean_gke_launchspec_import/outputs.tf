output "launchspec_ids" {
  value = toset([for launchspec in spotinst_ocean_gke_launch_spec.launchspec : launchspec.id ])
  description = "The launchspec (VNG) ID of each nodepool"
}

/*
output "instance_group" {
  value = local.instance_group_name
}
*/