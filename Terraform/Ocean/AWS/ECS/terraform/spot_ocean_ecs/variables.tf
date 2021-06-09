#Spot API Token
variable "spot_token" {
	type = string
}
variable "spot_account" {
	type = string
	description = "Spot Account ID Ex: act-123e3127"
}
variable "region" {
	type = string
}
variable "cluster_name" {
	type = string
}
variable "subnet_ids" {
	type = list(string)
}
variable "security_group_ids" {
	type = list(string)
}
variable "image_id" {
	type = string
}
variable "iam_instance_profile" {
	type = string
}
variable "key" {
	type = string
	default = ""
}
variable "public_ip" {
	type = string
	default = "false"
}
variable "utilize_ri" {
	type = bool
	default = true
}
variable "draining_timeout" {
	type = number
	default = 120
}
variable "monitoring" {
	type = string
	default = "true"
}
variable "optimized" {
	type = bool
	default = true
}
variable "autoscaler_enabled" {
	type = bool
	default = true
}
variable "autoscaler_auto" {
	type = bool
	default = true
}
variable "headroom_cpu" {
	type = number
	default = 0
}
variable "headroom_memory" {
	type = number
	default = 0
}
variable "headroom_num_unit" {
	type = number
	default = 0
}
variable "scale_down_percentage" {
	type = number
	default = 10
}
variable "update_roll" {
	type = bool
	default = false
}
variable "batch_percentage" {
	type = number
	default = 20
}

