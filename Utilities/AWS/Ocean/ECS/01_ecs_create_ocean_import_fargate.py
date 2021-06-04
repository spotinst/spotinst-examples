#########################################
##  Written by steven.feltner@spot.io
## This script should be ran BEFORE a spotinst ECS service import.
## The script will gather all services and do the following:
## 1) Describe all services within specified ECS cluster
## 2) Gather all SGs for each service
## 3) Create new Master SG
## 4) Copy all rules from existing SGS into master SG
## 5) Create a Spot Ocean Cluster
## 6) Copy/Import all fargate services into EC2 services (This does not remove/delete original fargate services)
## NOTE: Please use at your own discretion. Not responsible for any damage or accidental deletion of AWS infrastructure.

### Parameters ###
# Spot Account ID
account_id = ""
# Spot API Token
token = ""

ecs_cluster = ''
# New Secuirty Group - Can not be empty
securityGroupName = ''
# New Secuirty Group Name - Can not be empty
securityGroup_description = ''
# Network Details
region = ''
vpcId = ''
# Enter one or more subnet separated with comma
subnet_id = ""
# instance profile arn EX: arn:aws:iam::123456789:instance-profile/ecsInstanceRole
# to create one follow: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/instance_IAM_role.html
iam_instance_role = ""
# ECS optimized AMI can be found: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-optimized_AMI.html
ecs_ami_id = ""
# AWS credential Profile Name (Optional)
profile_name = ""
# AWS credentials (optional)
ACCESS_KEY = ""
SECRET_KEY = ""
SESSION_TOKEN = ""
###################

import base64
import json
import requests
import sys
import time

import boto3
from botocore.exceptions import ClientError
from botocore.exceptions import ProfileNotFound


####################
# Create a single SG for all the services in the cluster.
##################
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
    try:
        client = boto3.client('ecs', region_name=region)
    except ClientError as e:
        client = boto3.client('ecs', region_name=region,
                              aws_access_key_id=ACCESS_KEY,
                              aws_secret_access_key=SECRET_KEY,
                              aws_session_token=SESSION_TOKEN)

services = client.list_services(cluster=ecs_cluster, maxResults=100)

for i in services['serviceArns']:
    service_names.append(i.split('/', 1)[1])

# Only get services that do not start with sfm or previously imported by spotinst
for j in service_names:
    if j.startswith('sfm'):
        pass
    else:
        service_list.append(j)

# describe the services from the ecs_cluster with a max of 10 at a time
# divide the list into chunks of 10
x = list(divide_chunks(service_list, n))

# get list of SG IDs for the each services in the cluster
for i in range(len(x)):
    try:
        services = client.describe_services(cluster=ecs_cluster, services=x[i])
    except ClientError as e:
        print(e)

    for j in range(len(services['services'])):
        securityGroups = services['services'][j]['networkConfiguration']['awsvpcConfiguration']['securityGroups']
        for y in range(len(securityGroups)):
            security_group_ids.append(securityGroups[y])

try:
    session = boto3.session.Session(profile_name=profile_name)
    client = session.client('ec2', region_name=region)
except ProfileNotFound as e:
    print(e)
    print("Trying without profile...")
    try:
        client = boto3.client('ec2', region_name=region)
    except ClientError as e:
        client = boto3.client('ec2', region_name=region,
                              aws_access_key_id=ACCESS_KEY,
                              aws_secret_access_key=SECRET_KEY,
                              aws_session_token=SESSION_TOKEN)

# Get description of all security groups and rules
for i in range(len(security_group_ids)):
    try:
        securitygroups = client.describe_security_groups(GroupIds=[security_group_ids[i]])
        ip_permissions.append(securitygroups['SecurityGroups'][0]['IpPermissions'])
    except ClientError as e:
        print(e)

# Create a single security group
try:
    GroupId = client.create_security_group(Description=securityGroup_description, GroupName=securityGroupName,
                                           VpcId=vpcId, DryRun=False)
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
except ClientError as e:
    if e.response['Error']['Code'] == 'InvalidGroup.Duplicate':
        print("WARNING - The security group already exists in the VPC. Will add rules to existing SG")
        try:
            GroupId = client.describe_security_groups(
                Filters=[{'Name': 'group-name', 'Values': [securityGroupName]}, {'Name': 'vpc-id', 'Values': [vpcId]}])
            GroupId = GroupId.get('SecurityGroups')[0].get('GroupId')
            # Add all rules to new security group
            for i in range(len(ip_permissions)):
                try:
                    client.authorize_security_group_ingress(GroupId=GroupId, IpPermissions=ip_permissions[i])
                except ClientError as e:
                    if e.response['Error']['Code'] == 'InvalidPermission.Duplicate':
                        print(e.response['Error']['Message'] + " - Skipping")
                    else:
                        print("ERROR - Unable to add ingress rule to security group")
                        print(e.response)
        except ClientError as e:
            print("ERROR - Unable to add rules to existing security group")
            print(e.response)
            exit()
    else:
        print("ERROR - Unable to create security group")
        print(e.response)
        exit()

# Add all rules to new security group
for i in range(len(ip_permissions)):
    try:
        client.authorize_security_group_ingress(GroupId=GroupId, IpPermissions=ip_permissions[i])
    except ClientError as e:
        if e.response['Error']['Code'] == 'InvalidPermission.Duplicate':
            print(e.response['Error']['Message'] + " - Skipping")
        else:
            print("ERROR - Unable to add ingress rule to security group")
            print(e.response)

# get the security group ID and print to screen
time.sleep(2)
print("The security group ID: " + GroupId)

#########################################
## The will create an ECS Ocean Cluster:
#########################################

# Create user data for ocean cluster in base64
user_data = "#!/bin/bash \necho ECS_CLUSTER=" + ecs_cluster + " >> /etc/ecs/ecs.config;echo ECS_BACKEND_HOST= >> /etc/ecs/ecs.config;"
encodedBytes = base64.b64encode(user_data.encode("utf-8"))
encoded_user_data = str(encodedBytes, "utf-8")

# print(encoded_user_data)

print('Creating Ocean Cluster...')
headers = {'Authorization': 'Bearer ' + token}
url = 'https://api.spotinst.io/ocean/aws/ecs/cluster?accountId=' + account_id
data = {
    "cluster": {
        "clusterName": ecs_cluster,
        "name": ecs_cluster,
        "region": region,
        "autoScaler": {
            "isEnabled": 'true',
            "down": {
                "maxScaleDownPercentage": 10
            },
            "headroom": {
                "cpuPerUnit": 0,
                "memoryPerUnit": 0,
                "numOfUnits": 0
            }
        },
        "capacity": {
            "minimum": 0,
            "maximum": 1000,
            "target": 1
        },
        "strategy": {
            "fallbackToOd": 'true',
            "utilizeReservedInstances": 'true',
            "drainingTimeout": 120
        },
        "compute": {
            "subnetIds": [
                subnet_id
            ],
            "optimizeImages": {
                "shouldOptimizeEcsAmi": 'true',
                "performAt": "always"
            },
            "instanceTypes": {
                "whitelist": [
                    "a1.medium",
                    "a1.large",
                    "a1.xlarge",
                    "a1.2xlarge",
                    "a1.4xlarge",
                    "c5.large",
                    "c5.xlarge",
                    "c5.2xlarge",
                    "c5.4xlarge",
                    "c5.9xlarge",
                    "c5.18xlarge",
                    "c5d.large",
                    "c5d.xlarge",
                    "c5d.2xlarge",
                    "c5d.4xlarge",
                    "c5d.9xlarge",
                    "c5d.18xlarge",
                    "m5.large",
                    "m5.xlarge",
                    "m5.2xlarge",
                    "m5.4xlarge",
                    "m5.12xlarge",
                    "m5.24xlarge",
                    "m5a.large",
                    "m5a.xlarge",
                    "m5a.2xlarge",
                    "m5a.4xlarge",
                    "m5a.12xlarge",
                    "m5a.24xlarge",
                    "m5ad.large",
                    "m5ad.xlarge",
                    "m5ad.2xlarge",
                    "m5ad.4xlarge",
                    "m5ad.12xlarge",
                    "m5ad.24xlarge",
                    "m5d.large",
                    "m5d.xlarge",
                    "m5d.2xlarge",
                    "m5d.4xlarge",
                    "m5d.12xlarge",
                    "m5d.24xlarge",
                    "p3.2xlarge",
                    "p3.8xlarge",
                    "p3.16xlarge",
                    "r5.large",
                    "r5.xlarge",
                    "r5.2xlarge",
                    "r5.4xlarge",
                    "r5.12xlarge",
                    "r5.24xlarge",
                    "r5a.large",
                    "r5a.xlarge",
                    "r5a.2xlarge",
                    "r5a.4xlarge",
                    "r5a.12xlarge",
                    "r5a.24xlarge",
                    "r5ad.large",
                    "r5ad.xlarge",
                    "r5ad.2xlarge",
                    "r5ad.4xlarge",
                    "r5ad.12xlarge",
                    "r5ad.24xlarge",
                    "r5d.large",
                    "r5d.xlarge",
                    "r5d.2xlarge",
                    "r5d.4xlarge",
                    "r5d.12xlarge",
                    "r5d.24xlarge"]
            },
            "launchSpecification": {
                "imageId": ecs_ami_id,
                "userData": encoded_user_data,
                "securityGroupIds": [
                    GroupId
                ],

                "iamInstanceProfile": {
                    "arn": iam_instance_role
                },
                "tags": [
                    {
                        "tagKey": "Name",
                        "tagValue": ecs_cluster
                    },
                    {
                        "tagKey": "CreatedBy",
                        "tagValue": "Spotinst"
                    }
                ],
                "monitoring": 'true',
            }
        }
    }
}

r = requests.post(url, json=data, headers=headers)
r_text = json.loads(r.text)

if r.status_code == 200:
    ocean_id = r_text['response']['items'][0]['id']
    print("Created Ocean Cluster successfully, the Ocean ID: " + ocean_id)
else:
    print("FAILED to create Ocean Cluster with status code:", r.status_code)
    print(r.text)
    sys.exit()

#########################################
# import fargate services 
#########################################

service_names = []

try:
    session = boto3.session.Session(profile_name=profile_name)
    client = session.client('ecs', region_name=region)
except ProfileNotFound as e:
    print(e)
    print("Trying without profile...")
    try:
        client = boto3.client('ecs', region_name=region)
    except ClientError as e:
        client = boto3.client('ecs', region_name=region,
                              aws_access_key_id=ACCESS_KEY,
                              aws_secret_access_key=SECRET_KEY,
                              aws_session_token=SESSION_TOKEN)

services = client.list_services(cluster=ecs_cluster, maxResults=100)

for i in services['serviceArns']:
    try:
        temp = i.split('/')[2]
        if temp.startswith('sfm'):
            pass
        else:
            service_names.append(temp)
            print("Service to import: " + temp)
    except:
        temp = i.split('/')[1]
        if temp.startswith('sfm'):
            pass
        else:
            service_names.append(temp)
            print("Service to import: " + temp)

print('Importing fargate services...')

headers = {'Authorization': 'Bearer ' + token}
url = 'https://api.spotinst.io/ocean/aws/ecs/cluster/' + ocean_id + '/fargateMigration?accountId=' + account_id
data = {"services": service_names, "simpleNewServiceNames": 'true'}

r = requests.post(url, json=data, headers=headers)

if r.status_code == 200:
    print("Migration was successfully, service creation will take some time")
else:
    print("FAILED to Migrate services with status code:", r.status_code)
    print(r.text)
    sys.exit()

status = ""
print('Waiting for import to complete....')
while status != "FINISHED":
    prev_status = status
    update_progress(status)
    time.sleep(10)
    if status == "FAILED":
        break
    if status == "FINISHED_PARTIAL_SUCCESS":
        break
    else:
        url = 'https://api.spotinst.io/ocean/aws/ecs/cluster/' + ocean_id + '/fargateMigration/status?accountId=' + account_id
        r = requests.get(url, headers=headers)
        r_text = json.loads(r.text)
        status = r_text['response']['items'][0]['state']
        if status != prev_status:
            print('Current migration status: ' + status)
