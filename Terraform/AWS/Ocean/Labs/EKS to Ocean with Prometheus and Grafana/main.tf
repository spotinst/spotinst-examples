# # # CREATING NEW EKS CLUSTER re: https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name                  = var.cluster_name
  cluster_version               = "1.24"
  iam_role_permissions_boundary = "arn:aws:iam::303703646777:policy/deny_ec2_without_creator" ## removes boundaries of iam limit

  cluster_endpoint_public_access = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
  }

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  manage_aws_auth_configmap = true
  aws_auth_roles = [
    {
      rolearn  = var.rolearn
      username = "Admin"
      groups = [
        "system:masters"
      ]
    },
  ]

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    instance_types = ["t3.large", "m5.large"]
  }

  eks_managed_node_groups = {
    green = {
      min_size     = 0
      max_size     = 5
      desired_size = 2
      # instance_types = ["t3.large","m5.large"]
      capacity_type = "SPOT"
    }

  }
  tags = {
    Creator = var.creator
  }
}

# # # INSTALLING OCEAN CONTROLLER re: https://registry.terraform.io/modules/spotinst/ocean-controller/spotinst/latest
module "ocean-controller" {
  source  = "spotinst/ocean-controller/spotinst"
  version = "0.43.0"
  ## MOVE SPOT CONTROLLER TO VARIABLES - TO ART
  controller_version = var.ocean-controller-version
  depends_on         = [module.eks]

  # Credentials.
  spotinst_token   = var.spotinst_token
  spotinst_account = var.spotinst_account

  # Configuration.
  cluster_identifier = module.ocean-aws-k8s.ocean_controller_id
}

# # #  INSTALLING OCEAN-AWS-K8S re: https://github.com/spotinst/terraform-spotinst-ocean-aws-k8s
module "ocean-aws-k8s" {
  source       = "spotinst/ocean-aws-k8s/spotinst"
  depends_on   = [module.eks]
  cluster_name = module.eks.cluster_name

  # Configuration
  region                      = var.region
  subnet_ids                  = var.subnet_ids
  security_groups             = [module.eks.node_security_group_id]
  min_size                    = 0
  worker_instance_profile_arn = tolist(data.aws_iam_instance_profiles.profile.arns)[0]
  tags                        = { Creator = var.creator }
}

# # # CREATE NAMESPACE FOR PROMETHEUS STACK - suggested "MONITORING"
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = var.prometheusnamespace
  }
}

# # # ADDING/REFRESHING CLUSTER TO KUBECTX
resource "null_resource" "kubectx" {
  provisioner "local-exec" {
    command = "aws eks --region us-west-2 update-kubeconfig --name ${var.cluster_name}"
  }
  depends_on = [module.ocean-controller]
}

# # # ADDING GRAFANA CLOUD SECRETS TO K8S
resource "null_resource" "secrets" {
  provisioner "local-exec" {
    command = "kubectl create secret generic kubepromsecret --from-literal=username=${var.grafana_user} --from-literal=password=${var.grafana_apikey} -n monitoring"
  }
  # depends_on = [resource.kubernetes_namespace.monitoring]
  depends_on = [resource.null_resource.kubectx]
}

# # # INSTALL PROMETHEUS-STACK VIA HELM-RELEASE MODULE/kube-prometheus
# # # RE: https://artifacthub.io/packages/helm/prometheus-community/kube-prometheus-stack
module "kube-prometheus" {
  source       = "./modules/kube-prometheus"
  namespace    = var.prometheusnamespace
  kube-version = "36.2.0"
  depends_on   = [resource.null_resource.secrets]
}

# # # INSTALL OCEAN SPOT METRICS Exporter re: https://registry.terraform.io/modules/spotinst/ocean-metric-exporter/spotinst/latest
module "ocean-metric-exporter" {
  source                          = "spotinst/ocean-metric-exporter/spotinst"
  namespace                       = "kube-system"
  depends_on                      = [module.eks.cluster_name]
  metricsconfiguration_categories = ["cost_analysis", "scaling"]
}
# # # END OF SCRIPT INFO ON HOW TO ACCESS COMPONENTS
output "c_grafana_access" {
  value = [
    "kubectl port-forward svc/kube-prometheus-stackr-grafana 3000:80 --namespace ${var.prometheusnamespace}",
    "Access http://localhost:3000",

    "Grafana creds     ",
    "   admin          ",
    "   prom-operator  "
  ]
}
output "b_prometheus_access" {
  value = [
    "kubectl port-forward svc/kube-prometheus-stackr-prometheus 9090:9090 --namespace ${var.prometheusnamespace}",
    "Access at http://localhost:9090"
  ]
}
output "a_welcome_message" {
  value = [
    " !!! INSTRUCTIONS TO ACCESS PROMETHEUS AND GRAFANA ",
    " >>> RUN EACH COMMAND IN DIFFERENT TERMINAL SESSIONS !!! "
  ]
}