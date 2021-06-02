## Create Elastigroup EMR Cluster in Spot.io##
module "elastigroup_emr" {
  source = "elastigroup_emr"

  spot_token = "1234567890"
  spot_account = "act-123456789"

  emr_name = "Example-Spot-EMR-Terraform"
  region = "us-east-1"
  release_label = "emr-5.24.0"
  ami_id = "ami-068c8ed05785be1c4"
  subnet_ids = ["us-east-1a:subnet-0eba9f7d282222b23","us-east-1b:subnet-068e6f4f45218b98f"]
  bootstrap_bucket = "example"
  bootstrap_key = "bootstrap.json"
  master_sg_id = "sg-04cd8b735c62e31cb"
  slave_sg_id = "sg-04cd8b735c62e31cb"
  key = "example"
  log_uri = "s3://example/logs/"

  master_instance_type = ["m4.large"]

  core_instance_types = [
    "m4.2xlarge",
    "m4.4xlarge",
    "m5.4xlarge",
    "m5.2xlarge",
    "m5.8xlarge",
    "r5.4xlarge",
    "r5d.4xlarge",
    "m5.8xlarge",
    "m5d.4xlarge"
  ]
  core_lifecycle = "SPOT"
  core_desired = 5

  task_instance_types = [
    "m4.2xlarge",
    "m4.4xlarge",
    "m5.4xlarge",
    "m5.2xlarge",
    "m5.8xlarge",
    "r5.4xlarge",
    "r5d.4xlarge",
    "m5.8xlarge",
    "m5d.4xlarge"
  ]
  task_desired = 0

}

output "EMR_ID" {
  value = module.elastigroup_emr.EMR_id
}
output "EG_ID" {
  value = module.elastigroup_emr.elastigroup_id
}