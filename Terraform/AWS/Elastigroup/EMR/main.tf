### Create Elastigroup EMR Cluster in Spot.io ###
module "elastigroup_emr" {
  source = "./elastigroup_emr"

  spot_token = ""
  spot_account = ""

  ### Cluster Configurations ###
  emr_name = "Example-Spot-EMR-Terraform"
  release_label = "emr-5.24.0"
  ami_id = "ami-068c8ed05785be1c4"
  key = ""
  log_uri = "s3://"
  keep_job_flow_alive = false
  applications = [{name = "hive", version = "2.37"},{name = "spark", version = "2.47"}]
  tags = {CreatedBy="Terraform",Env="Dev"}

  ### Network ###
  region = "us-east-1"
  subnet_ids = ["us-east-1a:subnet-123456789","us-east-1b:subnet-123456789"]
  master_sg_id = "sg-123456789"
  slave_sg_id = "sg-123456789"

  ### Config/step Files ###
  # Bootstrap arguments stored in a file on s3
  bootstrap_bucket = "bucketname"
  bootstrap_key = "bucketfile.json"

  #configuration file stored in a file on s3. Note uncomment line 60 in the module main.tf
  #steps_bucket = ""
  #steps_key = ""

  #configuration file stored in a file on s3. Note uncomment line 66 in the module main.tf
  #config_bucket = ""
  #config_key = ""

  ### Master Node Configs ###
  master_instance_type = ["m4.large"]

  ### Core Node Configs ###
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
  core_desired = 1

  ### Task node configs ###
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
  task_lifecycle = "SPOT"
  task_desired = 0
  task_unit = "weight"

}

### Outputs ###
output "eg_id" {
  value = module.elastigroup_emr.elastigroup_id
}
