## Spot Credentials ##
variable "spot_token" {
	type = string
}
variable "spot_account" {
	type = string
	description = "Spot Account ID Ex: act-123e3127"
}
###################

## Ocean Variables ##
variable "cluster_name" {
	type = string
}
variable "region" {
	type = string
}
variable "max_size" {
	type = number
	default = 1000
}
variable "min_size" {
	type = number
	default = 0
}
variable "desired_capacity" {
	type = number
	default = null
}
variable "subnet_ids" {
	type = list(string)
}
variable "tags" {
	type = list(object({
		key = string
		value = string
	}))
	default = null
	description = "Tags to be added to resources"
}
variable "whitelist" {
	type = list(string)
	default = ["a1.4xlarge","a1.2xlarge","a1.medium","a1.xlarge","a1.large","a1.metal","c5.large","c5.2xlarge","c5.24xlarge","c5.metal","c5.18xlarge","c5.4xlarge","c5.9xlarge","c5.xlarge","c5.12xlarge","c5d.4xlarge","c5d.large","c5d.18xlarge","c5d.2xlarge","c5d.9xlarge","c5d.xlarge","c5d.12xlarge","c5d.24xlarge","c5d.metal","m5.24xlarge","m5.12xlarge","m5.2xlarge","m5.16xlarge","m5.4xlarge","m5.xlarge","m5.large","m5.8xlarge","m5.metal","m5a.4xlarge","m5a.24xlarge","m5a.large","m5a.xlarge","m5a.8xlarge","m5a.2xlarge","m5a.12xlarge","m5a.16xlarge","m5ad.xlarge","m5ad.large","m5ad.24xlarge","m5ad.12xlarge","m5ad.2xlarge","m5ad.4xlarge","m5d.4xlarge","m5d.large","m5d.12xlarge","m5d.8xlarge","m5d.2xlarge","m5d.16xlarge","m5d.24xlarge","m5d.xlarge","m5d.metal","p3.2xlarge","p3.8xlarge","p3.16xlarge","r5.metal","r5.xlarge","r5.8xlarge","r5.16xlarge","r5.12xlarge","r5.large","r5.24xlarge","r5.4xlarge","r5.2xlarge","r5a.4xlarge","r5a.2xlarge","r5a.24xlarge","r5a.12xlarge","r5a.16xlarge","r5a.8xlarge","r5a.xlarge","r5a.large","r5ad.12xlarge","r5ad.xlarge","r5ad.large","r5ad.2xlarge","r5ad.24xlarge","r5ad.4xlarge","r5d.4xlarge","r5d.8xlarge","r5d.12xlarge","r5d.2xlarge","r5d.16xlarge","r5d.24xlarge","r5d.large","r5d.metal","r5d.xlarge"]
}
variable "user_data" {
	type = string
	default = null
}
variable "image_id" {
	type = string
}
variable "security_group_ids" {
	type = list(string)
}
variable "key_pair" {
	type = string
	default = ""
}
variable "iam_instance_profile" {
	type = string
}
variable "associate_public_ip_address" {
	type = bool
	default = null
}
variable "utilize_reserved_instances" {
	type = bool
	default = true
}
variable "draining_timeout" {
	type = number
	default = 120
}
variable "monitoring" {
	type = bool
	default = false
}
variable "ebs_optimized" {
	type = bool
	default = true
}
###################

## optimize images ##
variable "perform_at" {
	type 	= string
	default = "always"
	description = "Needs to be one of the following values: never/always/timeWindow."
}
variable "optimize_time_windows" {
	type 	= list(string)
	default = null
	description = "Example: ['Sun:02:00-Sun:12:00', 'Wed:01:01-Fri:02:03']"
}
variable "should_optimize_ecs_ami" {
	type 	= bool
	default = true
}
##################

## Auto Scaler ##
variable "autoscaler_is_enabled" {
	type = bool
	default = true
}
variable "autoscaler_is_auto_config" {
	type = bool
	default = true
}
variable "cooldown" {
	type = number
	default = null
}
###################

## Headroom ##
variable "cpu_per_unit" {
	type = number
	default = 0
}
variable "memory_per_unit" {
	type = number
	default = 0
}
variable "num_of_units" {
	type = number
	default = 0
}
###################

## Down ##
variable "max_scale_down_percentage" {
	type = number
	default = 10
}
variable "max_vcpu" {
	type = number
	default = null
}
variable "max_memory_gib" {
	type = number
	default = null
}
###################

## Update Policy ##
variable "should_roll" {
	type = bool
	default = false
}
variable "batch_size_percentage" {
	type = number
	default = 20
}
###################

## Scheduled Task ##
# shutdown_hours #
variable "shutdown_is_enabled" {
	type = bool
	default = false
}
variable "shutdown_time_windows" {
	type = list(string)
	default = ["Sat:20:00-Sun:04:00","Sun:20:00-Mon:04:00"]
}
# task scheduling #
variable "taskscheduling_is_enabled" {
	type = bool
	default = false
}
variable "cron_expression" {
	type = string
	default = "0 1 * * *"
}
variable "task_type" {
	type = string
	default = "clusterRoll"
	description = "Available Action Types: 'clusterRoll'"
}
###################

## Block Device Mappings ##
variable "device_name" {
	type = string
	default = ""
}
variable "delete_on_termination" {
	type = string
	default = null
}
variable "encrypted" {
	type = bool
	default = null
}
variable "iops" {
	type = string
	default = null
}
variable "kms_key_id" {
	type = string
	default = null
}
variable "snapshot_id" {
	type = string
	default = null
}
variable "volume_type" {
	type = string
	default = null
}
variable "volume_size" {
	type = number
	default = null
}
variable "throughput" {
	type = number
	default = null
}
###################

## Dynamic Volume Size ##
variable "base_size" {
	type = number
	default = 30
}
variable "resource" {
	type = string
	default = "CPU"
	description = "resource must be one of [CPU]"
}
variable "size_per_resource_unit" {
	type = number
	default = 20
	description = "Additional size per resource unit (in GB). For example: if baseSize=50, and sizePerResourceUnit=20, and an instance with 2 CPU is launched - its disk size will be: 90GB"
}
variable "no_device" {
	type = string
	default = null
}
##################