#########################################
##  Written by steven.feltner@spot.io
## The script will migrate all fargate services to EC2 services to be managed by Spot.io Ocean.
## The script will do the following:
## 1) Clone each fargate service/s task definition to to an EC2 task definition
## 2) Create a duplicate service running on EC2 starting with sfm-

### Parameters ###
account_id = ""
token = ""
ecs_cluster = ""
region = ""
ocean_id = ""
# Profile is Optional
profile_name = ''
###################

import json
import requests
import sys
import time
import boto3
from botocore.exceptions import ProfileNotFound
from botocore.exceptions import ClientError


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
