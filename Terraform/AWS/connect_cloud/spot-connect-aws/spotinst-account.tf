module "spot_account" {
    source = "spot-account"
    #Desired Name of the Spot Account
    name = "test-terraform"
    token = ""
}

output "spot_account_id" {
    value = module.spot_account.spot_account_id
}
