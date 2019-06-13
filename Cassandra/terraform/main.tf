
locals {
  user_data = <<-EOF
    #!/bin/bash

    # Installs Cassandra
    yum update -y
    yum-config-manager --add-repo http://rpm.datastax.com/community
    mkdir ~/.keys
    wget http://rpm.datastax.com/rpm/repo_key
    cd .keys
    wget http://rpm.datastax.com/rpm/repo_key
    rpm --import repo_key
    yum update && yum upgrade -y
    yum install java dsc30 cassandra30-tools ntp -y

    # Set Cassandra on startup
    systemctl enable cassandra

    # Set host ip
    sed -i -e "s/localhost/$$(hostname -I | xargs)/g" /etc/cassandra/conf/cassandra.yaml

    # Setting the clusers seeds
    sed -i 's/- seeds: "127.0.0.1"/- seeds: "${var.Cassndrd-Node-1-IP},${var.Cassndrd-Node-2-IP},${var.Cassndrd-Node-3-IP}"/g' /etc/cassandra/conf/cassandra.yaml

    # Start Cassandra
    systemctl start cassandra
            EOF
}


# Getting the lastest linux 2 image
data "aws_ami" "amazon-linux-2" {
 most_recent = true
 owners      = ["amazon"]
 name_regex = "amzn2-ami-hvm-2.0.*-x86_64-gp2$"

  filter {
    name = "state"
    values = ["available"]
  }
}

# Create an Elastigroup
resource "spotinst_elastigroup_aws" "Cassandra-node-1-elastigroup" {

  name        = "Cassandra-node-1"
  description = "created by Terraform"
  product     = "Linux/UNIX"

  max_size          = 1
  min_size          = 1
  desired_capacity  = 1

  region      = "${var.region}"
  subnet_ids  = "${var.subnet_ids}"

  image_id              = "${data.aws_ami.amazon-linux-2.id}"
  key_name              = "${var.keypair}"
  security_groups       = ["${var.security_groups}"]

  persist_root_device   = true
  persist_private_ip    = true
  private_ips = ["${var.Cassndrd-Node-1-IP}"]

  user_data              = "${local.user_data}"
  enable_monitoring     = false
  ebs_optimized         = true
  placement_tenancy     = "default"
  spot_percentage       = 100

  instance_types_ondemand       = "${var.instance_types_ondemand}"
  instance_types_spot           = "${var.instance_types_spot}"
  instance_types_preferred_spot = "${var.instance_types_preferred_spot}"

  orientation           = "balanced"
  fallback_to_ondemand  = true

  tags = [
  {
    key   = "Name"
    value = "Cassandra-Node-1"
  }
 ]

  lifecycle {
    ignore_changes = [
      "desired_capacity",
    ]
  }
}


resource "spotinst_elastigroup_aws" "Cassandra-node-2-elastigroup" {

  name        = "Cassandra-node-2"
  description = "created by Terraform"
  product     = "Linux/UNIX"

  max_size          = 1
  min_size          = 1
  desired_capacity  = 1

  region      = "${var.region}"
  subnet_ids  = "${var.subnet_ids}"

  image_id              = "${data.aws_ami.amazon-linux-2.id}"
  key_name              = "${var.keypair}"
  security_groups       = ["${var.security_groups}"]

  persist_root_device   = true
  persist_private_ip    = true
  private_ips = ["${var.Cassndrd-Node-2-IP}"]

  user_data              = "${local.user_data}"
  enable_monitoring     = false
  ebs_optimized         = true
  placement_tenancy     = "default"
  spot_percentage       = 100

  instance_types_ondemand       = "${var.instance_types_ondemand}"
  instance_types_spot           = "${var.instance_types_spot}"
  instance_types_preferred_spot = "${var.instance_types_preferred_spot}"

  orientation           = "balanced"
  fallback_to_ondemand  = true

  tags = [
  {
    key   = "Name"
    value = "Cassandra-Node-2"
  }
 ]

  lifecycle {
    ignore_changes = [
      "desired_capacity",
    ]
  }
}


resource "spotinst_elastigroup_aws" "Cassandra-node-3-elastigroup" {

  name        = "Cassandra-node-3"
  description = "created by Terraform"
  product     = "Linux/UNIX"

  max_size          = 1
  min_size          = 1
  desired_capacity  = 1

  region      = "${var.region}"
  subnet_ids  = "${var.subnet_ids}"

  image_id              = "${data.aws_ami.amazon-linux-2.id}"
  key_name              = "${var.keypair}"
  security_groups       = ["${var.security_groups}"]

  persist_root_device   = true
  persist_private_ip    = true
  private_ips = ["${var.Cassndrd-Node-3-IP}"]

  user_data              = "${local.user_data}"
  enable_monitoring     = false
  ebs_optimized         = true
  placement_tenancy     = "default"
  spot_percentage       = 100

  instance_types_ondemand       = "${var.instance_types_ondemand}"
  instance_types_spot           = "${var.instance_types_spot}"
  instance_types_preferred_spot = "${var.instance_types_preferred_spot}"

  orientation           = "balanced"
  fallback_to_ondemand  = true

  tags = [
  {
    key   = "Name"
    value = "Cassandra-Node-3"
  }
 ]

  lifecycle {
    ignore_changes = [
      "desired_capacity",
    ]
  }
}
