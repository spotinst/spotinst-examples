# Terraform GCP Examples for Spot.io

## Introduction
Example Terraform for Spot.io

## Examples
* spot-connect-gcp

# spot-connect-gcp
The module will aid in automatically connecting your GCP project to Spot via terraform. Please ensure you have a Spot Organization Admin API token. This is required to be added as an environment variable stored in SPOTINST_TOKEN. This will also leverage a python script to create the Spot account. Please ensure you have Python 3 installed. 

This terraform module will do the following:

On Apply:
* Create GCP Service Account
* Create GCP Service Account Key
* Create GCP Project Role
* Create Spot Account within Spot Organization
* Assign Project Role to Service Account
* Provide GCP Service Account Key to newly created Spot Account

On Destroy:
Remove all above resources including deleting the Spot Account
