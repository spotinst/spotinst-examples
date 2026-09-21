variable "subscription_id" {
  type        = string
  description = "Azure subscription ID used for deployment."
}

variable "tenant_id" {
  type        = string
  description = "Microsoft Entra tenant ID used for deployment."
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group for the AKS cluster."
}

variable "resource_group_location" {
  type        = string
  description = "Azure region for the resource group and AKS cluster."
}

variable "cluster_name" {
  type        = string
  description = "Name of the AKS cluster."
}

variable "node_count" {
  type        = number
  description = "The initial quantity of nodes for the node pool."
  default     = 3
}

variable "node_vm_size" {
  type        = string
  description = "VM size for the default AKS node pool."
  default     = "Standard_D2_v2"
}

variable "username" {
  type        = string
  description = "The admin username for the new cluster."
  default     = "azureadmin"
}

variable "vnet_name" {
  type        = string
  description = "Virtual network used by AKS and Azure NetApp Files. Changing this can recreate AKS."
  default     = "aks-network"
}

variable "vnet_address_space" {
  type        = string
  description = "Virtual network CIDR."
  default     = "10.20.0.0/16"
}

variable "aks_subnet_name" {
  type        = string
  description = "Subnet for AKS node IPs."
  default     = "aks-nodes"
}

variable "aks_subnet_address_prefix" {
  type        = string
  description = "CIDR for the AKS node subnet."
  default     = "10.20.0.0/20"
}

variable "anf_subnet_name" {
  type        = string
  description = "Delegated subnet for Azure NetApp Files."
  default     = "anf-volumes"
}

variable "anf_subnet_address_prefix" {
  type        = string
  description = "CIDR for the delegated Azure NetApp Files subnet."
  default     = "10.20.16.0/24"
}

variable "anf_account_name" {
  type        = string
  description = "Azure NetApp Files account name."
  default     = "aksanf"
}

variable "anf_pool_name" {
  type        = string
  description = "Azure NetApp Files capacity pool name."
  default     = "ultra"
}

variable "anf_pool_size_gib" {
  type        = number
  description = "Azure NetApp Files Ultra capacity pool size in GiB. Minimum is 4096 GiB."
  default     = 4096
}

variable "trident_principal_object_id" {
  type        = string
  description = "Microsoft Entra service principal object ID receiving NetApp Contributor."
}

variable "ocean_rightsizing_cpu_percentile" {
  type        = number
  description = "CPU percentile used by Ocean automatic rightsizing recommendations."
  default     = 95
}

variable "ocean_rightsizing_memory_percentile" {
  type        = number
  description = "Memory percentile used by Ocean automatic rightsizing recommendations."
  default     = 95
}

variable "spotinst_token" {
  type        = string
  description = "Spot Personal Access Token. Set via TF_VAR_spotinst_token."
  sensitive   = true
}

variable "spotinst_account" {
  type        = string
  description = "Spot account ID. Set via TF_VAR_spotinst_account."
}

variable "ocean_node_min_count" {
  type        = number
  description = "Minimum number of nodes for the Spot Ocean node pool."
  default     = 1
}

variable "ocean_node_max_count" {
  type        = number
  description = "Maximum number of nodes for the Spot Ocean node pool."
  default     = 10
}

variable "ocean_spot_percentage" {
  type        = number
  description = "Percentage of Ocean nodes that should use Spot VMs."
  default     = 100
}

variable "ocean_vng_name" {
  type        = string
  description = "Name of the Spot Ocean virtual node group."
  default     = "wes-test-aks-tf-vng"
}

variable "ocean_vng_min_count" {
  type        = number
  description = "Minimum node count for the Spot Ocean virtual node group."
  default     = 1
}

variable "ocean_vng_max_count" {
  type        = number
  description = "Maximum node count for the Spot Ocean virtual node group."
  default     = 3
}

variable "ocean_vng_spot_percentage" {
  type        = number
  description = "Percentage of virtual node group capacity to use Spot VMs."
  default     = 100
}

variable "vmss_node_pools" {
  type = map(object({
    name       = string
    vm_size    = string
    node_count = number
    min_count  = number
    max_count  = number
  }))
  description = "User node pools backed by VM scale sets."

  default = {
    poolone = {
      name       = "poolone"
      vm_size    = "Standard_D2_v2"
      node_count = 1
      min_count  = 1
      max_count  = 3
    }
    pooltwo = {
      name       = "pooltwo"
      vm_size    = "Standard_D2_v2"
      node_count = 1
      min_count  = 1
      max_count  = 3
    }
  }
}