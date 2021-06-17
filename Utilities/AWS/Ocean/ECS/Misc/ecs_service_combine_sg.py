#########################################
##  Written by steven.feltner@spot.io
## This script should be ran BEFORE a spotinst ECS service import.
## The script will gather all services and do the following:
## 1) Describe all Services
## 2) Gather all SGs for each service
## 3) Create new Master SG
## 4) Copy all rules from existing SGS into master SG
## NOTE: Please use at your own discrection. Not responsible for any damage or accidental deletion of AWS infrastructure.


### Parameters ###
ecs_cluster = ""
securityGroup_description = ""
securityGroupName = ""
vpcId = ""
region = ""
# Profile is Optional
profile_name = ""
###################

import boto3
from botocore.exceptions import ClientError
from botocore.exceptions import ProfileNotFound


def divide_chunks(l, n):
    for i in range(0, len(l), n):
        yield l[i:i + n]


# variables
n = 5
service_names = []
service_list = []
security_group_ids = []
ip_permissions = []

try:
    session = boto3.session.Session(profile_name=profile_name)
    client = session.client('ecs', region_name=region)
except ProfileNotFound as e:
    print(e)
    print("Trying without profile...")
    client = boto3.client('ecs', region_name=region)

services = client.list_services(cluster=ecs_cluster, maxResults=100)

for i in services['serviceArns']:
    service_names.append(i.split('/', 1)[1])

# Only get services that start with sig
for j in service_names:
    if (j.startswith('sig')):
        pass
    else:
        service_list.append(j)

# describe the services from the cluster with a max of 10 at a time
# divide the list into chuncks of 10
x = list(divide_chunks(service_list, n))

# get list of SG IDs for the each services in the cluster
for i in range(len(x)):
    services = client.describe_services(cluster=ecs_cluster, services=x[i])

    for i in range(len(services['services'])):
        securityGroups = services['services'][i]['networkConfiguration']['awsvpcConfiguration']['securityGroups']
        for y in range(len(securityGroups)):
            security_group_ids.append(securityGroups[y])

client = boto3.client('ec2', region_name=region)

# Get description of all security groups and rules
for i in range(len(security_group_ids)):
    securitygroups = client.describe_security_groups(GroupIds=[security_group_ids[i]])
    ip_permissions.append(securitygroups['SecurityGroups'][0]['IpPermissions'])

# Create a single security group
try:
    GroupId = client.create_security_group(Description=securityGroup_description, GroupName=securityGroupName,
                                           VpcId=vpcId, DryRun=False)
except ClientError as e:
    if e.response['Error']['Code'] == 'InvalidGroup.Duplicate':
        print("ERROR - The security group already exists in the VPC")
        exit()
    else:
        print("ERROR - Unable to create security group")
        exit()

GroupId = GroupId.get('GroupId')

# Add all rules to new security group
for i in range(len(ip_permissions)):
    try:
        client.authorize_security_group_ingress(GroupId=GroupId, IpPermissions=ip_permissions[i])
    except ClientError as e:
        if e.response['Error']['Code'] == 'InvalidPermission.Duplicate':
            print(e.response['Error']['Message'] + " - Skipping")
        else:
            print("ERROR - Unable to add ingress rule to security group")

# get the security group ID and print to screen
print("The security group ID: " + GroupId)
