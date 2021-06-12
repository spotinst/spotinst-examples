module "spot_account_aws" {
    source = "./spot-account"

    #AWS Profile (Optional)
    #profile = ""

    #Name of the linked account in Spot (Optional) If none is provided will use account alias as the account name.
    #name = "test-terraform"

}

output "spot_account_id" {
    value = module.spot_account_aws.spot_account_id
}
