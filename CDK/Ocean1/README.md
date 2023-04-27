# AWS CDK Ocean Stack

This code defines an AWS CDK stack that provisions an Amazon EKS cluster using Spot by NetApp Ocean as the underlying infrastructure for worker nodes. It sets up the required IAM roles, security groups, and instance profiles for the worker nodes, and installs the Spotinst Ocean Controller on the EKS cluster.

## Requirements

- Python 3.7 or higher
- AWS CDK CLI
- An active Spotinst account with a valid API token
- AWS account with the necessary permissions

## How to use

1. Set up a Python virtual environment:

```
python -m venv .env
source .env/bin/activate # On Linux/macOS
```

2. Install the required dependencies:

```
pip install -r requirements.txt
```

3. Deploy the stack:

```
cdk deploy
```

## Code Overview

The `CdkOceanStack` class extends the AWS CDK `Stack` class and sets up the necessary resources:

- Imports the required modules and libraries.
- Defines the necessary variables such as the Spotinst token, account ID, cluster name, region, VPC ID, subnet IDs, and image ID.
- Retrieves the existing VPC attributes.
- Provisions the EKS cluster using the specified version, name, and VPC.
- Retrieves the EKS cluster security group for use in the VNG.
- Creates the necessary IAM roles and policies for the worker nodes.
- Adds the created IAM roles to the EKS cluster's AWS authentication config map.
- Creates the instance profile for the VNG.
- Creates the Spotinst Ocean cluster as a custom resource.
- Installs the Spotinst Ocean Controller on the EKS cluster using a Helm chart.

## Additional Notes

Remember to replace the necessary variables (e.g., `token_id`, `account_id`, `cluster_name`, `region`, `vpc_id`, `subnetIds`, and `imageId`) with your own values before deploying the stack.
