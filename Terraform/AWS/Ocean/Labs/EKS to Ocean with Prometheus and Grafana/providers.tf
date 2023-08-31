#Configure Providers
terraform {
  required_providers {
    spotinst = {
      source  = "spotinst/spotinst"
      version = "1.108.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "4.62.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.19.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.4.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.9.0"
    }
    grafana = {
      source = "grafana/grafana"
      version = "1.36.1"
    }
  }
}
### SPOT - SPOTINST
provider "spotinst" {
  token   = var.spotinst_token
  account = var.spotinst_account
  # Configuration options
}

### AWS
provider "aws" {
  region = var.region
}

### Data Resources for kubernetes provider
data "aws_eks_cluster" "cluster" {
  name       = module.eks.cluster_name
  depends_on = [module.eks.cluster_id]
}

data "aws_eks_cluster_auth" "cluster" {
  name       = module.eks.cluster_name
  depends_on = [module.eks.cluster_id]
}

data "aws_iam_instance_profiles" "profile" {
  role_name = module.eks.eks_managed_node_groups["green"].iam_role_name
}
### KUBERNETES
provider "kubernetes" {
  # config_path = "~/.kube/config"
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

### HELM
provider "helm" {
  kubernetes {
    # config_path = "~/.kube/config"
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}
