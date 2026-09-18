variable "tenant_id" {
  description = "The Tenant ID for the Azure subscription"
  type        = string
  default     = ""
}

variable "billing_account_id" {
  description = "The Billing Account ID"
  type        = string
  default     = ""
}

# Provider block
provider "azuread" {
  version = "3.0.0"
}
provider "azurerm" {
  version = "3.0.0"
  features {}
}
# Resource block
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

# Role assignments
# assign reservation reader role
resource "null_resource" "reservation_reader_role_assignment" {
  provisioner "local-exec" {
    command = 'az role assignment create --assignee ${azuread_application_registration.create_registered_app.id} --role "Reservations Reader" --scope "/providers/Microsoft.Capacity"'
  }
}

# assign reservation purchaser role
resource "azurerm_role_assignment" "reservation_purchaser_role_assignment" {
  role_definition_name = "Reservations Purchaser"
  principal_id = azuread_service_principal.create_service_principal.id
  scope = "/providers/Microsoft.Management/managementGroups/${var.tenant_id}"
}

# assign reservation administrator role
resource "null_resource" "reservation_administrator_role_assignment" {
  provisioner "local-exec" {
    command = 'az role assignment create --assignee ${azuread_application_registration.create_registered_app.id} --role "Reservations Administrator" --scope "/providers/Microsoft.Capacity"'
  }
}

# assign savings plan reader role
resource "null_resource" "reservation_administrator_role_assignment" {
  provisioner "local-exec" {
    command = 'az role assignment create --assignee ${azuread_application_registration.create_registered_app.id} --role "Savings plan Reader" --scope "/providers/Microsoft.BillingBenefits"'
  }
}

# assign savings plan purchaser role
resource "azurerm_role_assignment" "reservation_purchaser_role_assignment" {
  role_definition_name = "Savings plan Purchaser"
  principal_id = azuread_service_principal.create_service_principal.id
  scope = "/providers/Microsoft.Management/managementGroups/${var.tenant_id}"
}

# assign savings plan administrator role
resource "null_resource" "reservation_administrator_role_assignment" {
  provisioner "local-exec" {
    command = 'az role assignment create --assignee ${azuread_application_registration.create_registered_app.id} --role "Savings plan Administrator" --scope "/providers/Microsoft.BillingBenefits"'
  }
}

# assign cost management reader role
resource "azurerm_role_assignment" "cost_management_reader_role_assignment" {
  role_definition_name = "Cost Management Reader"
  principal_id = azuread_service_principal.create_service_principal.id
  scope = "/providers/Microsoft.Management/managementGroups/${var.tenant_id}"
}

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
