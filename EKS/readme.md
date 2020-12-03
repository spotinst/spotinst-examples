# EKS on Spot.io

## Introduction

In this example we will demonstrate how to integrate with an AWS EKS cluster on Spot.io using Terraform and Cloudformation while leveraging Spot.io features in order to keep the cluster highly available on EC2 Spot instances.

## Terraform Modules:
- A Terraform module to create an Amazon Elastic Kubernetes Service (EKS) cluster with Spot Ocean : https://tf-registry.herokuapp.com/modules/spotinst/ocean-eks/spotinst/latest

- A Terraform module to install the Ocean Controller : https://tf-registry.herokuapp.com/modules/spotinst/ocean-controller/spotinst/latest

## Step by step guide
* This Terrafom template will create an Spot.io Ocean Cluster and manage the data plane (Worker Nodes)
* You have to create Spotinst token  - https://docs.spot.io/administration/api/create-api-token
* Fill the required fields in the example ```variables.tfvars```
* Apply the Terraform