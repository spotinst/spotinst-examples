provider "aws" {
    version = "~> 2.35"
}

provider "external" {
    version = "~> 1.2"
}

provider "null" {
    version = "~> 2.1"
}

provider "random" {
    version = "~> 2.2"
}

module "spot_account" {
    source = "spot-account"
    #Desired Name of the Spot Account
    name = "test-terraform"
}

output "spot_account_id" {
    value = module.spot_account.spot_account_id
}
