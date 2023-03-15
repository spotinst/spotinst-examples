# EKS and Ocean Cluster Terraform Module

This Terraform module creates an Amazon EKS cluster and integrates it with the Spot Ocean cluster to manage the underlying worker nodes. The module also installs the required providers and Kubernetes addons, and configures the IAM roles and policies required for the EKS nodes.

## Features

1. Creates an Amazon EKS cluster
2. Creates IAM roles and policies for EKS worker nodes
3. Integrates the EKS cluster with Spot Ocean
4. Installs the Spot Ocean controller
5. Configures kubectl, Helm, and other providers
6. Installs Kubernetes addons

## Requirements

- Terraform v0.12.0 or newer
- AWS CLI configured and authenticated with the appropriate AWS account
- Spot API token and account ID

## Usage

1. Clone this Git repository.
2. Update the `variables.tf` file with your AWS and Spot credentials, cluster name, and other required configurations.
3. Run `terraform init` to initialize the Terraform providers and modules.
4. Run `terraform apply` to create the resources defined in the Terraform configuration.

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| `spotinst_token` | Spot API token | string | Yes |
| `spotinst_account` | Spot account ID | string | Yes |
| `cluster_name` | EKS and Ocean cluster name | string | Yes |
| `cluster_version` | Kubernetes version for the EKS cluster | string | Yes |
| `aws_region` | AWS region where the resources will be created | string | Yes |
| `vpc_id` | AWS VPC ID where the resources will be created | string | Yes |
| `private_subnets` | List of private subnet IDs within the VPC | list | Yes |

## Outputs

| Name | Description |
|------|-------------|
| `configure_kubectl` | Command to configure kubectl for the created EKS cluster |

## Spot Ocean

Spot Ocean is an intelligent Kubernetes infrastructure management platform that optimizes your infrastructure for cost, performance, and availability. It manages worker nodes and adjusts the underlying infrastructure based on container requirements, while ensuring that your workloads are running on the most cost-effective instances.

This Terraform module integrates the EKS cluster with Spot Ocean by creating an Ocean cluster, installing the Ocean controller, and configuring the required settings. The module also assigns tags to the Ocean cluster and manages the worker instance profiles and security groups.

To use the Spot Ocean integration, ensure that you have provided the correct Spot API token and account ID in the `variables.tf` file. Once the Terraform module has been applied, the Ocean controller will be installed and configured to manage your EKS worker nodes.
