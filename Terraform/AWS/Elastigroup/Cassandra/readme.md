# Cassandra cluster on Spot.io

## Introduction

In this quick start, we will demonstrate how to create a 3 node Cassandra cluster on Spotinst to reducing cloud compute costs up to 80% while leveraging Spotinst Stateful features in order to keep the cluster available.

When using Spot Instances on stateful application it can be very hard to maintain as they have a 2 minutes notice before termination.
Elastigroup can run Stateful application on spot instances while keeping high availability and provide full SLA.
Elasigroup gives you the option to persist the root and data volume and also the private IP of the instance.

## Cassandra architecture

Cassandra is a distributed system that has an architecture that enables to stay reliable even when one of the nodes goes down.
Cassandra nodes divided into racks and datacenters.

Racks are sets of nodes that don’t have a common replica set, Cassandra will distribute the data between rack in order to have redundancy.
Datacenters are geographically distributed racks in order to get low replication between those racks

To determine the node’s the rack and dc there is a mechanism called snitch, for example, there is an EC2 snitch that divides the racks to AZ  and the DC to regions.
In Cassandra every node has the same role, as a result, there isn't a master in a cluster and every node is independent by himself.
Cassandra splits the data to tokens every token is a slot of multiple keys and every node gets sets of token that he is in charge of and distributes tokens by replication factor.
That means if node 1 is the owner of “red” token with a replication factor of 3 then nodes 2 and 3 will also get the “red” token.
Each node accepts reads and writes if the node will not have the data it will fetch it from the other nodes.
When a node doesn’t have the right data he will fetch it from the other nodes.
To ensure that that data is up to date the node has to get follow consistency level the recommended is a quorum (the majority of replicas).

## Step by step guide

* This Terrafom template will create Stateful Elastigroup with persisting the private IP and Data and root volume.
* Create a Spotinst token  - https://docs.spot.io/administration/api/create-api-token
* Fill the required fields in the exapmple vars
* Apply the Terraform 
 
