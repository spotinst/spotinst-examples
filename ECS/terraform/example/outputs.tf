#Output the Spot Ocean ID for the newly created Ocean Cluster
output "ocean_id" {
	value = module.spot_ocean_ecs.ocean_id
}
