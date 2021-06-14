terraform {
  required_providers {
    spotinst = {
      source = "spotinst/spotinst"
    }
  }
}

### Providers ###
provider "spotinst" {
  token   = var.spotinst_token
  account = var.spotinst_account
}
provider "aws" {
  region = var.region
  profile = var.aws_profile
}
provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}
##################

### Data Resources ###
data "aws_eks_cluster" "cluster" {
  name    = var.cluster_name
}
data "aws_eks_cluster_auth" "cluster" {
  name    = var.cluster_name
}
data "aws_ami" "eks_worker" {
  filter {
    name   = "name"
    values = [local.worker_ami_name_filter]
  }
  most_recent = true
  owners = ["amazon"]
}
##################

### Local Variable ###
locals {
  worker_ami_name_filter = "amazon-eks-node-${data.aws_eks_cluster.cluster.version}-v*"
}
##################

## Create Ocean Cluster in Spot.io
resource "spotinst_ocean_aws" "ocean" {
  name                                = var.cluster_name
  controller_id                       = var.cluster_name
  region                              = var.region
  max_size                            = var.max_size
  min_size                            = var.min_size
  desired_capacity                    = var.desired_capacity
  subnet_ids                          = var.subnet_ids
  image_id                            = var.ami_id != null ? var.ami_id : data.aws_ami.eks_worker.id
  security_groups                     = var.security_groups
  key_name                            = var.key_name
  associate_public_ip_address         = var.associate_public_ip_address
  iam_instance_profile                = var.worker_instance_profile_arn
  blacklist                           = var.blacklist
  fallback_to_ondemand                = var.fallback_to_ondemand
  utilize_reserved_instances          = var.utilize_reserved_instances
  draining_timeout                    = var.draining_timeout
  grace_period                        = var.grace_period
  spot_percentage                     = var.spot_percentage

  user_data = <<-EOF
    #!/bin/bash
    set -o xtrace
    /etc/eks/bootstrap.sh ${var.cluster_name}
EOF

  tags {
    key   = "Name"
    value = "${var.cluster_name}-ocean-cluster-node"
  }
  tags {
    key   = "kubernetes.io/cluster/${var.cluster_name}"
    value = "owned"
  }

  dynamic tags {
    for_each = var.tags == null ? [] : var.tags
    content {
      key = tags.value["key"]
      value = tags.value["value"]
    }
  }

  # Auto Scaler Configurations
  autoscaler {
    autoscale_is_enabled          = var.autoscale_is_enabled
    autoscale_is_auto_config      = var.autoscale_is_auto_config
    auto_headroom_percentage      = var.auto_headroom_percentage
    autoscale_down {
      max_scale_down_percentage   = var.max_scale_down_percentage
    }
  }

  # Policy when config is updated
  update_policy {
    should_roll               = var.should_roll
    roll_config {
      batch_size_percentage   = var.batch_size_percentage
    }
  }

  # Prevent Capacity from changing during updates
  lifecycle {
    ignore_changes = [
      desired_capacity
    ]
  }
}

## Deploy Ocean Controller Pod into Cluster ##
module "ocean-controller" {
  source = "spotinst/ocean-controller/spotinst"

  # Credentials.
  spotinst_token      = var.spotinst_token
  spotinst_account    = var.spotinst_account

  # Configuration.
  cluster_identifier  = var.cluster_name
  disable_auto_update = false
}
