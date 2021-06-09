module "spot_account" {
    source = "spot-account"
    #Desired Name of the Spot Account
    name = "test-terraform"
    token = "c09767fd287c6c0df90a4eeba2380c34e248cd02faee419f81ee7b7be795a52f"
}

output "spot_account_id" {
    value = module.spot_account.spot_account_id
}
