provider "aws" {
/* 	access_key = "${var.ACCESS_KEY}"
	secret_key = "${var.SECRET_KEY}" */
	region     = "${var.AWS_REGION}"
}
provider "spotinst" {
    token   = "${var.SPOTINST_TOKEN}"
    account = "${var.SPOTINST_ACC}"
}
