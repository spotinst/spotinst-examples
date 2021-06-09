variable "region" {
    type = string
}

variable "aws_profile" {
    type = string
    default = "default"
}

variable "spot_token" {
    type = string
}

variable "spot_account" {
    type = string
}

variable "cluster_name" {
    type = string
}

variable "security_group_ids" {
    type = list(string)
}

variable "subnet_ids" {
    type = list(string)
}

variable "image_id" {
    type = string
}

variable "iam_instance_profile" {
    type = string
}

