## Create Ocean Cluster in Spot.io and deploy controller pod ##
module "ocean_eks" {
  source = "./ocean_eks"

  # Spot.io Credentials
  spotinst_token              = ""
  spotinst_account            = ""

  # Configuration
  cluster_name                = "example-cluster"
  region                      = "us-east-1"
  subnet_ids                  = ["subnet-123456","subnet-123456"]
  vpc_id                      = "vpc-123456789"
  #min_size                    = var.min_size
  #max_size                    = var.max_size
  #desired_capacity            = var.desired_capacity

  # Default Worker node specifics
  ami_id                      = "ami-123456"
  security_groups             = ["sg-12345"]
  worker_instance_profile_arn = "arn:instance profile"
}

