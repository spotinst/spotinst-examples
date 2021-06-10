#Output the Spot Ocean ID for the newly created Ocean Cluster
output "ocean_id" {
	value = module.ocean_ecs.ocean_id
}
