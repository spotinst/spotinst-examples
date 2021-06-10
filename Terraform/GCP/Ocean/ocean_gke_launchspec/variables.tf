### Variables ###
variable "cluster_name" {
  type        = string
  description = "Name of GKE Cluster"
}
variable "spot_token" {
  type        = string
  description = "Spot Token"
}
variable "spot_account" {
  type        = string
  description = "Spot Account ID"
}
variable "location" {
  type        = string
  description = "Location of cluster. ie us-west2a"
}
variable "project" {
  type        = string
  description = "The name of the project"
}
variable "ocean_id" {
  type        = string
  description = "The ID of the Ocean Cluster"
}
variable "source_image" {
  type        = string
  default     = null
}
#################

## VNG settings ##
variable "taints" {
  type = list(object({
    key = string
    value = string
    effect = string
  }))
  default = null
  description = "taints / toleration"
}
variable "labels" {
  type = list(object({
    key = string
    value = string
  }))
  default = null
  description = "NodeLabels / NodeSelectors"
}
variable "restrict_scale_down" {
  type        = bool
  default     = null
}
variable "headroom_num_of_units" {
  type        = number
  default     = null
}
variable "headroom_cpu_per_unit" {
  type        = number
  default     = null
}
variable "headroom_gpu_per_unit" {
  type        = number
  default     = null
}
variable "headroom_memory_per_unit" {
  type        = number
  default     = null
}
variable "preemptible_percentage" {
  type        = number
  default     = 100
  description = "The percentage of PE machines in the launchspec (VNG)"
}
/*
variable "tags" {
  type = list(object({
    key = string
    value = string
  }))
  default = null
  description = "Tags to be added to resources"
}*/