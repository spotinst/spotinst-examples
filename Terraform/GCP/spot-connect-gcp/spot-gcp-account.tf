provider "external" {
    version = "~> 1.2"
}

provider "null" {
    version = "~> 2.1"
}

module "spot_account" {
    source = "./spot-account"
    name = "steven-terraform-gcp"
    service_account_name = "steven-terraform-gcp"
    project = "spotinst-labs"
}

output "spot_account_id" {
    value = module.spot_account.spot_account_id
}
