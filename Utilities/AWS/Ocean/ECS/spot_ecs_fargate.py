#########################################
##  Written by steven.feltner@spot.io
## NOTE: Please use at your own discretion. Not responsible for any damage or accidental deletion of AWS infrastructure.
#########################################

import base64
import json
import requests
import sys
import time
import click
import ast

import boto3
from botocore.exceptions import ClientError
from botocore.exceptions import ProfileNotFound
from spotinst_sdk2 import SpotinstSession


class PythonLiteralOption(click.Option):
    def type_cast_value(self, ctx, value):
        try:
            return ast.literal_eval(value)
        except:
            raise click.BadParameter(value)


@click.group()
@click.pass_context
def cli(ctx, *args, **kwargs):
    ctx.obj = {}
    # Remove Spotinst SDK
    # session = SpotinstSession()
    # ctx.obj['client'] = session.client("ocean_aws")


@cli.command()
@click.option(
    '--account_id',
    '-a',
    type=str,
    required=True,
    help='Spot Account ID '
)
@click.option(
    '--token',
    '-t',
    type=str,
    required=True,
    help='Spot.io Token'
)
@click.option(
    '--ecs_cluster',
    '-e',
    type=str,
    required=True,
    help='Name of the ECS cluster'
)
@click.option(
    '--sg_name',
    type=str,
    default="FargateSecurityGroup",
    show_default=True,
    required=True,
    help='Name of the new security group'
)
@click.option(
    '--sg_description',
    type=str,
    default="FargateSecurityGroup",
    show_default=True,
    required=True,
    help='Description of the new security group'
)
@click.option(
    '--region',
    '-r',
    type=str,
    required=True,
    help='Region where the ECS cluster is located'
)
@click.option(
    '--vpc',
    '-v',
    type=str,
    required=True,
    help='VPC ID'
)
@click.option(
    '--subnet_ids',
    '-s',
    cls=PythonLiteralOption,
    default=[],
    required=True,
    help='Subnet ids - Syntax: \'["subnet-123456","subnet-123456"]\''
)
@click.option(
    '--iam_instance_role',
    type=str,
    required=True,
    help='This is the instance profile for the AWS ecsInstanceRole. The instance profile arn EX: arn:aws:iam::123456789:instance-profile/ecsInstanceRole'
)
@click.option(
    '--ecs_ami',
    type=str,
    required=True,
    help='ECS optimized AMI ID'
)
@click.option(
    '--profile',
    type=str,
    required=False,
    help='AWS CLI Profile Name'
)
@click.option(
    '--access_key',
    type=str,
    required=False,
    help='Access key for AWS CLI access'
)
@click.option(
    '--secret_key',
    type=str,
    required=False,
    help='Secret key for AWS CLI access'
)
@click.option(
    '--session_token',
    type=str,
    required=False,
    help='Session token for AWS CLI access'
)
@click.pass_context
def import_fargate(ctx, *args, **kwargs):
    """## The script will gather all services and do the following:
## 1) Describe all services within specified ECS cluster
## 2) Gather all SGs for each service
## 3) Create new Master SG
## 4) Copy all rules from existing SGS into master SG
## 5) Create a Spot Ocean Cluster
## 6) Copy/Import all fargate services into EC2 services (This does not remove/delete original fargate services)
## NOTE: Please use at your own discretion. Not responsible for any damage or accidental deletion of AWS infrastructure."""
    sg_id = create_sg(ecs_cluster=kwargs.get('ecs_cluster'), vpc=kwargs.get('vpc'), region=kwargs.get('region'),
                      sg_name=kwargs.get('sg_name'), sg_description=kwargs.get('sg_description'),
                      profile_name=kwargs.get('profile_name'), access_key=kwargs.get('access_key'),
                      secret_key=kwargs.get('secret_key'), session_token=kwargs.get('session_token'))
    oceanid = create_ocean(account_id=kwargs.get('account_id'), token=kwargs.get('token'),
                           ecs_cluster=kwargs.get('ecs_cluster'), region=kwargs.get('region'),
                           subnet_ids=kwargs.get('subnet_ids'), ecs_ami_id=kwargs.get('ecs_ami'), sg_id=sg_id,
                           iam_instance_role=kwargs.get('iam_instance_role'))
    fargate_import(profile_name=kwargs.get('profile'), region=kwargs.get('region'), access_key=kwargs.get('access_key'),
                   secret_key=kwargs.get('secret_key'), session_token=kwargs.get('session_token'),
                   ecs_cluster=kwargs.get('ecs_cluster'), ocean_id=oceanid, account_id=kwargs.get('account_id'),
                   token=kwargs.get('token'))


@cli.command()
@click.option(
    '--ecs_cluster',
    '-e',
    type=str,
    required=True,
    help='Name of the ECS cluster'
)
@click.option(
    '--region',
    '-r',
    type=str,
    required=True,
    help='Region where the ECS cluster is located'
)
@click.option(
    '--skip_nonrunning',
    type=bool,
    default=False,
    help='Decide if we skip services that currently have no running tasks'
)
@click.option(
    '--profile',
    type=str,
    required=False,
    help='AWS CLI Profile Name'
)
@click.option(
    '--access_key',
    type=str,
    required=False,
    help='Access key for AWS CLI access'
)
@click.option(
    '--secret_key',
    type=str,
    required=False,
    help='Secret key for AWS CLI access'
)
@click.option(
    '--session_token',
    type=str,
    required=False,
    help='Session token for AWS CLI access'
)
@click.pass_context
def rename_fargate(ctx, *args, **kwargs):
    """## The script will look for any migrated (fargate -> EC2) services starting with "sfm" and do the following:
## 1) Scale Original Fargate service to zero
## 2) Delete Original Fargate service
## 3) Copy configs of migrated EC2 service task definition
## 4) Create new EC2 service with same name as Original Fargate service
## 5) Scale Migrated "sfm" service to zero
## 6) Delete migrated "sfm" service
## NOTE: Please use at your own discretion. Not responsible for any damage or accidental deletion of AWS infrastructure."""
    rename_services(ecs_cluster=kwargs.get('ecs_cluster'), region=kwargs.get('region'),
                    skip_nonrunning=kwargs.get('skip_nonrunning'),
                    profile_name=kwargs.get('profile_name'), access_key=kwargs.get('access_key'),
                    secret_key=kwargs.get('secret_key'), session_token=kwargs.get('session_token'))


####################
# Helper function to divide into chunks
##################
def divide_chunks(l, n):
    for i in range(0, len(l), n):
        yield l[i:i + n]


####################
# Create a single SG for all the services in the cluster.
##################
def create_sg(ecs_cluster, vpc, region, sg_name, sg_description, profile_name, access_key, secret_key, session_token):
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
                                  aws_access_key_id=access_key,
                                  aws_secret_access_key=secret_key,
                                  aws_session_token=session_token)

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
                                  aws_access_key_id=access_key,
                                  aws_secret_access_key=secret_key,
                                  aws_session_token=session_token)

    # Get description of all security groups and rules
    for i in range(len(security_group_ids)):
        try:
            securitygroups = client.describe_security_groups(GroupIds=[security_group_ids[i]])
            ip_permissions.append(securitygroups['SecurityGroups'][0]['IpPermissions'])
        except ClientError as e:
            print(e)

    # Create a single security group
    try:
        sg_id = client.create_security_group(Description=sg_description, GroupName=sg_name,
                                             VpcId=vpc, DryRun=False)
        sg_id = sg_id.get('groupid')
        # Add all rules to new security group
        for i in range(len(ip_permissions)):
            try:
                client.authorize_security_group_ingress(GroupId=str(sg_id), IpPermissions=ip_permissions[i])
            except ClientError as e:
                if e.response['Error']['Code'] == 'InvalidPermission.Duplicate':
                    print(e.response['Error']['Message'] + " - Skipping")
                else:
                    print("ERROR - Unable to add ingress rule to security group")
    except ClientError as e:
        if e.response['Error']['Code'] == 'InvalidGroup.Duplicate':
            print("WARNING - The security group already exists in the VPC. Will add rules to existing SG")
            try:
                sg_id = client.describe_security_groups(
                    Filters=[{'Name': 'group-name', 'Values': [sg_name]}, {'Name': 'vpc-id', 'Values': [vpc]}])
                sg_id = sg_id.get('SecurityGroups')[0].get('GroupId')
                # Add all rules to new security group
                for i in range(len(ip_permissions)):
                    try:
                        client.authorize_security_group_ingress(GroupId=str(sg_id), IpPermissions=ip_permissions[i])
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
            client.authorize_security_group_ingress(GroupId=sg_id, IpPermissions=ip_permissions[i])
        except ClientError as e:
            if e.response['Error']['Code'] == 'InvalidPermission.Duplicate':
                print(e.response['Error']['Message'] + " - Skipping")
            else:
                print("ERROR - Unable to add ingress rule to security group")
                print(e.response)

    # get the security group ID and print to screen
    time.sleep(2)
    print("The security group ID: " + sg_id)
    return sg_id


#########################################
## The will create an ECS Ocean Cluster:
#########################################
def create_ocean(account_id, token, ecs_cluster, region, subnet_ids, ecs_ami_id, sg_id, iam_instance_role):
    ocean_exist = False

    headers = {'Authorization': 'Bearer ' + token}
    url = 'https://api.spotinst.io/ocean/aws/ecs/cluster?accountId=' + account_id

    r = requests.get(url, headers=headers)
    r_json = json.loads(r.text)
    if r.status_code == 200:
        items = r_json["response"]["items"]
        for x in items:
            if x["clusterName"] == ecs_cluster:
                print("Ocean Cluster already exists, SKIPPING....")
                ocean_id = x["id"]
                ocean_exist = True

    if not ocean_exist:
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
                    "subnetIds": subnet_ids,
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
                            sg_id
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
    return ocean_id


#########################################
# import fargate services
#########################################
def fargate_import(profile_name, region, access_key, secret_key, session_token, ecs_cluster, ocean_id, account_id,
                   token):
    service_names = []
    service_sfm_names = []

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
                                  aws_access_key_id=access_key,
                                  aws_secret_access_key=secret_key,
                                  aws_session_token=session_token)

    services = client.list_services(cluster=ecs_cluster, maxResults=100)

    for i in services['serviceArns']:
        try:
            temp = i.split('/')[2]
            if temp.startswith('sfm'):
                temp = temp.split('-', 1)[1]
                service_sfm_names.append(temp)
            else:
                service_names.append(temp)
                print("Service to import: " + temp)
        except:
            temp = i.split('/')[1]
            if temp.startswith('sfm'):
                temp = temp.split('-', 1)[1]
                service_sfm_names.append(temp)
            else:
                service_names.append(temp)
                print("Service to import: " + temp)

    print('Checking if the services have already been migrated...')

    service_names_filtered = []
    for x in service_names:
        if x not in service_sfm_names:
            service_names_filtered.append(x)
        else:
            print("Service: " + x + " has already been imported. SKIPPING")

    print('Importing fargate services...')

    if service_names_filtered:
        headers = {'Authorization': 'Bearer ' + token}
        url = 'https://api.spotinst.io/ocean/aws/ecs/cluster/' + ocean_id + '/fargateMigration?accountId=' + account_id
        data = {"services": service_names_filtered, "simpleNewServiceNames": 'true'}

        result = requests.post(url, json=data, headers=headers)

        if result.status_code == 200:
            print("Migration started, service creation will take some time")
        else:
            print("FAILED to Migrate services with status code:", result.status_code)
            print(result.text)
            sys.exit()

        status = ""
        print('Waiting for import to complete...')
        while status != "FINISHED":
            prev_status = status
            time.sleep(10)
            if status == "FAILED":
                break
            if status == "FINISHED_PARTIAL_SUCCESS":
                break
            else:
                url = 'https://api.spotinst.io/ocean/aws/ecs/cluster/' + ocean_id + '/fargateMigration/status?accountId=' + account_id
                result = requests.get(url, headers=headers)
                r_text = json.loads(result.text)
                if result.status_code == 200:
                    status = r_text['response']['items'][0]['state']
                    if status != prev_status:
                        print('Current migration status: ' + status)
                else:
                    print(r_text)


#########################################
# rename fargate services
#########################################
def rename_services(ecs_cluster, region, skip_nonrunning, profile_name, access_key, secret_key, session_token):
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
                                  aws_access_key_id=access_key,
                                  aws_secret_access_key=secret_key,
                                  aws_session_token=session_token)

    services = client.list_services(cluster=ecs_cluster, maxResults=100)

    print('---------------------')

    # Original service Names
    service_names = []
    # Migrated service Names
    service_list = []

    for i in services['serviceArns']:
        # If using newer services it will be the second element
        try:
            service_names.append(i.split('/', 2)[2])
        # If using legacy services it will be the first element
        except:
            service_names.append(i.split('/', 2)[1])

    # Only get services that start with "sfm"
    for j in service_names:
        if j.startswith('sfm'):
            response = client.describe_services(cluster=ecs_cluster, services=[j])
            current_runningcount = response['services'][0]['runningCount']
            if skip_nonrunning:
                if current_runningcount == 0:
                    print("SKIPPING - service " + j + " has no tasks running")
                else:
                    service_list.append(j)
            else:
                service_list.append(j)
        else:
            pass

    # Get the service names for the migrated services. Convert back to original name
    service_names = []
    for i in service_list:
        service = i.split('-', 1)[1]
        service_names.append(service)

    # delete original fargate services
    for i in range(len(service_names)):
        print("Updating orginal Fargate service to Zero: " + service_names[i])
        try:
            client.update_service(cluster=ecs_cluster, service=service_names[i], desiredCount=0)
            task = client.list_tasks(cluster=ecs_cluster, serviceName=service_names[i])
            for x in task['taskArns']:
                task_name = (x.split('/', 1)[1])
                print("Stopping task: " + task_name)
                client.stop_task(cluster=ecs_cluster, task=task_name)
        except ClientError as e:
            print(e)

        print("Deleting original Fargate service: " + service_names[i])
        try:
            client.delete_service(cluster=ecs_cluster, service=service_names[i])
        except ClientError as e:
            print(e)

    # wait for the services to be deleted before creating new ones with the same name
    time.sleep(60)

    # describe the services from the cluster with a max of 10 at a time
    # divide the list into chunks of 1
    n = 1
    x = list(divide_chunks(service_list, n))

    # Get the configurations from the migrated services and create new service with corrected/original name
    for i in range(len(x)):
        services = client.describe_services(cluster=ecs_cluster, services=x[i])
        temp = services.get('services')
        dict = temp[0]
        print("Creating EC2 Service: " + service_names[i])
        try:
            client.create_service(cluster=ecs_cluster, serviceName=service_names[i],
                                  taskDefinition=dict.get('taskDefinition'),
                                  loadBalancers=dict.get('loadBalancers'),
                                  serviceRegistries=dict.get('serviceRegistries'),
                                  desiredCount=dict.get('desiredCount'), launchType=dict.get('launchType'),
                                  deploymentConfiguration=dict.get('deploymentConfiguration'),
                                  placementConstraints=dict.get('placementConstraints'),
                                  placementStrategy=dict.get('placementStrategy'),
                                  networkConfiguration=dict.get('networkConfiguration'),
                                  schedulingStrategy=dict.get('schedulingStrategy'))
        except ClientError as e:
            print(e)

    # delete Migrated EC2 services with sfm
    for i in range(len(service_list)):
        print("Deleting Migrated SFM Service: " + service_list[i])
        try:
            client.update_service(cluster=ecs_cluster, service=service_list[i], desiredCount=0)
        except ClientError as e:
            print(e)
        try:
            client.delete_service(cluster=ecs_cluster, service=service_list[i])
        except ClientError as e:
            print(e)

    print("Completed")
    print('---------------------')


if __name__ == "__main__":
    cli()
