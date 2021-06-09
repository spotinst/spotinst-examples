#Can move these to variables
locals {
  spotinst_token = ""
  spotinst_account = "act-12345"
  cluster_name = "EKS-Workshop"
}

## Create Ocean Cluster in Spot.io and deploy controller pod ##
module "ocean_eks" {
  source = "ocean_eks"

  # Spot.io Credentials
  spotinst_token              = local.spotinst_token
  spotinst_account            = local.spotinst_account

  # Configuration
  cluster_name                = local.cluster_name
  region                      = "us-west-2"
  subnet_ids                  = ["subnet-12345678","subnet-12345678"]
  vpc_id                      = "vpc-123456789"

  # Default Worker node specifics
  # If no AMI is provided will use most up to date one
  #ami_id                      = ""
  # instance profile arn should have the EKSWorkerNodePolicy attached
  worker_instance_profile_arn = "arn:aws:iam::123456789:instance-profile/Spot-EKS-Workshop-Nodegroup"
  security_groups             = ["sg-123456789","sg-123456789"]

  # Additional Tags
  tags = [{key = "CreatedBy", value = "terraform"}]
}

## Create Ocean Virtual Node Group (launchspec) ##
module "ocean_eks_launchspec_stateless" {
  source = "ocean_eks_launchspec"

  # Spot.io Credentials
  spotinst_token              = local.spotinst_token
  spotinst_account            = local.spotinst_account

  cluster_name = local.cluster_name
  ocean_id = module.ocean_eks.ocean_id

  # Name of VNG in Ocean
  name = "stateless"
  # Can change the AMI
  #ami_id = ""
  # Add Labels or taints
  labels = [{key="type",value="stateless"}]
  #taints = [{key="type",value="stateless",effect="NoSchedule"}]
  tags = [{key = "CreatedBy", value = "terraform"}]
}

## Create additional Ocean Virtual Node Group (launchspec) ##
module "ocean_eks_launchspec_gpu" {
  source = "ocean_eks_launchspec"

  # Spot.io Credentials
  spotinst_token              = local.spotinst_token
  spotinst_account            = local.spotinst_account

  cluster_name = local.cluster_name
  ocean_id = module.ocean_eks.ocean_id

  # Name of VNG in Ocean
  name = "gpu"
  # Can change the AMI
  #ami_id = ""
  # Add Labels or taints
  labels = [{key="type",value="gpu"}]
  taints = [{key="type",value="gpu",effect="NoSchedule"}]
  # Limit VNG to specific instance types
  #instance_types = ["g4dn.xlarge","g4dn.2xlarge"]
  # Change the spot %
  #spot_percentage = 50
}

## Outputs ##
output "ocean_id" {
  value = module.ocean_eks.ocean_id
}
output "virtual_node_group_gpu_id" {
  value = module.ocean_eks_launchspec_gpu.virtual_node_group_id
}
output "virtual_node_group_stateless_id" {
  value = module.ocean_eks_launchspec_stateless.virtual_node_group_id
}