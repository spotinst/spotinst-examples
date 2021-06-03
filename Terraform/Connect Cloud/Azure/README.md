# Terraform Azure example for Spot.io

## Introduction
A Terraform module to connect an Azure Subscription to Spot.io

## Details
The module will aid in automatically connecting your Azure Subscription to Spot via terraform. Permissions will be managed by Azure Active Directory with a custom role that will be assigned to the Application. The Terraform module will leverage Spot APIs called via a script to complete the connection to the Spot platform. 

### Pre-Reqs
* Spot Organization Admin API token. This is required to be added as an environment variable stored in ```SPOTINST_TOKEN```.
* Python 3 installed
* Subscription ID
* Azure Active Directory ID

### Apply
The terraform module will do the following:

On Apply:
* Create an App Registration
* Create an App Secret
* Create a Custom Role
* Create a Service Principal 
* Assign Role to Application on Subscription
* Create New Spot Account using the subscription display name
* Provide and link newly created application credentials to Spot account. 

Prints out the following:
* Spot Account ID
