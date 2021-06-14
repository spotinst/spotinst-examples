variable "spotinst_token" {
  type        = string
  description = "Spotinst Personal Access token"
}

variable "spotinst_account" {
  type        = string
  description = "Spotinst account ID"
}

variable "cluster_name" {
  type        = string
  description = "Cluster name"
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where the EKS will be located"
}

variable "region" {
  type        = string
  description = "The region the EKS cluster will be located"
}

variable "aws_profile" {
  type        = string
  default     = null
}

variable "ami_id" {
  type        = string
  default     = null
  description = "The image ID for the EKS worker nodes. If none is provided, Terraform will search for the latest version of their EKS optimized worker AMI based on platform"
}

variable "worker_instance_profile_arn" {
  type        = string
  description = "Instance Profile ARN to assign to worker nodes. Should have the WorkerNode policy"
}
variable "security_groups" {
  type        = list(string)
  description = "List of security groups"
}

##Ocean Configurations
variable "min_size" {
  type        = number
  default     = 0
  description = "The lower limit of worker nodes the Ocean cluster can scale down to"
}

variable "max_size" {
  type        = number
  default     = 1000
  description = "The upper limit of worker nodes the Ocean cluster can scale up to"
}

variable "desired_capacity" {
  type        = number
  default     = 1
  description = "The number of worker nodes to launch and maintain in the Ocean cluster"
}

variable "key_name" {
  type        = string
  default     = null
  description = "The key pair to attach to the worker nodes launched by Ocean"
}

variable "associate_public_ip_address" {
  type        = bool
  default     = true
  description = "Associate a public IP address to worker nodes"
}

variable "blacklist" {
  type        = list(string)
  description = "List of instance types to prohibit Ocean to use"
  default     = [
    "c6g.12xlarge",
    "c6g.16xlarge",
    "c6g.2xlarge",
    "c6g.4xlarge",
    "c6g.8xlarge",
    "c6g.large",
    "c6g.medium",
    "c6g.metal",
    "c6g.xlarge",
    "c6gd.12xlarge",
    "c6gd.16xlarge",
    "c6gd.2xlarge",
    "c6gd.4xlarge",
    "c6gd.8xlarge",
    "c6gd.large",
    "c6gd.medium",
    "c6gd.metal",
    "c6gd.xlarge",
    "c6gn.12xlarge",
    "c6gn.16xlarge",
    "c6gn.2xlarge",
    "c6gn.4xlarge",
    "c6gn.8xlarge",
    "c6gn.large",
    "c6gn.medium",
    "c6gn.xlarge",
    "m6g.12xlarge",
    "m6g.16xlarge",
    "m6g.2xlarge",
    "m6g.4xlarge",
    "m6g.8xlarge",
    "m6g.large",
    "m6g.medium",
    "m6g.metal",
    "m6g.xlarge",
    "m6gd.12xlarge",
    "m6gd.16xlarge",
    "m6gd.2xlarge",
    "m6gd.4xlarge",
    "m6gd.8xlarge",
    "m6gd.large",
    "m6gd.medium",
    "m6gd.metal",
    "m6gd.xlarge",
    "r6g.12xlarge",
    "r6g.16xlarge",
    "r6g.2xlarge",
    "r6g.4xlarge",
    "r6g.8xlarge",
    "r6g.large",
    "r6g.medium",
    "r6g.metal",
    "r6g.xlarge",
    "r6gd.12xlarge",
    "r6gd.16xlarge",
    "r6gd.2xlarge",
    "r6gd.4xlarge",
    "r6gd.8xlarge",
    "r6gd.large",
    "r6gd.medium",
    "r6gd.metal",
    "r6gd.xlarge",
    "t2.medium",
    "t2.xlarge",
    "t2.large",
    "t2.2xlarge",
    "t2.micro",
    "t2.small",
    "t3.small",
    "t3.medium",
    "t3.xlarge",
    "t3.2xlarge",
    "t3.large",
    "t3.micro",
    "t3a.large",
    "t3a.xlarge",
    "t3a.medium",
    "t3a.2xlarge",
    "t3a.small",
    "t3a.micro",
    "t4g.2xlarge",
    "t4g.large",
    "t4g.medium",
    "t4g.micro",
    "t4g.small",
    "t4g.xlarge"]
}

variable "fallback_to_ondemand" {
  type        = bool
  default     = true
  description = "Launch On-Demand in the event there are no EC2 spot instances available"
}
variable "utilize_reserved_instances" {
  type        = bool
  default     = true
  description = "If there are any vacant Reserved Instances, launch On-Demand to consume them"
}
variable "draining_timeout" {
  type        = number
  default     = 120
  description = "Draining timeout before terminating a node"
}
variable "grace_period" {
  type        = number
  default     = 600
  description = "The amount of time, in seconds, after the instance has launched to start checking its health."
}
variable "spot_percentage" {
  type        = number
  default     = null
  description = "The % of the cluster should be running on Spot vs OD. 100 means 100% of the cluster will be ran on Spot instances"
}
variable "tags" {
  type = list(object({
    key = string
    value = string
  }))
  default = null
  description = "Tags to be added to resources"
}
variable "should_roll" {
  type        = string
  default     = false
  description = "Should the cluster be rolled for configuration updates"
}

