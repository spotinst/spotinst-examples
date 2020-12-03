# ECS on Spot.io

# Spot Ocean ECS Terraform Module

A Terraform module to create ECS Ocean Cluster. You can update the ```terraform.tfvars``` with specific information and run terraform apply to create + Manage the Ocean ECS Cluster
https://registry.terraform.io/providers/spotinst/spotinst/latest/docs/resources/ocean_ecs

## Table of Contents

- [Usage](#usage)
- [Prerequisites](#prerequisites)
- [Resources](#resources)
- [Requirements](#requirements)
- [Providers](#providers)
- [Inputs](#inputs)
- [Outputs](#outputs)
- [Documentation](#documentation)
- [Getting Help](#getting-help)
- [Community](#community)
- [Contributing](#contributing)
- [License](#license)

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
| aws | >= 3.3.0 |
| spotinst | >= 1.27.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 3.3.0 |
| spotinst | >= 1.27.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| ami\_id | The image ID for the ECS worker nodes | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| ocean\_cluster\_id | The ID of the Ocean cluster |
| ocean\_controller\_id | The ID of the Ocean controller |

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