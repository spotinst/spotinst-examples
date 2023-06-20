variable "spot_token" {
  type        = string
  default     = "Your Spot API Token goes here"
  sensitive   = true
  description = "Your Spot API Token - https://docs.spot.io/administration/api/create-api-token"
}

variable "spot_account" {
  type        = string
  default     = "act-61e1c107"
  sensitive   = true
  description = "Spot account that will house the Ocean Cluster"
}

variable "cluster_name" {
  type        = string
  default     = "Cluster Name"
  description = "The name of your EKS Cluster (will also be the name of the Ocean Cluster)"
}

variable "cluster_version" {
  type        = string
  default     = "1.27"
  description = "Kubernetes version to be used for the EKS Cluster"
}

variable "vpc_id" {
  type        = string
  default     = "vpc-0fecbed6ddaf5860f" #This is the SA-Team VPC
  description = "ID of the AWS VPC to be used for the EKS Cluster"
}

variable "private_subnet_ids" {
  type        = list(any)
  default     = ["subnet-09545f79a52f59825", "subnet-0df0c7239150dd441", "subnet-067d25b121cf77310", "subnet-038861e9b08976c88"]
  description = "Private Subnets associated with the VPC - Can be found by viewing the VPC Resource Map in AWS"
}

variable "public_subnet_ids" {
  type        = list(any)
  default     = ["subnet-0a60fdfc059cc0c55", "subnet-00dd3842d49f32f7e", "subnet-013f06cd493bb19b5"]
  description = "Public Subnets associated with the VPC - Can be found by viewing the VPC Resource Map in AWS"
}

variable "kms_key_owners" {
  type        = list(any)
  default     = ["arn:aws:iam::303703646777:role/Admin"]
  sensitive   = true
  description = "This will make Admins the owner of the KMS key that EKS creates"
}

variable "key_pair" {
  type        = string
  default     = "Your AWS key pair"
  description = "The Key Pair to be used for creating and managing the EKS Cluster"
}

variable "iam_role_permissions_boundary" {
  type        = string
  default     = "arn:aws:iam::303703646777:policy/deny_ec2_without_creator"
  description = "This is NOT needed for customers. Spot SAs need this so we do not override the requirement for the 'creator' tag"
}

variable "instance_types" {
  type        = list(any)
  default     = ["t3.medium"]
  description = "List of instances that the cluster will provision."
}

variable "availability_vs_cost" {
  type        = string
  default     = "balanced"
  description = "(Optional, Default: balanced) You can control the approach that Ocean takes while launching nodes by configuring this value. Possible values: costOriented,balanced,cheapest."
}

variable "aws_region" {
  type        = string
  default     = "us-west-2"
  description = "AWS Region where resources will be created"
}

variable "creator" {
  type        = string
  default     = "Your NetApp email"
  description = "Value of the creator tag needed to allow SAs to provision compute resources."
}

variable "eks_version" {
  type        = string
  default     = "~> 19.0"
  description = "Version of AWS EKS Module"
}

variable "headroom" {
  type        = number
  default     = 0
  description = "Auto Headroom percentage. Can be 0 - 200. The usual default is 5"
}

variable "spread" {
  type        = string
  default     = "vcpu"
  description = "Ocean will spread nodes by this value. Options are 'count' or 'vcpu'"
}

variable "utilize_commitments" {
  type        = bool
  default     = true
  description = "If savings plans commitment has available capacity, Ocean will utilize them alongside RIs (if exist) to maximize cost efficiency."
}

variable "utilize_reserved_instances" {
  type        = bool
  default     = true
  description = "If there are any vacant Reserved Instances, launch On-Demand to consume them"
}

variable "scale_down_percentage" {
  type        = number
  default     = 100
  description = "Max % to scale-down. Number between 1-100."
}

variable "shutdown_hours" {
  default = {
    is_enabled = true
    time_windows = [
      "Sat:05:00-Mon:13:00"
    ]
  }
  description = "Will scale down the cluster to 0 during the time windows. Time is in GMT"
}