locals {
  eks_details = <<EKS_DETAILS
EKS_CLUSTER_NAME="${module.eks.cluster_id}"
EKS_ENDPOINT="${module.eks.cluster_endpoint}"
EKS_CERTIFICATE="${module.eks.cluster_certificate_authority_data}"
SPOTINST_OCEAN_NAME="${spotinst_ocean_aws.tf_ocean_cluster.name}"
EKS_DETAILS
}

output "EKS_DETAILS" {
  value = "${local.eks_details}"
} 