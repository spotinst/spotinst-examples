# Configure the Spotinst provider
provider "spotinst" {
   token   = "${var.spotinst_token}"
   account = "${var.spotinst_account}"
}

provider "aws" {
  region = "${var.region}"
}
