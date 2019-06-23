
locals {
  device_name = "/dev/xvdc"
  master_name = "master-1"
  data_path = "/var/lib/elasticsearch"
  sleep_sec = 10
  logical_volume = "lv_elastic01"
  volume_group = "vg_elastic01"

  user_data = <<-EOS

#!/usr/bin/env bash

# Paramters
device="${local.device_name}"
data_path="${local.data_path}"
sleep_sec=${local.sleep_sec}
logical_volume="${local.logical_volume}"
volume_group="${local.volume_group}"
device_lv="/dev/$${volume_group}/$${logical_volume}"

function install_java
{
   echo "Install jdk"
   rpm_file_src="http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-8u131-linux-x64.rpm"
   rpm_file_dest="/tmp/jdk-8u131-linux-x64.rpm"
   wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" -O "$$rpm_file_dest" "$$rpm_file_src"
   rpm -Uvh "$$rpm_file_dest"
}

function install_es
{
    echo "Install elasticsearch"
    # Installing ELK
    wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.1.1-x86_64.rpm
    wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.1.1-x86_64.rpm.sha512
    rpm --install elasticsearch-7.1.1-x86_64.rpm

    echo "Install ec2 discovery"
    yes | sudo /usr/share/elasticsearch/bin/elasticsearch-plugin install discovery-ec2


   echo "Update elasticsearch config"
   cat > /etc/elasticsearch/elasticsearch.yml << 'EOF'
# ======================== Elasticsearch Configuration =========================
# ---------------------------------- Cluster -----------------------------------
# Use a descriptive name for your cluster:
cluster.name: ${var.ELK-CluserName}
# ------------------------------------ Node ------------------------------------
node.master: false
# ----------------------------------- Paths ------------------------------------
# Path to directory where to store the data (separate multiple locations by comma):
path.data: /var/lib/elasticsearch
# Path to log files:
path.logs: /var/log/elasticsearch
# ---------------------------------- Network -----------------------------------
# Set the bind address to a specific IP (IPv4 or IPv6):
network.host: ["_ec2:privateIpv4_","_local_"]
# --------------------------------- Discovery ----------------------------------
#
# EC2 Discovery
discovery.seed_providers: ec2
discovery.ec2.tag.${var.tagName}: ${var.tagValue}
# Master node Discovery
cluster.initial_master_nodes: ["master-1"]
# Setup the endpoint
discovery.ec2.endpoint: "ec2.${var.region}.amazonaws.com"
# Prevent the "split brain" by configuring the majority of nodes (total number of master-eligible nodes / 2 + 1):
discovery.zen.minimum_master_nodes: 2
EOF
   ## Update jvm Xmx/Xms according to inst. type
   #grep Xm /etc/elasticsearch/jvm.options
}

function handle_mounts
{
   echo "Wait until we have the EBS attached (new or reattached)"
   ls -l "$$device" > /dev/null
   while [ $? -ne 0 ]; do
       echo "Device $$device is still NOT available, sleeping..."
       sleep $$sleep_sec
       ls -l "$$device" > /dev/null
   done
   echo "Device $$device is available"
   echo "Check if the instance is new or recycled"
   lsblk "$$device" --output FSTYPE | grep LVM > /dev/null
   if [ $? -ne 0 ]; then
       echo "Device $$device is new, creating LVM & formatting"
       pvcreate "$$device"
       pvdisplay
       vgcreate vg_elastic01 "$$device"
       vgdisplay
       lvcreate -l 100%FREE -n "$$logical_volume" "$volume_group"
       lvdisplay
       mkfs -t ext4 $$device_lv
   else
       echo "Device $$device was reattached"
   fi
   echo "Add to entry to fstab"
   UUID=$(blkid $$device_lv -o value | head -1)
   echo "UUID=$$UUID $$data_path    ext4 _netdev 0 0" >> /etc/fstab
   echo "Make sure mount is available"
   mount -a > /dev/null
   while [ $? -ne 0 ]; do
       echo "Error mounting all filesystems from /etc/fstab, sleeping..."
       sleep 2;
       mount -a > /dev/null
   done
   chown -R elasticsearch:elasticsearch "$$data_path"
   echo "Mounted all filesystems from /etc/fstab, proceeding"
}

function start_apps
{
   echo "Start elasticsearch"
    # Start ELK
    systemctl daemon-reload
    systemctl enable elasticsearch
    systemctl start elasticsearch
}

function main
{
   ## Installations can be offloaded to AMI
   install_java
   install_es
   handle_mounts
   start_apps
}
main
                EOS

  user_data_master = <<-EOF

#!/usr/bin/env bash

# Paramters
device="${local.device_name}"
data_path="${local.data_path}"
sleep_sec=${local.sleep_sec}
logical_volume="${local.logical_volume}"
volume_group="${local.volume_group}"
device_lv="/dev/$${volume_group}/$${logical_volume}"


function install_java
{
   echo "Install jdk"
   rpm_file_src="http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-8u131-linux-x64.rpm"
   rpm_file_dest="/tmp/jdk-8u131-linux-x64.rpm"
   wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" -O "$$rpm_file_dest" "$$rpm_file_src"
   rpm -Uvh "$$rpm_file_dest"
}

function install_kibana
{
  # Setup kibana
  echo "Setup kibana"
  wget https://artifacts.elastic.co/downloads/kibana/kibana-7.1.1-x86_64.rpm
  rpm --install kibana-7.1.1-x86_64.rpm

  # Setup the server host
  sed -i -e "s/#server.host: \"localhost\"/server.host: 0.0.0.0/g" /etc/kibana/kibana.yml
}

function install_es
{
  echo "Install elasticsearch"

  # Installing ELK
  wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.1.1-x86_64.rpm
  wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.1.1-x86_64.rpm.sha512
  rpm --install elasticsearch-7.1.1-x86_64.rpm

  echo "Install ec2 discovery"
  yes | sudo /usr/share/elasticsearch/bin/elasticsearch-plugin install discovery-ec2


  echo "Update elasticsearch config"

  cat > /etc/elasticsearch/elasticsearch.yml << 'EOF'
# ======================== Elasticsearch Configuration =========================
# ---------------------------------- Cluster -----------------------------------
# Use a descriptive name for your cluster:
cluster.name: ${var.ELK-CluserName}
# ------------------------------------ Node ------------------------------------
node.name: ${local.master_name}
node.master: true
node.data: false
node.ingest: false
search.remote.connect: false
# ----------------------------------- Paths ------------------------------------
# Path to directory where to store the data (separate multiple locations by comma):
path.data: /var/lib/elasticsearch
# Path to log files:
path.logs: /var/log/elasticsearch
# ---------------------------------- Network -----------------------------------
# Set the bind address to a specific IP (IPv4 or IPv6):
network.host: ["_ec2:privateIpv4_","_local_"]
# --------------------------------- Discovery ----------------------------------
#
# EC2 Discovery
discovery.seed_providers: ec2
discovery.ec2.tag.${var.tagName}: ${var.tagValue}
# Master node Discovery
cluster.initial_master_nodes: ["master-1"]
# Setup the endpoint
discovery.ec2.endpoint: "ec2.${var.region}.amazonaws.com"
# Prevent the "split brain" by configuring the majority of nodes (total number of master-eligible nodes / 2 + 1):
discovery.zen.minimum_master_nodes: 2
EOF
  ## Update jvm Xmx/Xms according to inst. type
  #grep Xm /etc/elasticsearch/jvm.options

  
}

function install_cerebro
{
   echo "Install Docker"
   kernel_installed=$(uname -r)
   if [[ "$$kernel_installed" =~ .*amzn.* ]]; then
       yum install docker-17.06.2ce-1.102.amzn2.x86_64 -y
   else
       echo "Amazon Linux is required, not installing docker/cerebro"
   fi
}

function handle_mounts
{
   echo "Wait until we have the EBS attached (new or reattached)"
   ls -l "$$device" > /dev/null
   while [ $? -ne 0 ]; do
       echo "Device $device is still NOT available, sleeping..."
       sleep $$sleep_sec
       ls -l "$$device" > /dev/null
   done
   echo "Device $$device is available"
   echo "Check if the instance is new or recycled"
   lsblk "$$device" --output FSTYPE | grep LVM > /dev/null
   if [ $? -ne 0 ]; then
       echo "Device $$device is new, creating LVM & formatting"
       pvcreate "$$device"
       pvdisplay
       vgcreate vg_elastic01 "$$device"
       vgdisplay
       lvcreate -l 100%FREE -n "$$logical_volume" "$volume_group"
       lvdisplay
       mkfs -t ext4 $$device_lv
   else
       echo "Device $$device was reattached"
   fi
   echo "Add to entry to fstab"
   UUID=$(blkid $$device_lv -o value | head -1)
   echo "UUID=$$UUID $$data_path    ext4 _netdev 0 0" >> /etc/fstab
   echo "Make sure mount is available"
   mount -a > /dev/null
   while [ $? -ne 0 ]; do
       echo "Error mounting all filesystems from /etc/fstab, sleeping..."
       sleep 2;
       mount -a > /dev/null
   done
   chown -R elasticsearch:elasticsearch "$$data_path"
   echo "Mounted all filesystems from /etc/fstab, proceeding"
}

function start_apps
{
  echo "Start elasticsearch"
  # Start ELK
  systemctl daemon-reload
  systemctl enable elasticsearch
  systemctl start elasticsearch

  echo "Start Kibana"
  # Start Kibana
  systemctl enable kibana
  systemctl start kibana

  echo "Start cerebro"
  systemctl start docker
  docker run -p 9000:9000 lmenezes/cerebro &

}
function main
{
   ## Installations can be offloaded to AMI
   install_java
   install_es
   install_cerebro
   install_kibana

   handle_mounts
   start_apps
}
main
                            EOF
}


########################################
#### AWS Settings             ##########
########################################
data "aws_ami" "amazon-linux-2" {
 most_recent = true
 owners      = ["amazon"]
 name_regex = "amzn2-ami-hvm-2.0.*-x86_64-gp2$"

  filter {
    name = "state"
    values = ["available"]
  }
}

resource "aws_iam_role_policy" "ES_discovery_policy" {
  name = "ES_Discovery_policy"
  role = "${aws_iam_role.ES_discovery.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:Describe*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
              EOF
}

resource "aws_iam_role" "ES_discovery" {
  name = "ES_discovery"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
                      EOF
}

resource "aws_iam_instance_profile" "ES_discovery_instance_profile" {
  name = "ES_discovery_instance_profile"
  role = "${aws_iam_role.ES_discovery.name}"
}

########################################
#### Master Node              ##########
########################################
module "ec2_cluster" {
  source                        = "terraform-aws-modules/ec2-instance/aws"
  version                       = "1.21.0"
  name                          = "es-master"
  instance_count                = 1

  ami                           = "${data.aws_ami.amazon-linux-2.id}"
  instance_type                 = "${var.instance_types_ondemand}"
  key_name                      = "${var.keypair}"
  monitoring                    = false
  vpc_security_group_ids        = ["${var.security_groups}"]
  subnet_id                     = "${var.master_subnet}"
  associate_public_ip_address	= true
  iam_instance_profile          = "${aws_iam_instance_profile.ES_discovery_instance_profile.name}"

  user_data              = "${local.user_data_master}"

 
  root_block_device      = [
    {
          volume_type      = "gp2"
          volume_size      = 10
    }
  ]
  ebs_block_device = [
    {
      device_name = "${local.device_name}"
      volume_type = "gp2"
      volume_size = 10
    }
  ] 
  tags = {
    "${var.tagName}" = "${var.tagValue}"
  }
}

########################################
#### Data Nodes               ##########
########################################
resource "spotinst_elastigroup_aws" "elasticsearch-node-1-elastigroup" {

  name        = "elasticsearch-node-1"
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
  iam_instance_profile  = "${aws_iam_instance_profile.ES_discovery_instance_profile.name}"

  persist_block_devices = true
  block_devices_mode    = "reattach"

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

  ebs_block_device = [
    {
      device_name           = "${local.device_name}"
      delete_on_termination = true
      volume_type           = "gp2"
      volume_size           = 10
    }
  ]

  tags = [
  {
    key   = "Name"
    value = "Elasticsearch-Node-1"
  }
 ]

  lifecycle {
    ignore_changes = [
      "desired_capacity",
    ]
  }
}

resource "spotinst_elastigroup_aws" "elasticsearch-node-2-elastigroup" {

  name        = "elasticsearch-node-2"
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
  iam_instance_profile  = "${aws_iam_instance_profile.ES_discovery_instance_profile.name}"

  persist_block_devices = true
  block_devices_mode    = "reattach"

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

  ebs_block_device = [
    {
      device_name           = "${local.device_name}"
      delete_on_termination = true
      volume_type           = "gp2"
      volume_size           = 10
    }
  ]

  tags = [
  {
    key   = "Name"
    value = "Elasticsearch-Node-2"
  }
 ]

  lifecycle {
    ignore_changes = [
      "desired_capacity",
    ]
  }
}

resource "spotinst_elastigroup_aws" "elasticsearch-node-3-elastigroup" {

  name        = "elasticsearch-node-3"
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
  iam_instance_profile  = "${aws_iam_instance_profile.ES_discovery_instance_profile.name}"

  persist_block_devices = true
  block_devices_mode    = "reattach"

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

  ebs_block_device = [
    {
      device_name           = "${local.device_name}"
      delete_on_termination = true
      volume_type           = "gp2"
      volume_size           = 10
    }
  ]

  tags = [
  {
    key   = "Name"
    value = "Elasticsearch-Node-3"
  }
 ]

  lifecycle {
    ignore_changes = [
      "desired_capacity",
    ]
  }
}
