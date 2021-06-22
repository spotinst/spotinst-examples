# ECS on Spot.io

# Spot Ocean ECS Terraform Module

## Prerequisites

* Have a ECS cluster created
* Spot Account and API Token

## Usage
```hcl
module "ocean_ecs" {
  source = "../ocean_ecs"

  spot_token                      = "12345678901234567890"
  spot_account                    = "act-123456789"

  cluster_name                    = "ECS-Workshop"
  region                          = "us-west-2"
  subnet_ids                      = ["subnet-123456789,subnet-123456789"]
  security_group_ids              = ["sg-123456789"]
  image_id                        = "ami-123456789"
  iam_instance_profile            = "arn:aws:iam::123456789:instance-profile/ecsInstanceRole"

  tags = [{key = "CreatedBy", value = "terraform"},{key = "Env", value = "Dev"}]
}
```

## Resources
This module creates and manages the following resources:
- spotinst_ocean_ecs

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| terraform | >=0.13.0 |
| spotinst | >= 1.45.0 |

## Providers

| Name | Version |
|------|---------|
| spotinst | >= 1.45.0 |

## Inputs

| Name | Type | Default | Required |
|------------|----------|---------------|:-----:|
spot\_token  |string    |               |Yes
spot\_account|string    |               |Yes
cluster\_name|string    |               |Yes
region       |string           |               |Yes
max\_size    |number|1000|No
min\_size   |number|0|No
desired\_capacity|number|null|No
subnet\_ids     |list(string)   |       |Yes
tags|'list(object({key=string, value=string})'|null|No
whitelist|list(string)| |No
user\_data|string|  |No
image\_id|string|   |Yes
security\_group\_ids|list(string)|  |Yes
key\_pair|string|null|No
iam\_instance\_profile|string|  |Yes
associate\_public\_ip\_address|bool|null|No
utilize\_reserverd\_instances|bool|TRUE|No
ddraining\_timeout|number|120|No
monitoring|bool|FALSE|No
ebs\_optimized|bool|TRUE|No
perform\_at|string|'always'|No
optimize\_time\_window|list(string)|null|No
should\_optimize\_ecs\_ami|bool|TRUE|No
autoscaler\_is\_enabled|bool|TRUE|No
autoscaler\_is\_auto\_config|bool|TRUE|No
cooldown|number|null|No
cpu\_per\_unit|number|0|No
memory\_per\_unit|number|0|No
num\_of\_units|number|0|No
max\_scale\_down\_percentage|number|10|No
max\_vcpu|number|null|No
max\_memory\_gib|number|null|No
should\_roll|bool|TRUE|No
batch\_size\_percentage|number|20|No
shutdown\_is\_enabled|bool|FALSE|No
shutdown\_time\_windows|list(string)|'[''Sat:20:00-Sun:04:00'',''Sun:20:00-Mon:04:00'']'|No
taskscheduling\_is\_enabled|bool|FALSE|No
cron\_expression|string|    |No
task\_type|string|clusterRoll|No
device\_name|string|    |No
delete\_on\_termination|string|null|No
encrypted|bool|null|No
iops|bool|null|No
kms\_key\_id|string|null|No
snapshot\_id|string|null|No
volume\_type|string|null|No
volume\_size|number|null|No
throughput|number|null|No
base\_size|number|30|No
resource|string|CPU|No
size\_per\_resource\_unit|number|20|No
no\_device|string|null|No


## Outputs

| Name | Description |
|------|-------------|
| ocean\_cluster\_id | The ID of the Ocean cluster |

## Documentation

If you're new to [Spot](https://spot.io/) and want to get started, please checkout our [Getting Started](https://docs.spot.io/connect-your-cloud-provider/) guide, available on the [Spot Documentation](https://docs.spot.io/) website.

## Getting Help

We use GitHub issues for tracking bugs and feature requests. Please use these community resources for getting help:

- Ask a question on [Stack Overflow](https://stackoverflow.com/) and tag it with [terraform-spotinst](https://stackoverflow.com/questions/tagged/terraform-spotinst/).
- Join our [Spot](https://spot.io/) community on [Slack](http://slack.spot.io/).
- Open an issue.

## Community

- [Slack](http://slack.spot.io/)
- [Twitter](https://twitter.com/spot_hq/)

## Contributing

Please see the [contribution guidelines](CONTRIBUTING.md).

## License

Code is licensed under the [Apache License 2.0](LICENSE).