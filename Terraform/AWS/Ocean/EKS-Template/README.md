# Template for EKS and Ocean Integration with Terraform

This Terraform module creates an Amazon EKS cluster and integrates it with the Spot Ocean cluster to manage the underlying worker nodes. 

## Features

1. Creates an Amazon EKS cluster with an EKS-Managed Node Group
2. Installs the Spot Ocean Controller
3. Creates the Ocean Cluster
4. Creates a VNG for the Ocean Cluster

## Requirements

- Terraform v0.12.0 or newer
- AWS CLI configured and authenticated with the appropriate AWS account
- Spot API token and account ID

## Usage

1. Clone this Git repository.
2. Update the `variables.tf` file with your AWS and Spot credentials, cluster name, and other required configurations.
3. Run `terraform init` to initialize the Terraform providers and modules.
4. Run `terraform apply` to create the resources defined in the Terraform configuration.