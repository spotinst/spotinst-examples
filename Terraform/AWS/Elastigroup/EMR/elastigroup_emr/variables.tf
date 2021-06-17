variable "spot_token" {
  type        = string
}
variable "spot_account" {
  type        = string
}
variable "emr_name" {
  type        = string
  description = "Name of the EMR Cluster and Elastigroup"
}
variable "region" {
  type        = string
}
variable "strategy" {
  type        = string
  default     = "new"
  description = "The Strategy for creating the group. At least one of the following is required: wrapping, cloning, or new"
}
variable "release_label" {
  type        = string
  default     = "emr-5.21.0"
  description = "Version of EMR"
}
variable "num_retries" {
  type        = number
  default     = 2
  description = "Number of retries to provision the cluster"
}
variable "subnet_ids" {
  type        = list(string)
}
variable "timeout" {
  type        = number
  default     = 15
  description = "EMR clusters occasionally get stuck in provisioning status due to unhealthy clusters, slowness or other issues. In such cases, a timeout can be used to automatically terminate the cluster after the defined period of time."
}
variable "timeout_action" {
  type        = string
  default     = "terminateAndRetry"
  description = "Desired action if the timeout is exceeded. Currently terminate and terminateAndRetry are supported."
}
variable "log_uri" {
  type        = string
  description = "The path to the Amazon S3 location where logs for this cluster are stored."
  default     = ""
}
variable "job_flow_role" {
  type        = string
  description = "The IAM role that was specified when the job flow was launched. The EC2 instances of the job flow assume this role."
  default     = ""
}
variable "service_role" {
  type        = string
  description = "The IAM role that will be assumed by the Amazon EMR service to access AWS resources on your behalf"
  default     = ""
}
variable "termination_protected" {
  type        = bool
  default     = false
  description = "Specifies whether the Amazon EC2 instances in the cluster are protected from termination by API calls, user numberervention, or in the event of a job-flow error"
}
variable "keep_job_flow_alive" {
  type        = bool
  default     = false
  description = "Specifies whether the cluster should remain available after completing all steps"
}
variable "ami_id" {
  type        = string
  default     = ""
}
variable "key" {
  type        = string
  default     = ""
  description = "The name of an Amazon EC2 key pair that can be used to ssh to the master node."
}
variable "master_sg_id" {
  type        = string
  default     = ""
  description = "EMR Managed Security group that will be set to the primary instance group."
}
variable "slave_sg_id" {
  type        = string
  default     = ""
  description = "EMR Managed Security group that will be set to the replica instance group."
}
variable "service_sg_id" {
  type        = string
  default     = ""
  description = "The identifier of the Amazon EC2 security group for the Amazon EMR service to access clusters in VPC private subnets."
}
variable "additional_master_sg_ids" {
  type        = list(string)
  default     = [""]
  description = "A list of additional Amazon EC2 security group IDs for the master node."
}
variable "additional_slave_sg_ids" {
  type        = list(string)
  default     = [""]
  description = "A list of additional Amazon EC2 security group IDs for the core and task nodes."
}

variable "steps_bucket" {
  type        = string
  default     = ""
}
variable "steps_key" {
  type        = string
  default     = ""
}
variable "config_bucket" {
  type        = string
  default     = ""
}
variable "config_key" {
  type        = string
  default     = ""
}
variable "bootstrap_bucket" {
  type        = string
  default     = ""
}
variable "bootstrap_key" {
  type        = string
  default     = ""
}
variable "applications" {
  type        = list(object({name = string, version = string}))
  default     = null
}
variable "tags" {
  type        = map(string)
  default     = null
  description = "Sample: {CreatedBy=\"Terraform\",Env=\"Dev\"}"
}

####################################

### Master Node Variables ###
variable "master_instance_type" {
  type        = list(string)
  default     = [""]
}
variable "master_lifecycle" {
  type        = string
  default     = "ON_DEMAND"
}
variable "master_ebs_optimized" {
  type        = bool
  default     = true
}
variable "master_volume_per_instance" {
  type        = number
  default     = 1
}
variable "master_volume_type" {
  type        = string
  default     = "gp2"
}
variable "master_volume_size" {
  type        = number
  default     = 30
}
####################################

### Core Node Variables ###
variable "core_instance_types" {
  type        = list(string)
  default     = [""]
}
variable "core_min" {
  type        = number
  default     = 0
}
variable "core_max" {
  type        = number
  default     = 100
}
variable "core_desired" {
  type        = number
  default     = 1
}
variable "core_lifecycle" {
  type        = string
  default     = "SPOT"
  description = "The MrScaler lifecycle for instances in core group. Allowed values are 'SPOT' and 'ON_DEMAND'."
}
variable "core_ebs_optimized" {
  type        = bool
  default     = true
  description = "EBS Optimization setting for instances in group."
}
variable "core_unit" {
  type        = string
  default     = ""
  description = "Unit of task group for target, min and max. The unit could be instance or weight. instance "
}
variable "core_volume_per_instance" {
  type        = number
  default     = 1
  description = "Amount of volumes per instance in the core group."
}
variable "core_volume_type" {
  type        = string
  default     = "gp2"
  description = "Allowed valuse are 'gp2' and others"
}
variable "core_volume_size" {
  type        = number
  default     = 30
}
####################################

### Task Node Variables ###
variable "task_instance_types" {
  type        = list(string)
  default     = [""]
  description = ""
}
variable "task_min" {
  type        = number
  default     = 0
  description = ""
}
variable "task_max" {
  type        = number
  default     = 100
}
variable "task_desired" {
  type        = number
  default     = 0
}
variable "task_lifecycle" {
  type        = string
  default     = "SPOT"
  description = "SPOT"
}
variable "task_ebs_optimized" {
  type        = bool
  default     = true
}
variable "task_unit" {
  type        = string
  default     = "instance"
  description = "Unit of task group for target, min and max. The unit could be instance or weight. instance - amount of instances. weight - amount of vCPU."
}
variable "task_volume_per_instance" {
  type        = number
  default     = 1
  description = "Amount of volumes per instance in the core group."
}
variable "task_volume_type" {
  type        = string
  default     = "gp2"
  description = "volume type. Allowed values are 'gp2', 'io1' and others."
}
variable "task_volume_size" {
  type        = number
  default     = 30
  description = "Size of the volume, in GBs."
}
####################################

