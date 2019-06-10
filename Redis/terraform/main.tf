
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
resource "spotinst_elastigroup_aws" "redis-slaves-elastigroup" {

  name        = "redis-slaves-elastigroup"
  description = "created by Terraform"
  product     = "Linux/UNIX"

  max_size          = 3
  min_size          = 3
  desired_capacity  = 3

  region      = "${var.region}"
  subnet_ids  = "${var.subnet_ids}"

  image_id              = "${data.aws_ami.amazon-linux-2.id}"
  key_name              = "${var.keypair}"
  security_groups       = ["${var.security_groups}"]
  persist_root_device   = true
  persist_private_ip    = true 
    user_data              = <<-EOF
                            #!bin/bash

                            sudo yum -y update
                            sudo yum -y install gcc gcc-c++ make jemalloc tcl
                            
                            sudo mkdir /etc/redis /var/lib/redis
                            
                            cd /usr/local/src
                            sudo wget "http://download.redis.io/redis-stable.tar.gz"
                            sudo tar vxzf "redis-stable.tar.gz"
                            sudo rm -f "redis-stable.tar.gz"
                            cd "redis-stable"
                            sudo make distclean
                            sudo make
                            sudo make install

                            sudo sed -e "s/^bind 127.0.0.1$/bind $$(hostname -I | xargs)/" -e "s/^# cluster-enabled yes$/cluster-enabled yes/" -e "s/^# cluster-config-file nodes-6379.conf$/cluster-config-file nodes-6379.conf/" -e "s/^# cluster-node-timeout 15000$/cluster-node-timeout 15000/"  -e "s/^daemonize no$/daemonize yes/" -e "s/^dir \.\//dir \/var\/lib\/redis\//" -e "s/^loglevel verbose$/loglevel notice/" -e "s/^logfile \"\"$/logfile \/var\/log\/redis.log/" redis.conf | sudo tee ./redisNew.conf

                            redis-server ./redisNew.conf
                            redis-cli --cluster add-node $$(hostname -I | xargs):6379 ${var.master_ip}:6379 --cluster-slave
                           EOF
  enable_monitoring     = false
  ebs_optimized         = true
  placement_tenancy     = "default"
  spot_percentage       = 100
  target_group_arns     = "${var.target_group_arns}"

  instance_types_ondemand       = "r4.large"
  instance_types_spot           = ["r4.xlarge", "r4.2xlarge"]
  instance_types_preferred_spot = ["r4.xlarge"]

  orientation           = "balanced"
  fallback_to_ondemand  = true
  
  tags = [
  {
     key   = "Name"
     value = "Redis"
  }
 ]

  lifecycle {
    ignore_changes = [
      "desired_capacity",
    ]
  }
}