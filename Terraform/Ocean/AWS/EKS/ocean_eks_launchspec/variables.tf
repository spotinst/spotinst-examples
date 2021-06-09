variable "spotinst_token" {
  type        = string
  description = "Spotinst Personal Access token"
}

variable "spotinst_account" {
  type        = string
  description = "Spotinst account ID"
}

### Required Ocean VNG (Launch Spec) Configurations
variable "ocean_id" {
  type        = string
  description = "Ocean ID"
}
variable "cluster_name" {
  type        = string
  description = "Name of EKS Cluster"
}
variable "name" {
  type        = string
  description = "Name for nodegroup (VNG)"
}


## Optional VNG Configurations
variable "user_data" {
  type        = string
  default     = null
}
variable "worker_instance_profile_arn" {
  type        = string
  default     = null
  description = "Instance Profile ARN to assign to worker nodes. Should have the WorkerNode policy"
}
variable "security_groups" {
  type        = list(string)
  default     = null
  description = "List of security groups"
}
variable "subnet_ids" {
  type        = list(string)
  default     = null
  description = "List of subnets"
}
variable "ami_id" {
  type        = string
  default     = null
  description = "ami id"
}
variable "max_instance_count" {
  type        = number
  default     = null
  description = "Maximum number of nodes launch by Spot VNG"
}
variable "instance_types" {
  type        = list(string)
  default     = null
  description = "Specific instance types permitted by this VNG. For example, [\"m5.large\",\"m5.xlarge\"]"
}
variable "root_volume_size" {
  type        = number
  default     = 30
  description = "Size of root volume"
}
variable "spot_percentage" {
  type        = number
  default     = 100
  description = "Percentage of VNG that will run on EC2 Spot instances and remaining will run on-demand"
}
variable "labels" {
  type = list(object({
    key = string
    value = string
  }))
  default = null
  description = "NodeLabels / NodeSelectors"
}
variable "taints" {
  type = list(object({
    key = string
    value = string
    effect = string
  }))
  default = null
  description = "taints / toleration"
}
variable "tags" {
  type = list(object({
    key = string
    value = string
  }))
  default = null
  description = "Tags to be added to resources"
}


