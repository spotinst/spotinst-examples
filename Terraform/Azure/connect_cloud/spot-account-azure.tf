#Call the spot module to create a Spot account and link Azure
module "spot_subscription_1" {
  source = "spot-account-azure"
  spot_token = ""
  subscription_id = ""
  tenant_id = ""
}

output "spot_account_id_1" {
  value = module.spot_subscription_1.spot_account_id
}

module "spot_subscription_2" {
  source = "spot-account-azure"
  spot_token = ""
  subscription_id = ""
  tenant_id = ""
}

output "spot_account_id_2" {
  value = module.spot_subscription_2.spot_account_id
}

