# Terraform GCP Examples for Spot.io

## Introduction
Example Terraform for Spot.io

## Examples
* spot-connect-aws

#spot-connect-gcp
The module will aid in automatically connecting your AWS Account to Spot via terraform. Please ensure you have a Spot Organization Admin API token. This is required to be added as an environment variable stored in SPOTINST_TOKEN. This will also leverage a python script to create the Spot account. Please ensure you have Python 3 installed. 

This terraform module will do the following:

On Apply:
* Create AWS IAM Policy 
* Create AWS IAM Role
* Create Spot Account within current Spot Organization
* Assign Policy to IAM Role
* Provide IAM Role to newly created Spot Account

On Destroy:
Remove all above resources including deleting the Spot Account