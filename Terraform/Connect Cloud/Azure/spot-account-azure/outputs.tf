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

output "spot_account_id" {
  description = "spot account_id"
  value = local.account_id
}
