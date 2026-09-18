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
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.38"
    }
    spotinst = {
      source  = "spotinst/spotinst"
      version = "~> 1.175"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}

provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.k8s.kube_config[0].host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.k8s.kube_config[0].client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.k8s.kube_config[0].client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.k8s.kube_config[0].cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = azurerm_kubernetes_cluster.k8s.kube_config[0].host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.k8s.kube_config[0].client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.k8s.kube_config[0].client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.k8s.kube_config[0].cluster_ca_certificate)
  }
}

provider "spotinst" {
  token   = var.spotinst_token
  account = var.spotinst_account
}

provider "github" {
  owner = var.github_owner
}