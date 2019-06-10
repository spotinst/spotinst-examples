# Redis slaves on Spotinst

## Introduction

In this example we will demonstarte how to run Redis cluster slaves on Spotinst using Terraform and Cloudformation while leveraging Spotinst Stateful features in order to keep the cluster available.
Elastigroup Stateful features allows to Persist the root volume, data volume and also the private IP of the instance thus enables you to run redis cluster slaves on Spotinst Elastigroup.

![Stateful](https://git-quick-start.s3-us-west-2.amazonaws.com/Stateful-Redis.png)

## Redis cluster architecture

Redis has 2 main ways of clusters, Sentinal and cluster mode.
We are going to focus on cluster mode, Cluster mode split Redis DB into shards thous every shard holds a portion of the keys by using hash slots.
In Redis there are 16384 hash slots, every key assigned to a hash slot by using the hash function to distribute the keys among the shards.
Every shard (Master) can have a slave replica that can failover from master when he fails, Inorder to failover the cluster has to vote that master isn’t healthy and then the salve will promote to be master.

![Quick Start Terraform with redis](https://git-quick-start.s3-us-west-2.amazonaws.com/Redis.png)

## Step by step guide

* This Terrafom / Cloudformation template will create Stateful Elastigroup with persisting the private IP and Data and root volume.
* You have to create Spotinst token  - https://api.spotinst.com/spotinst-api/administration/create-an-api-token/
* Fill the required fields in the exapmple vars
* Apply the Terraform / Cloudformation and wait for the slaves to join
 
