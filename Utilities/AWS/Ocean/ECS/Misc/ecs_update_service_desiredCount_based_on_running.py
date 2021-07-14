#########################################
##  Written by steven.feltner@spot.io
## Script to update the desiredCount (# of tasks) for all services have less running than desired. 
#########################################

### Parameters ###
cluster = ''
region = ''
desiredCount = 0
# AWS Profile Name (Optional)
profile_name = ''
###################

import boto3
from botocore.exceptions import ProfileNotFound
from botocore.exceptions import ClientError

try:
    session = boto3.session.Session(profile_name=profile_name)
    client = session.client('ecs', region_name=region)
except ProfileNotFound as e:
    print(e)
    try:
        print("Trying without profile...")
        client = boto3.client('ecs', region_name=region)
    except ClientError as e:
        print(e)

try:
    services = client.list_services(cluster=cluster, maxResults=100)
except ClientError as e:
    print(e)

print('---------------------')

service_names = []

for i in services['serviceArns']:
    service_names.append(i.split('/', 1)[1])

for j in service_names:
    # if(j.startswith('sfm')):
    response = client.describe_services(cluster=cluster, services=[j])
    # print(response)
    current_desiredCount = response['services'][0]['desiredCount']
    current_runningCount = response['services'][0]['runningCount']
    ServiceName = response['services'][0]['serviceName']
    if current_runningCount < current_desiredCount:
        print("Services that have more desired than running will now be scaled down...")
        print("ServiceName: " + ServiceName)
        print("desiredCount = " + str(current_desiredCount) + " runningCount = " + str(current_runningCount))
        client.update_service(cluster=cluster, service=j, desiredCount=desiredCount)
        print("Updated service: " + j + " to a desired count of: " + str(desiredCount))
