variable "region" {

}

variable "cluster_identifier" {

}

variable "keypair" {

}

variable "subnet_ids" {
  type = list(string)
}

variable "image_id" {

}

variable "security_groups" {
  type = list(string)

}

variable "instance_types_ondemand" {

}

variable "instance_types_spot" {
  type = list(string)
}


variable "spotinst_token" {

}

variable "spotinst_account" {

}
variable "aws_access_key" {

}

variable "aws_secret_key" {

}

variable "cluster_name" {

}

variable "vpc_id" {

}

variable "namespace" {

}

variable "kube-version" {

}