###
## Script to update the desiredCount (# of tasks) for all services have less running than desired. 
###

### Parameters ###
cluster=''
desiredCount=0
region=''
###################

import boto3

client = boto3.client('ecs', region_name = region)

services = client.list_services(cluster=cluster,maxResults=100)

print('---------------------')

serivce_names=[]

for i in services['serviceArns']:
   serivce_names.append(i.split('/', 1)[1])

for j in serivce_names:
#if(j.startswith('sfm')):
		response = client.describe_services(cluster=cluster,services=[j])
		#print(response)
		current_desiredCount = response['services'][0]['desiredCount']
		current_runningCount = response['services'][0]['runningCount']
		ServiceName = response['services'][0]['serviceName']
		if(current_runningCount < current_desiredCount):
			print("Services that have more desired than running will now be scaled down...")
			print("ServiceName: " + ServiceName)
			print("desiredCount = " + str(current_desiredCount) + " runningCount = " + str(current_runningCount))
			client.update_service( cluster=cluster, service=j, desiredCount=desiredCount)
			print("Updated service: " + j + " to a desired count of: " + str(desiredCount))
