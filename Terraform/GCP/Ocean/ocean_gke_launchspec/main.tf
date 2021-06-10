terraform {
  required_providers {
    spotinst = {
      source = "spotinst/spotinst"
    }
    google = {
      source = "hashicorp/google"
    }
  }
}

### Providers ###
provider "spotinst" {
  token   = var.spot_token
  account = var.spot_account
}
provider "google" {
  # Configuration options
  project = var.project
}
##################


#Data source to pull most recent COS image URI
data "google_compute_image" "COS" {
  family  = "cos-stable"
  project = "gke-node-images"
}
#Retrieve cluster info to get instance group URLS
data "google_container_cluster" "gke" {
  name     = var.cluster_name
  location = var.location
}
#Retrieve template info for each node group
data "google_compute_instance_template" "template" {
  for_each = toset(local.template_name)
  filter = "name eq ${each.key}.*"
  most_recent = true
  project = var.project
}

### Local resources ###
locals {
  # Get instance group URL and split to retrieve just the instance group name
  instance_group_split = [for s in data.google_container_cluster.gke.instance_group_urls : split("/", s)]
  # Store the list of instance group names from the specific cluster
  instance_group_name = flatten([for s in local.instance_group_split : concat([s[10]])])
  #Split the instance groups to remove the random generated suffix
  template_name_split = [for s in local.instance_group_name : split("-", s)]
  #Remove the suffix
  template_size = [for s in local.template_name_split: slice(s, 0,length(s)-2)]
  #Store the template prefix to retrieve the template data
  template_name = [for s in local.template_size: join("-", s)]
}
#######################


### Spot Ocean Launchspec resource - create a launchspec using default node pool and add additional configurations. ###
resource "spotinst_ocean_gke_launch_spec" "launchspec" {

  ocean_id            = var.ocean_id
  source_image        = data.google_compute_image.COS.self_link
  restrict_scale_down = false

  dynamic "metadata" {
    for_each = data.google_compute_instance_template.template[local.template_name[0]].metadata
    content {
      key   = metadata.key
      value = metadata.value
    }
  }

  strategy {
    preemptible_percentage = var.preemptible_percentage
  }

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
}