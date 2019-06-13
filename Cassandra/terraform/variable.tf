
variable "Cassndrd-Node-1-IP" {
}

variable "Cassndrd-Node-2-IP" {
}

variable "Cassndrd-Node-3-IP" {
}

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

variable "spotinst_token" {
  
}

variable "spotinst_account" {

}
