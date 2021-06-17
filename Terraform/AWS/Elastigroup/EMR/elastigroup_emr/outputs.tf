output "elastigroup_id" {
  value = spotinst_mrscaler_aws.Terraform-MrScaler-01.id
}

output "cluster_id" {
  value = local.cluster_id
}

output "ip" {
  value = local.dns_name
}