variable "subscription_id" {}
variable "tenant_id" {}


# Configure the Azure Provider
provider "azurerm" {
  version = "=2.42.0"
  features {}
  subscription_id = var.subscription_id
}

provider "azuread" {
  version = ">1.0.0"
  tenant_id = var.tenant_id
}

# Create a random string for the azure app registration
resource "random_string" "value" {
  length = 24
  special = false
}

resource "azuread_application" "spot" {
  name                        = "spot-azure"
  available_to_other_tenants  = false
  oauth2_permissions          = []
  reply_urls                  = ["https://spot.io"]
  type                        = "webapp/api"

}

resource "azuread_application_password" "spot-credential" {
  application_object_id = azuread_application.spot.id
  description           = "Spot.io Managed Password"
  value                 = random_string.value.result
  end_date              = "2099-01-01T01:02:03Z"
}


data "azurerm_subscription" "current" {}
data "azurerm_client_config" "current" {}

resource "azurerm_role_definition" "spot" {
  name        = "Spot.io-custom-role"
  scope       = data.azurerm_subscription.current.id
  description = "This is a custom role created via Terraform for Spot.io App"

  permissions {
    actions = [
      "Microsoft.Compute/disks/read",
      "Microsoft.Compute/disks/write",
      "Microsoft.Compute/disks/delete",
      "Microsoft.Compute/disks/beginGetAccess/action",
      "Microsoft.Compute/images/read",
      "Microsoft.Compute/images/write",
      "Microsoft.Compute/snapshots/read",
      "Microsoft.Compute/virtualMachines/*",
      "Microsoft.Compute/virtualMachineScaleSets/read",
      "Microsoft.Compute/virtualMachineScaleSets/instanceView/read",
      "Microsoft.Compute/virtualMachineScaleSets/networkInterfaces/read",
      "Microsoft.Compute/virtualMachineScaleSets/publicIPAddresses/read",
      "Microsoft.Compute/virtualMachineScaleSets/virtualMachines/extensions/read",
      "Microsoft.Insights/MetricDefinitions/Read",
      "Microsoft.Insights/Metrics/Read",
      "Microsoft.Insights/AutoscaleSettings/Read",
      "Microsoft.Insights/AutoscaleSettings/providers/Microsoft.Insights/MetricDefinitions/Read",
      "Microsoft.ManagedIdentity/userAssignedIdentities/assign/action",
      "Microsoft.ManagedIdentity/identities/read",
      "Microsoft.NetApp/netAppAccounts/read",
      "Microsoft.NetApp/netAppAccounts/write",
      "Microsoft.NetApp/netAppAccounts/capacityPools/write",
      "Microsoft.NetApp/netAppAccounts/capacityPools/read",
      "Microsoft.NetApp/netAppAccounts/capacityPools/delete",
      "Microsoft.NetApp/netAppAccounts/capacityPools/volumes/write",
      "Microsoft.NetApp/netAppAccounts/capacityPools/volumes/read",
      "Microsoft.NetApp/netAppAccounts/capacityPools/volumes/delete",
      "Microsoft.NetApp/netAppAccounts/capacityPools/volumes/snapshots/write",
      "Microsoft.NetApp/netAppAccounts/capacityPools/volumes/snapshots/read",
      "Microsoft.NetApp/netAppAccounts/capacityPools/volumes/ReplicationStatus/read",
      "Microsoft.NetApp/netAppAccounts/capacityPools/volumes/DeleteReplication/action",
      "Microsoft.NetApp/netAppAccounts/capacityPools/volumes/ResyncReplication/action",
      "Microsoft.NetApp/netAppAccounts/capacityPools/volumes/AuthorizeReplication/action",
      "Microsoft.NetApp/netAppAccounts/capacityPools/volumes/ReInitializeReplication/action",
      "Microsoft.NetApp/netAppAccounts/capacityPools/volumes/BreakReplication/action",
      "Microsoft.Network/applicationGateways/read",
      "Microsoft.Network/applicationGateways/backendhealth/action",
      "Microsoft.Network/applicationGateways/backendAddressPools/join/action",
      "Microsoft.Network/dnsZones/read",
      "Microsoft.Network/dnsZones/A/read",
      "Microsoft.Network/dnsZones/write",
      "Microsoft.Network/dnsZones/A/write",
      "Microsoft.Network/dnsZones/A/delete",
      "Microsoft.Network/loadBalancers/read",
      "Microsoft.Network/loadBalancers/backendAddressPools/read",
      "Microsoft.Network/loadBalancers/backendAddressPools/write",
      "Microsoft.Network/loadBalancers/backendAddressPools/join/action",
      "Microsoft.Network/networkInterfaces/read",
      "Microsoft.Network/networkInterfaces/write",
      "Microsoft.Network/networkInterfaces/delete",
      "Microsoft.Network/networkInterfaces/join/action",
      "Microsoft.Network/networkInterfaces/ipconfigurations/read",
      "Microsoft.Network/networkSecurityGroups/read",
      "Microsoft.Network/networkSecurityGroups/join/action",
      "Microsoft.Network/publicIPAddresses/read",
      "Microsoft.Network/publicIPAddresses/write",
      "Microsoft.Network/publicIPAddresses/delete",
      "Microsoft.Network/publicIPAddresses/join/action",
      "Microsoft.Network/virtualNetworks/read",
      "Microsoft.Network/virtualNetworks/subnets/join/action",
      "Microsoft.Network/virtualNetworks/subnets/read",
      "Microsoft.Network/virtualNetworks/virtualMachines/read",
      "Microsoft.Network/virtualNetworks/subnets/write",
      "Microsoft.Resources/tags/write",
      "Microsoft.Resources/subscriptions/resourceGroups/read",
      "Microsoft.ContainerService/managedClusters/read",
      "Microsoft.ContainerService/managedClusters/agentPools/read"
    ]
    not_actions = []
  }

  assignable_scopes = [
    data.azurerm_subscription.current.id
  ]
}



resource "azuread_service_principal" "spot" {
  depends_on = [ 
    azuread_application.spot,
  ]
  application_id       = azuread_application.spot.application_id
}

resource "azurerm_role_assignment" "spot" {
  scope                = data.azurerm_subscription.current.id
  role_definition_id   = azurerm_role_definition.spot.role_definition_resource_id
  principal_id         = azuread_service_principal.spot.object_id
}


output "application_id" {
  value = azuread_application.spot.application_id
}
output "subscription_id" {
  value = data.azurerm_subscription.current.subscription_id
}
output "client_secret" {
  value = random_string.value.result
}
output "directory_id" {
  value = data.azurerm_client_config.current.tenant_id
}



