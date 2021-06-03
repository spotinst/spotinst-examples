##############
## Delete task Definitions that start with "SFM"
## NOTE: Please use at your own discrection. Not responsible for any damage or accidental deletion of AWS infrastructure.
##############

### Parameters ###
region = ''
# Profile is optional
profile_name = ''
###################

import boto3
from botocore.exceptions import ProfileNotFound

try:
    session = boto3.session.Session(profile_name=profile_name)
    client = session.client('ecs', region_name=region)
except ProfileNotFound as e:
    print(e)
    print("Trying without profile...")
    client = boto3.client('ecs', region_name=region)

task_definitions = []

paginator = client.get_paginator('list_task_definitions')
page_iterator = paginator.paginate(status='ACTIVE')

# Get 100 at a time until all retrieved
for page in page_iterator:
    temp = page['taskDefinitionArns']
    for i in temp:
        task_definitions.append(i.split('/', 1)[1])

# Loop through all tasks and deregisters definitions that start with sig
for j in task_definitions:
    if j.startswith('sfm'):
        print("Deregistering task: " + j)
        client.deregister_task_definition(taskDefinition=j)
    else:
        pass
