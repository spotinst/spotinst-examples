# Configure the AWS EKS Cluster
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_addons = {
    aws-ebs-csi-driver = {}
    coredns            = {}
    kube-proxy         = {}
    vpc-cni = {
      most_recent    = true
      before_compute = true
      configuration_values = jsonencode({
        env = {
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }
  }

  # This adds your Admin User to the configMap and lets you to see the compute resources in the AWS console
  manage_aws_auth_configmap = true
  aws_auth_roles = [
    {
      rolearn  = "arn:aws:iam::303703646777:role/Admin"
      username = "Admin"
      groups   = ["system:masters"]
    }
  ]

  kms_key_owners                 = var.kms_key_owners
  cluster_name                   = var.cluster_name
  cluster_version                = var.cluster_version
  vpc_id                         = var.vpc_id
  subnet_ids                     = var.private_subnet_ids
  cluster_endpoint_public_access = true
  iam_role_permissions_boundary  = var.iam_role_permissions_boundary

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    iam_role_permissions_boundary = var.iam_role_permissions_boundary
    instance_types                = var.instance_types
    subnet_ids                    = var.private_subnet_ids
    tags = {
      creator = var.creator
    }
  }

  eks_managed_node_groups = {
    nodeGroup1 = {
      min_size     = 0
      max_size     = 5
      desired_size = 1
    }
  }

  tags = {
    creator   = var.creator
  }
}

# Configure the Ocean Controller
module "ocean-controller" {
  source = "spotinst/ocean-controller/spotinst"

  depends_on = [module.eks]

  # Credentials.
  spotinst_token   = var.spot_token
  spotinst_account = var.spot_account

  # Configuration.
  cluster_identifier = module.eks.cluster_name
  tolerations        = []
}


# Configure the Ocean Module
module "ocean-aws-k8s" {
  source = "spotinst/ocean-aws-k8s/spotinst"

  depends_on = [module.eks]

  //configuration
  cluster_name               = module.eks.cluster_name
  region                     = var.aws_region
  subnet_ids                 = var.private_subnet_ids
  auto_headroom_percentage   = var.headroom
  availability_vs_cost       = var.availability_vs_cost
  spread_nodes_by            = var.spread
  utilize_commitments        = var.utilize_commitments
  utilize_reserved_instances = var.utilize_reserved_instances
  max_scale_down_percentage  = var.scale_down_percentage
  shutdown_hours             = var.shutdown_hours

  // region LAUNCH CONFIGURATION
  security_groups             = [module.eks.cluster_primary_security_group_id]
  key_name                    = var.key_pair
  worker_instance_profile_arn = tolist(data.aws_iam_instance_profiles.profile.arns)[0]
  use_as_template_only        = true
  min_size                    = 0

  tags = {
    creator   = var.creator
    protected = ""
  }
}


## Create additional Ocean Virtual Node Group (launchspec) ##
module "ocean-aws-k8s-vng1" {
  source = "spotinst/ocean-aws-k8s-vng/spotinst"

  depends_on = [module.ocean-controller, module.ocean-aws-k8s]

  name          = "vng1" # Name of VNG in Ocean
  ocean_id      = module.ocean-aws-k8s.ocean_id
  initial_nodes = 1
}