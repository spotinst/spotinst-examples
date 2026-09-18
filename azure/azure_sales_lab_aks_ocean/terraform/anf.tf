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

resource "kubernetes_namespace_v1" "trident" {
  metadata {
    name = var.trident_namespace
  }
}

resource "kubernetes_namespace_v1" "spot_system" {
  metadata {
    name = "spot-system"
  }
}

resource "kubernetes_secret_v1" "spotinst_credentials" {
  metadata {
    name      = "spotinst-credentials"
    namespace = kubernetes_namespace_v1.spot_system.metadata[0].name
  }

  type = "Opaque"

  data = {
    token   = var.spotinst_token
    account = var.spotinst_account
  }
}

resource "kubernetes_secret_v1" "trident_azure_credentials" {
  metadata {
    name      = "trident-azure-credentials"
    namespace = var.trident_namespace
  }

  type = "Opaque"

  data = {
    subscriptionID = var.subscription_id
    tenantID       = var.tenant_id
    clientID       = var.trident_client_id
    clientSecret   = var.trident_client_secret
  }

  depends_on = [azurerm_role_assignment.trident_netapp_contributor, kubernetes_namespace_v1.trident]
}
