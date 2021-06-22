## Launchspec Variables ##
variable "name" {
  type = string
}
variable "ocean_id" {
  type = string
}

## Block Device Mappings ##
variable "device_name" {
  type = string
  default = null
}
variable "delete_on_termination" {
  type = string
  default = null
}
variable "encrypted" {
  type = bool
  default = null
}
variable "iops" {
  type = string
  default = null
}
variable "kms_key_id" {
  type = string
  default = null
}
variable "snapshot_id" {
  type = string
  default = null
}
variable "volume_type" {
  type = string
  default = null
}
variable "volume_size" {
  type = number
  default = null
}
variable "throughput" {
  type = number
  default = null
}
###################

## Dynamic Volume Size ##
variable "base_size" {
  type = number
  default = null
}
variable "resource" {
  type = string
  default = null
}
variable "size_per_resource_unit" {
  type = number
  default = null
}
variable "no_device" {
  type = string
  default = null
}
##################

