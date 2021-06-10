# Ocean Terraform Module for Spot.io Ocean with GKE

A Terraform module to create an Ocean cluster and install Ocean Controller.

## Usage
Download module and store locally
```hcl
module "ocean_gke" {
  source = "./ocean_gke"

  # Spot Credentials
  spot_token = local.spot_token
  spot_account = local.spot_account

  project = local.project
  # GKE information
  cluster_name = local.cluster_name
  location = local.location
}
```


## Providers

| Name | Version |
|------|---------|
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | ~> 2.0 |

## Modules
* ocean_gke - Creates Ocean Cluster
* ocean_controller - Create and installs spot ocean controller pod [Doc](https://registry.terraform.io/modules/spotinst/ocean-controller/spotinst/latest)
* ocean_gke_launchspec - (Optional) Create additional custom launchspecs (VNG)
* ocean_gke_launchspec_import - (Optional) Dynamically create launchspec (VNG) for every node pool in GKE

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