
# Spotinst resource to create the worker nodes.

resource "spotinst_ocean_aws" "tf_ocean_cluster" {
  name          = "${var.CLUSTER_NAME}"
  controller_id = "${var.CLUSTER_NAME}"
  region        = "${var.AWS_REGION}"

  max_size         = "100000"
  min_size         = "1"
  desired_capacity = "1"

  subnet_ids = ["${var.SUBNET_ID}"]

  image_id        = "${lookup(var.AMI_ID,var.AWS_REGION)}"
  security_groups = ["${var.SECURITY_GROUPS}","${module.eks.worker_security_group_id}"]
  key_name        = "${var.KEY_NAME}"
  root_volume_size = "${var.ROOT_VOL_SIZE}"
  user_data = <<-EOF
      #!/bin/bash
      set -o xtrace
      /etc/eks/bootstrap.sh ${module.eks.cluster_id}
      EOF

  iam_instance_profile = "${aws_iam_instance_profile.workers.arn}"
  tags = ["${var.TAGS}"]
  tags = [
    {
      key = "Name"
      value = "EKS-SPOTINST-${var.CLUSTER_NAME}-Instances"
    },
    {
      key = "kubernetes.io/cluster/${module.eks.cluster_id}"
      value =  "owned"
    }
  ]

  depends_on = ["module.eks"]
}


# Creating the instance profile and roles.
data "aws_iam_policy_document" "workers_assume_role_policy" {
  statement {
    sid = "EKSWorkerAssumeRole"

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "workers" {
  name_prefix           = "${var.CLUSTER_NAME}"
  assume_role_policy    = "${data.aws_iam_policy_document.workers_assume_role_policy.json}"
  force_detach_policies = true
}

resource "aws_iam_instance_profile" "workers" {
  name_prefix = "${var.CLUSTER_NAME}"
  role        = "${aws_iam_role.workers.name}"
}

resource "aws_iam_role_policy_attachment" "workers_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = "${aws_iam_role.workers.name}"
}

resource "aws_iam_role_policy_attachment" "workers_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = "${aws_iam_role.workers.name}"
}

resource "aws_iam_role_policy_attachment" "workers_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = "${aws_iam_role.workers.name}"
}

# Installing controller
resource "null_resource" "controller_installation" {
  depends_on = ["module.eks","spotinst_ocean_aws.tf_ocean_cluster"]
  provisioner "local-exec" {
    command = <<EOT
      if [ ! -z ${var.SPOTINST_ACC} -a ! -z ${var.SPOTINST_TOKEN} ]; then
        echo "Downloading controller configMap"
        curl https://spotinst-public.s3.amazonaws.com/integrations/kubernetes/cluster-controller/templates/spotinst-kubernetes-controller-config-map.yaml -o configMap.yaml
        echo "Finished downloading controller configMap"
        sed -i -e "s@<TOKEN>@${var.SPOTINST_TOKEN}@g" configMap.yaml
        sed -i -e "s@<ACCOUNT_ID>@${var.SPOTINST_ACC}@g" configMap.yaml
        sed -i -e "s@<IDENTIFIER>@${var.CLUSTER_NAME}@g" configMap.yaml
        echo "Creating controller configMap in k8s"
        kubectl --kubeconfig=${module.eks.kubeconfig_filename} create -f configMap.yaml
        echo "Created controller configMap in k8s. creating controller resources"
        kubectl --kubeconfig=${module.eks.kubeconfig_filename} create -f https://s3.amazonaws.com/spotinst-public/integrations/kubernetes/cluster-controller/spotinst-kubernetes-cluster-controller-ga.yaml
        echo "Controller installed"
      else 
        echo "Account id and token has not been provided, therefore the spotinst-controller will not be created"
      fi
    EOT
  }  
}

