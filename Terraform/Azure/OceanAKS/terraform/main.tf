resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = var.resource_group_name
}

resource "azurerm_virtual_network" "aks" {
  name                = var.vnet_name
  address_space       = [var.vnet_address_space]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "aks" {
  name                 = var.aks_subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.aks.name
  address_prefixes     = [var.aks_subnet_address_prefix]
}

resource "azurerm_subnet" "anf" {
  name                 = var.anf_subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.aks.name
  address_prefixes     = [var.anf_subnet_address_prefix]

  delegation {
    name = "netapp-volumes"

    service_delegation {
      name = "Microsoft.Netapp/volumes"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/action",
      ]
    }
  }
}

resource "azurerm_kubernetes_cluster" "k8s" {
  location            = azurerm_resource_group.rg.location
  name                = var.cluster_name
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = var.cluster_name

  identity {
    type = "SystemAssigned"
  }

  default_node_pool {
    name           = "agentpool"
    vm_size        = var.node_vm_size
    node_count     = var.node_count
    vnet_subnet_id = azurerm_subnet.aks.id

    upgrade_settings {
      max_surge                     = "10%"
      drain_timeout_in_minutes      = 0
      node_soak_duration_in_minutes = 0
    }
  }
  linux_profile {
    admin_username = var.username

    ssh_key {
      key_data = azapi_resource_action.ssh_public_key_gen.output.publicKey
    }
  }
  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
  }

}