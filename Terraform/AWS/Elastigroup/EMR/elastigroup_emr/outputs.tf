output "elastigroup_id" {
  value = spotinst_mrscaler_aws.Terraform-MrScaler-01.id
}

output "cluster_id" {
  value = data.local_file.cluster.content
}

output "ip" {
  value = data.local_file.dns_name.content
}