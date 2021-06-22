terraform {
    required_providers {
        spotinst = {
            source = "spotinst/spotinst"
        }
    }
}

# Configure the Spotinst provider
provider "spotinst" {
    token                                = var.spot_token
    account                              = var.spot_account
}

#Create Spot.io Ocean ECS Cluster
resource "spotinst_ocean_ecs" "example" {

    name                                = var.cluster_name
    cluster_name                        = var.cluster_name
    region                              = var.region

    min_size                            = var.min_size
    max_size                            = var.max_size
    desired_capacity                    = var.desired_capacity

    subnet_ids                          = var.subnet_ids

    dynamic tags {
        for_each = var.tags == null ? [] : var.tags
        content {
            key = tags.value["key"]
            value = tags.value["value"]
        }
    }
    whitelist 						    = var.whitelist
    user_data                           = <<-EOF
    #!/bin/bash
    echo "ECS_CLUSTER=${var.cluster_name}" >> /etc/ecs/ecs.config
    EOF

    image_id                            = var.image_id
    security_group_ids                  = var.security_group_ids
    key_pair                            = var.key_pair
    iam_instance_profile                = var.iam_instance_profile
    associate_public_ip_address         = var.associate_public_ip_address
    monitoring                          = var.monitoring

    ## Strategy ##
    utilize_reserved_instances          = var.utilize_reserved_instances
    draining_timeout                    = var.draining_timeout

    ebs_optimized                       = var.ebs_optimized

    optimize_images {
        perform_at = var.perform_at
        time_windows = var.optimize_time_windows
        should_optimize_ecs_ami = var.should_optimize_ecs_ami
    }

    ## Autoscaler Settings ##
    autoscaler {
        is_enabled                      = var.autoscaler_is_enabled
        is_auto_config                  = var.autoscaler_is_auto_config
        cooldown                        = var.cooldown
        headroom {
            cpu_per_unit                = var.cpu_per_unit
            memory_per_unit             = var.memory_per_unit
            num_of_units                = var.num_of_units
        }
        down {
            max_scale_down_percentage   = var.max_scale_down_percentage
        }
        resource_limits {
            max_vcpu                    = var.max_vcpu
            max_memory_gib              = var.max_memory_gib
        }
    }

    ## Update Policy ##
    update_policy {
        should_roll                     = var.should_roll
        roll_config {
            batch_size_percentage       = var.batch_size_percentage
        }
    }


    ## Scheduled Task ##
    scheduled_task {
        shutdown_hours {
            is_enabled                  = var.shutdown_is_enabled
            time_windows                = var.shutdown_time_windows
        }
        tasks {
            is_enabled                  = var.taskscheduling_is_enabled
            cron_expression             = var.cron_expression
            task_type                   = var.task_type
        }
    }

    ## Block Device Mappings ##
    block_device_mappings {
        device_name                     = var.device_name
        ebs {
            delete_on_termination       = var.delete_on_termination
            encrypted                   = var.encrypted
            iops                        = var.iops
            kms_key_id                  = var.kms_key_id
            snapshot_id                 = var.snapshot_id
            volume_type                 = var.volume_type
            volume_size                 = var.volume_size
            throughput                  = var.throughput
            dynamic_volume_size {
                base_size               = var.base_size
                resource                = var.resource
                size_per_resource_unit  = var.size_per_resource_unit
            }
        }
    }
}
