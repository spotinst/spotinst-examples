# ECS on Spot.io

# Spot Ocean ECS Terraform Module

## Prerequisites

* Have a ECS cluster created
* Spot Account and API Token

## Usage
```hcl
module "spot_ocean_ecs" {
  source = "../spot_ocean_ecs"

  # Credentials.
  spotinst_token   = var.spotinst_token
  spotinst_account = var.spotinst_account
}
```

## Resources
This module creates and manages the following resources:
- spotinst_ocean_ecs

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| terraform | >=0.12.15 |
| spotinst | >= 1.27.0 |

## Providers

| Name | Version |
|------|---------|
| spotinst | >= 1.27.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| ami\_id | The image ID for the ECS worker nodes | `string` | `null` | no |

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