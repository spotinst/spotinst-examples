#################
### Variables ###
#################

# Provider block
provider "azuread" {
  version = "3.0.0"
}
provider "azurerm" {
  version = "3.0.0"
  features {}
}
#################
### Resources ###
#################
# Create an Azure AD application registration
resource "azuread_application_registration" "create_registered_app" {
  display_name = "EcoAzureADApp3"
}
# Create an Azure AD service principal
resource "azuread_service_principal" "create_service_principal" {
   client_id = azuread_application_registration.create_registered_app.client_id
}
# Create an Azure AD application password
resource "azuread_application_password" "create_secret_key" {
  application_id = azuread_application_registration.create_registered_app.id
}
########################
### Role Assignments ###
########################
{{role_assignments}}
# Output
output "client_id" {
  value = azuread_application_registration.create_registered_app.client_id
}
output "object_id" {
  value = azuread_service_principal.create_service_principal.object_id
}
output "application_secret" {
  value = azuread_application_password.create_secret_key.value
  sensitive = true
}
data "azuread_client_config" "current" {}


