locals {
    cmd = "${path.module}/scripts/spot-account"
    account_id = data.external.account.result["account_id"]
    external_id = "spot:aws:extid:${random_id.external_id.hex}"
    name = var.name
}

# Create a random string for the external ID attached to the role
resource "random_id" "external_id" {
  byte_length = 8
}

# Create the AWS Role for Spot
resource "aws_iam_role" "spot"{
    name = "SpotRole-${random_id.external_id.hex}"
    provisioner "local-exec" {
        # Without this set-cloud-credentials fails 
        command = "sleep 10"
    }
    assume_role_policy = <<-EOT
        {
            "Version": "2012-10-17",
            "Statement": [
                {
                "Effect": "Allow",
                "Principal": {
                    "AWS": "arn:aws:iam::922761411349:root"
                },
                "Action": "sts:AssumeRole",
                "Condition": {
                    "StringEquals": {
                    "sts:ExternalId": "${local.external_id}"
                    }
                }
                }
            ]
        }
    EOT
}

# Create the Policy
resource "aws_iam_policy" "spot" {
  name        = "Spot-Policy-${random_id.external_id.hex}"
  path        = "/"
  description = "Allow Spot.io to manage resources"

  policy = templatefile("${path.module}/spot_policy.json", {})
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "spot" {
  role       = aws_iam_role.spot.name
  policy_arn = aws_iam_policy.spot.arn
}

# Call Spot API to create the Spot Account 
resource "null_resource" "account" {
    triggers = {
        cmd = "${path.module}/scripts/spot-account"
        name = var.name
    }
    provisioner "local-exec" {
        interpreter = ["/bin/bash", "-c"]
        command = "${self.triggers.cmd} create ${self.triggers.name}"
    }

    provisioner "local-exec" {
        when = destroy
        interpreter = ["/bin/bash", "-c"]
        command = <<-EOT
            ID=$(${self.triggers.cmd} get --filter=name=${self.triggers.name} --attr=account_id) &&\
            ${self.triggers.cmd} delete "$ID"
        EOT
    }
}

# Retrieve the Spot Account Information
data "external" "account" {
    depends_on = [null_resource.account]
    program = [
        local.cmd,
        "get",
        "--filter=name=${var.name}"
    ]
}

# Link the Role ARN to the Spot Account
resource "null_resource" "account_association" {
    depends_on = [aws_iam_role.spot]
    provisioner "local-exec" {
        interpreter = ["/bin/bash", "-c"]
        command = "${local.cmd} set-cloud-credentials ${local.account_id} ${aws_iam_role.spot.arn} ${local.external_id}"
    } 
}