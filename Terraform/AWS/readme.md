# Terraform AWS Examples for Spot.io

## Introduction
Example Terraform for Spot.io

## Details
The module will aid in automatically connecting your AWS Account to Spot via terraform.  This will also leverage a python script to call the Spot.io APIs to create a Spot account within your Spot Organization and add the ARN of the created role. 

### Pre-Reqs
* Spot Organization Admin API token. This is required to be added as an environment variable stored in ```SPOTINST_TOKEN```.
* Python 3 installed

### Run
This terraform module will do the following:

On Apply:
* Create AWS IAM Policy 
* Create AWS IAM Role
* Create Spot Account within current Spot Organization
* Assign Policy to IAM Role
* Provide IAM Role to newly created Spot Account

On Destroy:
Remove all above resources including deleting the Spot Account
