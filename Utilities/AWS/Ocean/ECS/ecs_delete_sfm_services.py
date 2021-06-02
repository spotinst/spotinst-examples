###############
## Delete all services that start with "sfm"
## NOTE: Please use at your own discrection. Not responsible for any damage or accidental deletion of AWS infrastructure.
###############

### Parameters ###
cluster=''
region=''
###################

import boto3, time

client = boto3.client('ecs', region_name = region)
services = client.list_services(cluster=cluster,maxResults=100)

print('---------------------')

service_names=[]

for i in services['serviceArns']:
	service_names.append(i.split('/', 1)[1])

for j in service_names:
	if(j.startswith('sfm')):
		client.update_service(cluster=cluster,service=j,desiredCount=0)
		time.sleep(5)
		client.delete_service(cluster=cluster,service=j)
		print("Deleting service: "+j)
	else:
		pass

