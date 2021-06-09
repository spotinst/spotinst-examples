# Ocean Terraform Module for Spot.io Ocean with EKS

A Terraform module to create an Ocean cluster and install Ocean Controller.

## Usage
Download module and store locally
```hcl
module "ocean_eks" {
  source = "./ocean_eks"

  # Spot.io Credentials
  spotinst_token              = ""
  spotinst_account            = ""

  # Configuration
  cluster_name                = local.cluster_name
  region                      = "us-west-2"
  subnet_ids                  = ["subnet-12345678","subnet-12345678"]
  vpc_id                      = "vpc-123456789"
  worker_instance_profile_arn = "arn:aws:iam::123456789:instance-profile/Spot-EKS-Workshop-Nodegroup"
  security_groups             = ["sg-123456789","sg-123456789"]
}
```

## Examples

- [Simple Installation](https://github.com/spotinst/spotinst-examples/blob/master/Terraform/Ocean/AWS/EKS/main.tf)

## Providers

| Name | Version |
|------|---------|
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | ~> 2.0 |

## Modules
* ocean_eks - Creates Ocean Cluster
* ocean-controller - Create and installs spot ocean controller pod [Doc](https://registry.terraform.io/modules/spotinst/ocean-controller/spotinst/latest)
* ocean_eks_launchspec - (Optional) Create additional custom launchspecs (VNG)

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