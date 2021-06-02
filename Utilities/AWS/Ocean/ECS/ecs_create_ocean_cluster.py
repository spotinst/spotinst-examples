#########################################
##  Written by Steven Feltner@spotinst
## The script will create an ECS Ocean Cluster:

# ECS optimized AMI can be found: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-optimized_AMI.html 
# IAM role needs to be in arn format

### Parameters ###
account_id = ""
token = ""
ecs_cluster=""
region=""
subnet_id=""
securityGroup_id=""
iam_instance_role=""
ecs_ami_id=""
keyPair = ""
###################

import json, base64, requests

#########################################
## The will create an ECS Ocean Cluster:
#########################################

# Creating log file
log_file = open("spotinst_ocean_ecs_create_log.txt", "w+")
count = 0

#Create user data for ocean cluster in base64
user_data = "#!/bin/bash \necho ECS_CLUSTER="+ecs_cluster+" >> /etc/ecs/ecs.config;echo ECS_BACKEND_HOST= >> /etc/ecs/ecs.config;"
encodedBytes = base64.b64encode(user_data.encode("utf-8"))
encoded_user_data = str(encodedBytes, "utf-8")

#print(encoded_user_data)

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
      "cooldown": 180,
      "down": {
        "evaluationPeriods": 3,
        "maxScaleDownPercentage": 60
      },
    },
    "capacity": {
      "minimum": 0,
      "maximum": 1000,
      "target": 1
    },
    "strategy": {
      "fallbackToOd": 'true',
      "utilizeReservedInstances": 'true',
      "drainingTimeout": 60
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
      "keyPair": keyPair,
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
      "associatePublicIpAddress" : 'false',
      "monitoring": 'true',
      }
    }
  }
}

r = requests.post(url, json=data, headers=headers)
r_text = str(r.text)

log_file = open("spotinst_ocean_ecs_create_log.txt", "a+")
log_file.write(r_text)
r_text = json.loads(r.text)

if r.status_code == 200:
    ocean_id = r_text['response']['items'][0]['id']
    print("Created Ocean Cluster successfully, the Ocean ID: " + ocean_id)
else:
    print("FAILED to create Ocean Cluster with status code:", r.status_code, "\nPlease check spotinst_ocean_ecs_create_log.txt for more information")
    sys.exit()
