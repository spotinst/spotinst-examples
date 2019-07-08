#!/usr/bin/env python
# coding: utf-8

import requests
import boto3

# This script recieves account_id, token and filename and imports Stateful instances as specified in the given file.
# Every line in the file is equal to one instance
# The line format should be: instance_id;elastigroup_name;region;instance_types;shouldKeepPrivateIP(true/false);
# Instance types should be written: instance_type1,instance_type2,...
# If shouldKeepPrivateIP is set to true the original instance will be terminated in the process
# and the Elastigroup will be configured to Maintain Private IP
# Example: i-01365b71385ef3b86;elastigorup-stateful;us-west-2;t2.medium,t3.large;False

# Parameters
account_id = ""
token = ""
filename = ""

# Opening file
f = open(filename, "r")
content = f.read()
lines = content.split("\n")

# Creating log file
log_file = open("multiple_stateful_import_log.txt", "w+")
count = 0

# Running on the lines in the file
for line in lines:
    if line == "":
        break

    # Getting input from the line
    columns = line.split(";")
    instance_id = columns[0]
    elg_name = columns[1]
    region = columns[2]
    instance_types_input = columns[3]
    keep_private_ip = columns[4]

    # get instance tag Name for the Elastigroup name
    ec2 = boto3.resource('ec2')
    ec2instance = ec2.Instance(instance_id)
    instancename = ''
    for tags in ec2instance.tags:
        if tags["Key"] == 'Name':
            instancename = tags["Value"]
    elg_name = instancename if instancename else columns[1]

    # Fixing instance types format
    instance_types = instance_types_input.split(",")
    inst_types = []
    for inst_type in instance_types:
        inst_types.append("\'" + inst_type + "\'")

    # Importing Stateful Instance
    print('Importing Stateful Instance:', instance_id, 'In region:', region)
    headers = {'Authorization': 'Bearer ' + token}
    url = 'https://api.spotinst.io/aws/ec2/statefulMigrationGroup?accountId=' + account_id
    data = {'statefulMigrationGroup': {'shouldKeepPrivateIp': bool(keep_private_ip), 'originalInstanceId': instance_id, 'name': elg_name,
                                       'product': 'Linux/UNIX', 'spotInstanceTypes': instance_types, 'region': region}}

    r = requests.post(url, json=data, headers=headers)
    r_text = str(r.text)
    log_file = open("multiple_stateful_import_log.txt", "a+")
    log_file.write(r_text)

    # Printing result for this instance
    if r.status_code == 200:
        print("Import of Stateful Instance:",
              instance_id, "completed succesfully!")
        count = count + 1
    else:
        print("Import of Stateful Instance:", instance_id,
              "failed with status code:", r.status_code)

print("Succesfuly imported", count, "of", len(lines),
      "Stateful Instance, for more information see multiple_stateful_import_log.txt")
