resource "azapi_resource_action" "ssh_public_key_gen" {
  type        = "Microsoft.Compute/sshPublicKeys@2022-11-01"
  resource_id = azapi_resource.ssh_public_key.id
  action      = "generateKeyPair"
  method      = "POST"

  response_export_values = ["publicKey", "privateKey"]
}

resource "azapi_resource" "ssh_public_key" {
  type      = "Microsoft.Compute/sshPublicKeys@2022-11-01"
  name      = var.cluster_name
  location  = azurerm_resource_group.rg.location
  parent_id = azurerm_resource_group.rg.id

  lifecycle {
    ignore_changes = [name]
  }
}

output "key_data" {
  value = azapi_resource_action.ssh_public_key_gen.output.publicKey
}