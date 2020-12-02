module "eks" {
  version            = "v4.0.2"
  source             = "terraform-aws-modules/eks/aws"
  cluster_name       = "EKS-${var.CLUSTER_NAME}-spotinst"
  subnets            = ["${var.SUBNET_ID}"]
  vpc_id             = "${var.VPC_ID}"
  worker_group_count = 0

  map_roles_count    = 1
  map_roles          = [
    {
      role_arn = "${aws_iam_role.workers.arn}"
      username = "system:node:{{EC2PrivateDNSName}}"
      group = "system:nodes"
    },
  ]

  worker_additional_security_group_ids = ["${var.SECURITY_GROUPS}"]
}