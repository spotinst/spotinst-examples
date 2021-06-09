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

## Create Virtual Node group (Launch Spec)
resource "spotinst_ocean_aws_launch_spec" "nodegroup" {
  ocean_id = var.ocean_id
  name = var.name

  user_data               = var.user_data
  image_id                = var.ami_id
  iam_instance_profile    = var.worker_instance_profile_arn
  security_groups         = var.security_groups
  subnet_ids              = var.subnet_ids
  instance_types          = var.instance_types
  root_volume_size        = var.root_volume_size

  dynamic labels {
    for_each = var.labels == null ? [] : var.labels
    content {
      key = labels.value["key"]
      value = labels.value["value"]
    }
  }

  dynamic taints {
    for_each = var.taints == null ? [] : var.taints
    content {
      key = taints.value["key"]
      value = taints.value["value"]
      effect = taints.value["effect"]
    }
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

  dynamic tags {
    for_each = var.tags == null ? [] : var.tags
    content {
      key = tags.value["key"]
      value = tags.value["value"]
    }
  }

  strategy {
    spot_percentage = var.spot_percentage
  }
}