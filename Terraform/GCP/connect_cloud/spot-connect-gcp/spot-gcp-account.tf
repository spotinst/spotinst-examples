provider "external" {
    version = "~> 1.2"
}

provider "null" {
    version = "~> 2.1"
}

#Call the spot module to create a Spot account and link project
module "spot_account" {
    source = "spot-account"
    #Name of the Spot Account
    name = "terraform-gcp"
    #Name of the service Account
    service_account_name = "spot-terraform"
    project = "example"
}

output "spot_account_id" {
    value = module.spot_account.spot_account_id
}
