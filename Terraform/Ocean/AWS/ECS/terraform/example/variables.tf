variable "region" {}

variable "aws_profile" {
    default = "default"
}

variable "spot_token" {}

variable "spot_account" {}

variable "cluster_name" {}

variable "security_group_ids" {
    type = list
}

variable "subnet_ids" {
    type = list
}

variable "image_id" {}

variable "iam_instance_profile" {}

