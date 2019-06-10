# Redis slaves on Spotinst

## Introduction

Terraform quickstart to use Redis cluster slaves on Spotinst to reducing cloud compute costs up to 80% while leveraging Spotinst Stateful features in order to keep the cluster available.

## Redis cluster architecture

Redis has 2 main ways of clusters, Sentinal and cluster mode.
We are going to focus on cluster mode, Cluster mode split Redis DB into shards thous every shard holds a portion of the keys by using hash slots.
In Redis there are 16384 hash slots, every key assigned to a hash slot by using the hash function to distribute the keys among the shards.
Every shard (Master) can have a slave replica that can failover from master when he fails, Inorder to failover the cluster has to vote that master isn’t healthy and then the salve will promote to be master.

![Quick Start Terraform with redis](https://git-quick-start.s3-us-west-2.amazonaws.com/Redis.png)

