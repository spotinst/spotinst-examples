# Configure the Spotinst provider
provider "spotinst" {
   token   = var.spot_token
   account = var.spot_account
}

#Create Spot.io Ocean ECS Cluster
resource "spotinst_ocean_ecs" "example" {
    region                          = var.region
    name                            = var.cluster_name
    cluster_name                    = var.cluster_name

    min_size                        = "0"
    max_size                        = "100"
    desired_capacity                = "0" 

    subnet_ids                      = var.subnet_ids
    security_group_ids              = var.security_group_ids
    image_id                        = var.image_id
    iam_instance_profile            = var.iam_instance_profile

    key_pair                        = var.key
    whitelist 						= [
        "a1.4xlarge","a1.2xlarge","a1.medium","a1.xlarge","a1.large","a1.metal","c5.large","c5.2xlarge","c5.24xlarge","c5.metal","c5.18xlarge","c5.4xlarge","c5.9xlarge","c5.xlarge","c5.12xlarge","c5d.4xlarge","c5d.large","c5d.18xlarge","c5d.2xlarge","c5d.9xlarge","c5d.xlarge","c5d.12xlarge","c5d.24xlarge","c5d.metal","m5.24xlarge","m5.12xlarge","m5.2xlarge","m5.16xlarge","m5.4xlarge","m5.xlarge","m5.large","m5.8xlarge","m5.metal","m5a.4xlarge","m5a.24xlarge","m5a.large","m5a.xlarge","m5a.8xlarge","m5a.2xlarge","m5a.12xlarge","m5a.16xlarge","m5ad.xlarge","m5ad.large","m5ad.24xlarge","m5ad.12xlarge","m5ad.2xlarge","m5ad.4xlarge","m5d.4xlarge","m5d.large","m5d.12xlarge","m5d.8xlarge","m5d.2xlarge","m5d.16xlarge","m5d.24xlarge","m5d.xlarge","m5d.metal","p3.2xlarge","p3.8xlarge","p3.16xlarge","r5.metal","r5.xlarge","r5.8xlarge","r5.16xlarge","r5.12xlarge","r5.large","r5.24xlarge","r5.4xlarge","r5.2xlarge","r5a.4xlarge","r5a.2xlarge","r5a.24xlarge","r5a.12xlarge","r5a.16xlarge","r5a.8xlarge","r5a.xlarge","r5a.large","r5ad.12xlarge","r5ad.xlarge","r5ad.large","r5ad.2xlarge","r5ad.24xlarge","r5ad.4xlarge","r5d.4xlarge","r5d.8xlarge","r5d.12xlarge","r5d.2xlarge","r5d.16xlarge","r5d.24xlarge","r5d.large","r5d.metal","r5d.xlarge"]

    user_data                       = <<-EOF
    #!/bin/bash
    echo "ECS_CLUSTER=${var.cluster_name}" >> /etc/ecs/ecs.config        
    EOF

    associate_public_ip_address     = var.public_ip
    utilize_reserved_instances      = var.utilize_ri
    draining_timeout                = var.draining_timeout
    monitoring                      = var.monitoring
    ebs_optimized                   = var.optimized

    tags{
        key = "ApplicationId"
        value =  "12345"
    }
    tags{
        key =  "ApplicationName"
        value =  "Example"
    }
    tags{
        key =  "Name"
        value =  var.cluster_name
    }

    autoscaler {
        is_enabled                  = var.autoscaler_enabled
        is_auto_config              = var.autoscaler_auto
        headroom {
            cpu_per_unit            = var.headroom_cpu
            memory_per_unit         = var.headroom_memory
            num_of_units            = var.headroom_num_unit
        }
        down {
            max_scale_down_percentage   = var.scale_down_percentage
        }
    }

    update_policy {
        should_roll                 = var.update_roll
        roll_config {
            batch_size_percentage   = var.batch_percentage
        }
    }

}
