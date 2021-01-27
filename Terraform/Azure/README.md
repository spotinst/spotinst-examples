# Terraform Azure example for Spot.io

## Introduction
Example Terraform to connect Azure Subscription to Spot.io

## Details
The module will aid in automatically connecting your Azure Subscription to Spot via terraform. Permissions will be managed by Azure Active Directory with a custom role that will be assigned to the Application. 

### Pre-Reqs
* Subscription ID
* Azure Active Directory ID

### Apply
This terraform module will do the following:

On Apply:
* Create App Registration
* Create App Secret
* Create Custom Role
* Create Service Principal 
* Assign Role to Application on Subscription

Prints out the following to be entered into the Spot Console:
* Application ID
* Subscription ID
* Client Secret ID
* Directory ID
