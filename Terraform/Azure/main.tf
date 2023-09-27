// Creating an Azure Resource Group where all resources will be allocated
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.resource_group_location
}

// Generating an SSH key pair for secure communication with the AKS cluster nodes
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
}

// Creating an Azure Kubernetes Service (AKS) cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_cluster_name
  location            = azurerm_resource_group.rg.location // Location is inherited from the Resource Group
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = var.aks_cluster_name

  // Configuring the default node pool for the AKS cluster
  default_node_pool {
    name                = "systempool"
    node_count          = var.aks_node_count
    vm_size             = "Standard_D2_v2"
    enable_auto_scaling = false
  }

  identity {
    type = "SystemAssigned" // Using system-assigned managed identity for the AKS cluster
  }

  network_profile {
    network_plugin = "kubenet" // Using kubenet as the network plugin for the AKS cluster
  }

  linux_profile {
    admin_username = "adminuser"
    ssh_key {
      key_data = tls_private_key.ssh.public_key_openssh // Assigning the generated SSH public key to the AKS cluster
    }
  }
}

// Fetching the data of the created AKS cluster for further configurations
data "azurerm_kubernetes_cluster" "aks" {
  name                = azurerm_kubernetes_cluster.aks.name
  resource_group_name = azurerm_resource_group.rg.name
}

// Outputting the command to configure kubectl to connect to the newly created AKS cluster
output "configure_kubectl" {
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.rg.name} --name ${azurerm_kubernetes_cluster.aks.name}"
  description = "Run this command to configure kubectl to connect to the newly created AKS cluster."
}

// Configuring the Spotinst Ocean Controller module
module "ocean-controller" {
  source = "spotinst/ocean-controller/spotinst"

  // Providing credentials for Spotinst
  spotinst_token   = var.spotinst_token
  spotinst_account = var.spotinst_account

  // Identifying the cluster for the Ocean Controller
  cluster_identifier = var.aks_cluster_name

  // Ensuring that the Ocean AKS NP module is created before the Ocean Controller module
  depends_on = [
    module.ocean-aks-np
  ]
}

// Configuring the Spotinst Ocean AKS Node Pool (NP) module
module "ocean-aks-np" {
  source = "spotinst/ocean-aks-np-k8s/spotinst"

  // Providing credentials for Spotinst
  spotinst_token   = var.spotinst_token
  spotinst_account = var.spotinst_account

  // Configuring the Ocean AKS NP module with details from the created AKS cluster and Resource Group
  ocean_cluster_name                       = var.aks_cluster_name
  aks_region                               = azurerm_resource_group.rg.location
  controller_cluster_id                    = var.aks_cluster_name
  aks_cluster_name                         = azurerm_kubernetes_cluster.aks.name
  aks_infrastructure_resource_group_name   = "MC_${azurerm_resource_group.rg.name}_${azurerm_kubernetes_cluster.aks.name}_${azurerm_resource_group.rg.location}"
  aks_resource_group_name                  = azurerm_resource_group.rg.name
  autoscaler_is_enabled                    = var.autoscaler_is_enabled
  availability_zones                       = [1, 2, 3]
}

// Configuring the Spotinst Ocean AKS Virtual Node Group (VNG) module
module "ocean-aks-np-vng" {
  source = "spotinst/ocean-aks-np-k8s-vng/spotinst"

  // Setting the name of the Ocean VNG and associating it with the Ocean ID from the Ocean AKS NP module
  ocean_vng_name = "${var.aks_cluster_name}-vng"
  ocean_id       = module.ocean-aks-np.ocean_id
}
