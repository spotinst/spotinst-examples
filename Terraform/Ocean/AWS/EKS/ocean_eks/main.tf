terraform {
  required_providers {
    spotinst = {
      source = "spotinst/spotinst"
    }
  }
}

#Set up Spotinst Provider
provider "spotinst" {
  token   = var.spotinst_token
  account = var.spotinst_account
}

provider "aws" {
  region = var.region
}

data "aws_eks_cluster" "cluster" {
  name    = var.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name    = var.cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

locals {
  standard_tags = {
    CreatedBy = "terraform"
    protected = "true"
    spot   = "true"
  }
}

## Create Ocean Cluster in Spot.io
resource "spotinst_ocean_aws" "ocean" {
  name                                = var.cluster_name
  controller_id                       = var.cluster_name
  region                              = var.region
  max_size                            = var.max_size
  min_size                            = var.min_size
  desired_capacity                    = var.desired_capacity
  subnet_ids                          = var.subnet_ids
  image_id                            = var.ami_id
  security_groups                     = var.security_groups
  key_name                            = var.key_name
  associate_public_ip_address         = var.associate_public_ip_address
  iam_instance_profile                = var.worker_instance_profile_arn
  blacklist                           = var.blacklist
  fallback_to_ondemand                = var.fallback_to_ondemand
  utilize_reserved_instances          = var.utilize_reserved_instances
  draining_timeout                    = var.draining_timeout
  grace_period                        = var.grace_period

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

  dynamic "tags" {
    for_each = local.standard_tags
    content {
      key   = tags.key
      value = tags.value
    }
  }

  # Auto Scaler Configurations
  autoscaler {
    autoscale_is_enabled          = true
    autoscale_is_auto_config      = true
    auto_headroom_percentage      = 5
    autoscale_down {
      max_scale_down_percentage   = 10
    }
  }

  # Policy when config is updated
  update_policy {
    should_roll               = false
    roll_config {
      batch_size_percentage   = 20
    }
  }

  # Prevent Capacity from changing during updates
  lifecycle {
    ignore_changes = [
      desired_capacity
    ]
  }
}

## Create Virtual Node group (Launch Spec)
resource "spotinst_ocean_aws_launch_spec" "nodegroup" {
  ocean_id = spotinst_ocean_aws.ocean.id
  name = "nodegroup"


  image_id = var.ami_id
  user_data = <<-EOF
    #!/bin/bash
    set -o xtrace
    /etc/eks/bootstrap.sh ${var.cluster_name}
EOF

  iam_instance_profile    = var.worker_instance_profile_arn
  security_groups         = [var.worker_security_group_id]
  subnet_ids              = var.subnet_ids
  instance_types          = var.instance_types
  root_volume_size        = var.root_volume_size


  labels {
    key = "type"
    value = "gpu"
  }

  taints {
    key = "type"
    value = "gpu"
    effect = "NoSchedule"
  }

  resource_limits {
    max_instance_count    = var.max_instance_count
  }

  tags {
    key = "Name"
    value = "${var.cluster_name}-ocean-cluster-node"
  }
  tags {
    key = "kubernetes.io/cluster/${var.cluster_name}"
    value = "owned"
  }

  dynamic "tags" {
    for_each = local.standard_tags
    content {
      key = tags.key
      value = tags.value
    }
  }

  strategy {
    spot_percentage = var.spot_percentage
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
  disable_auto_update = true
}
