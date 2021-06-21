terraform {
  required_version = ">= 0.13.1"
  required_providers {
    azuread = {
      source = "hashicorp/azuread"
      version = "<2.0.0"
    }
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
}

## Providers ##
# Configure the Azure Provider
provider "azurerm" {
  subscription_id = var.subscription_id
  features {}
}
provider "azuread" {
  tenant_id = var.tenant_id
}
###############

## Locals ##
locals {
  cmd = "${path.module}/scripts/spot-account"
  account_id = lookup(data.external.account.result,"account_id","Fail")
}
###############

## Data Resources ##
data "azurerm_subscription" "current" {}
data "azurerm_client_config" "current" {}
###############

## Resources ##
# Create a random string for the azure app registration
resource "random_string" "value" {
  length = 24
  special = false
}

resource "azuread_application" "spot" {
  name                        = "Spot.io-${data.azurerm_subscription.current.display_name}"
  available_to_other_tenants  = false
  oauth2_permissions          = []
  reply_urls                  = ["https://spot.io"]
  type                        = "webapp/api"

}

resource "azuread_application_password" "spot-credential" {
  depends_on            = [azuread_application.spot]
  application_object_id = azuread_application.spot.id
  description           = "Spot.io Managed Password"
  value                 = random_string.value.result
  end_date              = "2099-01-01T01:02:03Z"
}

resource "azurerm_role_definition" "spot" {
  name        = "Spot.io-custom-role-${data.azurerm_subscription.current.display_name}"
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
      "Microsoft.Resources/subscriptions/resourceGroups/read"
    ]
    not_actions = []
  }

  assignable_scopes = [
    data.azurerm_subscription.current.id
  ]
}

resource "azuread_service_principal" "spot" {
  depends_on           = [azuread_application.spot]
  application_id       = azuread_application.spot.application_id
}

resource "azurerm_role_assignment" "spot" {
  scope                = data.azurerm_subscription.current.id
  role_definition_id   = azurerm_role_definition.spot.role_definition_resource_id
  principal_id         = azuread_service_principal.spot.object_id
}

#Remove spaces from display name
# Call Spot API to create the Spot Account
resource "null_resource" "account" {
  triggers = {
    cmd = "${path.module}/scripts/spot-account"
    name = data.azurerm_subscription.current.display_name
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = "${self.triggers.cmd} create \"${self.triggers.name}\""
  }

  provisioner "local-exec" {
    when = destroy
    interpreter = ["/bin/bash", "-c"]
    command = <<-EOT
            ID=$(${self.triggers.cmd} get --filter=name="${self.triggers.name}" --attr=account_id) &&\
            ${self.triggers.cmd} delete "$ID"
        EOT
  }
}

# Retrieve the Spot Account Information
data "external" "account" {
  depends_on = [null_resource.account]
  program = [local.cmd, "get", "--name=${data.azurerm_subscription.current.display_name}"]
}
# Link the Role ARN to the Spot Account
resource "null_resource" "account_association" {
  depends_on = [azurerm_role_assignment.spot]
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = "${local.cmd} set-cloud-credentials --account_id ${local.account_id} --token ${var.spot_token} --client_id ${azuread_application.spot.application_id} --client_secret ${random_string.value.result} --tenant_id ${data.azurerm_client_config.current.tenant_id} --subscription_id ${var.subscription_id}"
  }
}

