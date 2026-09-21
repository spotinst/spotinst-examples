terraform {
  required_version = ">=1.0"

  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = "~> 1.13"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.2"
    }
    spotinst = {
      source  = "spotinst/spotinst"
      version = "~> 1.175"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}

provider "spotinst" {
  token   = var.spotinst_token
  account = var.spotinst_account
}
