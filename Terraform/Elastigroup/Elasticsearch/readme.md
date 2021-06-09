# Elasticsearch cluster on Spotinst

## Introduction

In this quick start, we’ll demonstrate how to create an Elasticsearch cluster while using Spotinst to reducing cloud compute costs up to 80% while leveraging Spotinst Stateful features in order to keep the cluster available.

## Spotinst Stateful feature

Ever since Spot Instances were introduced to the cloud computing market, leveraging them was applicable solely for stateless applications, due to the 2-minute interruption notification by AWS which causes a disturbance to the application’s operations.

In order to expand the reach of Spot Instances to additional use cases, we developed stateful capabilities that can run Stateful applications on spot instances while retaining high availability and data continuity.

Spotinst Elastigroup provides the user with the option to persist the root and data volumes, as well as the private IP of the EC2 instance.

Root volume persistency – When Spotinst persists the root volume of the EC2 instance, a back-end process is generating an AMI (Amazon Machine Image) every 5 minutes from the old instance, and in case an interruption is expected, the new instance will boot up from the latest AMI.   

Data volume persistency – When Spotinst persists the data volume of the EC2 instance, a back-end process is generating an AMI using 2 possible methods: Reattach volumes or Snapshot backups.

Private IP persistency – When Spotinst will spin up the new instance it will de-attach the current ENI of the old instance and re-attach it to the new instance.



## Elasticsearch architecture

In Elasticsearch every node has a role or can have a couple of them, There are 3 main roles - Data, Master and ingest role.
Data role - Store the shards and replicas of the indexes.
Ingest role - Reprocess the data before it indexed.
Master role - Mantian the cluster state.

![ELK example of cluster](https://git-quick-start.s3-us-west-2.amazonaws.com/cerbero.png)

Data in Elasticsearch collected to indexes, Every index splits into the different data nodes in the cluster.
There are 2 way to store an index - 
Shard - The primary copy of the index, this copy can be written into and read from.
Replica - The backup copy of the index.

## Delay shard allocation

When the primary shard turns unavailable his replica takes over and become the primary shard while a new replica is created on differenet node
In order to reduce the replication of the new replica while the new spot instance in launched use the command above.

```
curl -XPUT 'localhost:9200/_all/_settings' -H 'Content-Type: application/json' -d '{ "settings": { "index.unassigned.node_left.delayed_timeout": "10m"}}'
```

## Step by step guide

* This Terrafom / Cloudformation template will create Stateful Elastigroup with persisting the private IP and Data and root volume.
* You have to create Spotinst token  - https://api.spotinst.com/spotinst-api/administration/create-an-api-token/
* Fill the required fields in the exapmple vars
* Apply the Terraform / Cloudformation and wait for the slaves to join
 