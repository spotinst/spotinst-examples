resource "azurerm_netapp_account" "aks" {
  name                = var.anf_account_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_netapp_pool" "ultra" {
  name                = var.anf_pool_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = azurerm_netapp_account.aks.name
  service_level       = "Ultra"
  size_in_tb          = var.anf_pool_size_gib / 1024
}

resource "azurerm_role_assignment" "trident_netapp_contributor" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "NetApp Contributor"
  principal_id         = var.trident_principal_object_id
  principal_type       = "ServicePrincipal"
}