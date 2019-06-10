variable "region" {
  
}

variable "keypair" {
  
}

variable "subnet_ids" {
  type = "list"
}

variable "security_groups" {
    type = "list"
  
}

variable "instance_types_ondemand" {
  
}

variable "instance_types_spot" {
  type = "list"
}

variable "instance_types_preferred_spot" {
    type = "list"
  
}

variable "master_ip" {
  
}

variable "spotinst_token" {
  
}

variable "spotinst_account" {

}

variable "target_group_arns" {
  type = "list"
}
