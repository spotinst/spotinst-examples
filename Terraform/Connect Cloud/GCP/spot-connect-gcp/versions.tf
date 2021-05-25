terraform {
  required_providers {
    external = {
      source = "hashicorp/external"
    }
    null = {
      source = "hashicorp/null"
    }
  }
  required_version = ">= 0.13"
}
