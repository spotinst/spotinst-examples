terraform {
  required_providers {
    spotinst = {
      source = "spotinst/spotinst"
    }
  }
}

provider "spotinst" {
  token = var.spot_token
  account = var.spot_account
}

locals {
  cmd = "${path.module}/scripts/get-emr"
  cluster_id = lookup(data.external.cluster_id.result, "cluster_id", "fail" )
  dns_name = lookup(data.external.dns_name.result, "dns_name", "fail")
}

# Create a Elastigroup with EMR integration(Mr Scaler) with New strategy
resource "spotinst_mrscaler_aws" "Terraform-MrScaler-01" {
  name                = var.emr_name
  description         = "MrScaler creation via Terraform"
  region              = var.region
  strategy            = var.strategy
  release_label       = var.release_label
  retries             = var.num_retries

  availability_zones  = var.subnet_ids

  provisioning_timeout {
    timeout           = var.timeout
    timeout_action    = var.timeout_action
  }

  // --- CLUSTER ------------
  log_uri                             = var.log_uri
  job_flow_role                       = var.job_flow_role
  service_role                        = var.service_role

  termination_protected               = var.termination_protected
  keep_job_flow_alive                 = var.keep_job_flow_alive

  custom_ami_id                       = var.ami_id
  ec2_key_name                        = var.key

  managed_primary_security_group      = var.master_sg_id
  managed_replica_security_group      = var.slave_sg_id
  service_access_security_group       = var.service_sg_id

  additional_primary_security_groups  = var.additional_master_sg_ids
  additional_replica_security_groups  = var.additional_slave_sg_ids

  dynamic applications {
    for_each = var.applications == null ? [] : var.applications
    content {
      name = applications.value["name"]
      version = applications.value["version"]
    }
  }

  /* Uncomment if you need to use steps or configurations file
  steps_file {
    bucket  = var.steps_bucket
    key     = var.steps_key
  }

  configurations_file {
    bucket  = var.config_bucket
    key     = var.config_key
  }
*/

  bootstrap_actions_file {
    bucket  = var.bootstrap_bucket
    key     = var.bootstrap_key
  }
  // -------------------------

  // --- MASTER GROUP -------------
  master_instance_types = var.master_instance_type
  master_lifecycle      = var.master_lifecycle
  master_ebs_optimized  = var.master_ebs_optimized

  master_ebs_block_device {
    volumes_per_instance = var.master_volume_per_instance
    volume_type          = var.master_volume_type
    size_in_gb           = var.master_volume_size
  }
  // ------------------------------

  // --- CORE GROUP -------------
  core_instance_types   = var.core_instance_types
  core_min_size         = var.core_min
  core_max_size         = var.core_max
  core_desired_capacity = var.core_desired
  core_lifecycle        = var.core_lifecycle
  core_ebs_optimized    = var.core_ebs_optimized
  core_unit             = var.core_unit

  core_ebs_block_device {
    volumes_per_instance = var.core_volume_per_instance
    volume_type          = var.core_volume_type
    size_in_gb           = var.core_volume_size
  }
  // ----------------------------

  // --- TASK GROUP -------------
  task_instance_types   = var.task_instance_types
  task_min_size         = var.task_min
  task_max_size         = var.task_max
  task_desired_capacity = var.task_desired
  task_lifecycle        = var.task_lifecycle
  task_ebs_optimized    = var.task_ebs_optimized
  task_unit             = var.task_unit

  task_ebs_block_device {
    volumes_per_instance = var.task_volume_per_instance
    volume_type          = var.task_volume_type
    size_in_gb           = var.task_volume_size
  }
  // ----------------------------

  dynamic "tags" {
    for_each = var.tags == null ? {} : var.tags
    content {
      key   = tags.key
      value = tags.value
    }
  }
}


### Call script to get the cluster ID using Spot APIs ###
data "external" "cluster_id" {
    depends_on = [spotinst_mrscaler_aws.Terraform-MrScaler-01]
    program = [local.cmd, "get-logs", spotinst_mrscaler_aws.Terraform-MrScaler-01.id]
}

### Call script to get the DNS name/Ip address from the cluster###
data "external" "dns_name" {
  depends_on = [data.external.cluster_id]
  program = [local.cmd, "get-dns", local.cluster_id, var.region]
}

