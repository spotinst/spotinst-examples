# variables for modules
locals {
  spot_token = ""
  spot_account = ""
  project = ""
  cluster_name = ""
  location = ""
}


## Create Ocean Cluster and deploy controller pod
module "ocean_gke" {
  source = "./ocean_gke"

  # Spot Credentials
  spot_token = local.spot_token
  spot_account = local.spot_account

  project = local.project
  # GKE information
  cluster_name = local.cluster_name
  location = local.location
}

output "ocean_id" {
  value = module.ocean_gke.ocean_id
}
output "controller_id" {
  value = module.ocean_gke.controller-id
}

/*
## Import all existing node groups as launchspecs (VNG)
### Note you will be unable to edit any of the settings of the VNG, it will match the node pool in GKE ###
module "ocean_gke_launchspec_import" {
  source = "./ocean_gke_launchspec_import"

  # Spot Credentials
  spot_token = local.spot_token
  spot_account = local.spot_account

  project = local.project
  # GKE information
  cluster_name = local.cluster_name
  location = local.location

  ocean_id = module.ocean_gke.ocean_id

}

output "launchspec_ids" {
  value = module.ocean_gke_launchspec_import.launchspec_ids
}
*/

## Create a new custom launchspec (VNG) by importing default and changing settings
module "ocean_gke_launchspec_stateless" {
  source = "./ocean_gke_launchspec"

  # Spot Credentials
  spot_token = local.spot_token
  spot_account = local.spot_account

  project = local.project
  # GKE information
  cluster_name = local.cluster_name
  location = local.location

  ocean_id = module.ocean_gke.ocean_id

  # Add Labels or taints
  labels = [{key="type",value="stateless"}]
  taints = [{key="type",value="stateless",effect="NoSchedule"}]
}
