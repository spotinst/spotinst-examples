#Spot API Token
variable "spot_token" {}

#Spot Account ID Ex: act-123e3127
variable "spot_account" {}

variable "region" {}

variable "cluster_name" {}

variable "subnet_ids" {}

variable "security_group_ids" {}

variable "image_id" {}

variable "iam_instance_profile" {}

variable "key" {
	default = ""
}
variable "public_ip" {
	default = "false"
}
variable "utilize_ri" {
	default = "true"
}
variable "draining_timeout" {
	default = "120"
}
variable "monitoring" {
	default = "true"
}
variable "optimized" {
	default = "true"
}
variable "autoscaler_enabled" {
	default = "true"
}
variable "autoscaler_auto" {
	default = "true"
}
variable "headroom_cpu" {
	default = "0"
}
variable "headroom_memory" {
	default = "0"
}
variable "headroom_num_unit" {
	default = "0"
}
variable "scale_down_percentage" {
	default = "10"
}
variable "update_roll" {
	default = "false"
}
variable "batch_percentage" {
	default = "20"
}

