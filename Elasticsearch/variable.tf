variable "region" {
  default =  "us-west-2"
}

variable "spotinst_token" {
  
}

variable "spotinst_account" {

}

variable "ELK-CluserName" {
  default = "elasticsearch"
}

variable "keypair" {
  
}

variable "subnet_ids" {
  type = "list"
}

variable "master_subnet" {
  
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

variable "tagName" {
  
}

variable "tagValue" {
  
}

