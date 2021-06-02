provider "aws" {
  region              = var.region
  profile             = var.aws_profile
}
#### Create Ocean ECS Cluster ####
module "spot_ocean_ecs" {
    source = "..\/spot_ocean_ecs"

    cluster_name                    = var.cluster_name
    spot_token                      = var.spot_token
    spot_account                    = var.spot_account
    region                          = var.region
    subnet_ids                      = var.subnet_ids
    security_group_ids              = var.security_group_ids
    image_id                        = var.image_id
    iam_instance_profile            = var.iam_instance_profile
}



    
