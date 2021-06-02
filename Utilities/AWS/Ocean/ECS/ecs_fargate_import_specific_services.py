#########################################
##  Written by Steven Feltner        
## The script will migrate specified fargate services to EC2 services to be managed by Spot.io Ocean.
## The script will do the following:
## 1) Clone each fargate service/s task definition to to an EC2 task definition
## 2) Create a duplicate service running on EC2 starting with sfm-

### Parameters ###
account_id = "act-61e1c107"
token = "c09767fd287c6c0df90a4eeba2380c34e248cd02faee419f81ee7b7be795a52f"
cluster='ECS-Workshop'
region='us-west-2'
ocean_id='o-8b6fe0a3'
services=["ECS-Workshop-1"]
###################

import boto3, json, requests, time, sys

# Creating log file
log_file = open("spotinst_fargate_import_log.txt", "w+")
count = 0

print('Importing fargate services...')
headers = {'Authorization': 'Bearer ' + token}
url = 'https://api.spotinst.io/ocean/aws/ecs/cluster/' + ocean_id +'/fargateMigration?accountId=' + account_id
data = { "services": services, "simpleNewServiceNames": 'true'} 


r = requests.post(url, json=data, headers=headers)
r_text=str(r.text)
log_file = open("spotinst_fargate_import_log.txt", "a+")
log_file.write(r_text)

if r.status_code == 200:
    print("Migration started successfully, service creation will take some time")
else:
    print("FAILED to Migrate services with status code:", r.status_code, "\nPlease check spotinst_fargate_import_log.txt for more information")
    sys.exit()

status = ""
print('Waiting for import to complete....')
while status != "FINISHED":
    prev_status = status
    time.sleep(10)
    if status == "FAILED":
        break
    if status == "FINISHED_PARTIAL_SUCCESS":
        print(temp)
        break
    else:
        url = 'https://api.spotinst.io/ocean/aws/ecs/cluster/'+ocean_id+'/fargateMigration/status?accountId=' + account_id
        r = requests.get(url, headers=headers)
        r_text = json.loads(r.text)
        status = r_text['response']['items'][0]['state']
        if(status != prev_status):
            print('Current migration status: ' + status)

