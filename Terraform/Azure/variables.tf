variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the Azure Resource Group"
  type        = string
}

variable "resource_group_location" {
  description = "Azure Resource Group Location"
  type        = string
}

variable "aks_cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
}

variable "aks_node_count" {
  description = "Number of nodes in the AKS cluster"
  type        = number
  default     = 1
}

variable "spotinst_token" {
  description = "Spotinst API Token"
  type        = string
}

variable "spotinst_account" {
  description = "Spotinst Account ID"
  type        = string
}

variable "autoscaler_is_enabled" {
  description = "Enable the Ocean Kubernetes Autoscaler"
  type        = bool
  default     = true
}
