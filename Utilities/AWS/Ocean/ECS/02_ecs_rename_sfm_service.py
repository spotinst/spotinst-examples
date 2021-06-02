#########################################
##  Written by Steven.Feltner@spot.io      
## This script should be ran after a spotinst ECS service import
## The script will look for any migrated (fargate -> EC2) services starting with "sfm" and do the following:
## 1) Scale Original Fargate service to zero
## 2) Delete Original Fargate service
## 3) Copy configs of migrated EC2 service task definition
## 4) Create new EC2 service with same name as Orginal Fargate service
## 5) Scale Migrated "sfm" service to zero
## 6) Delete migrated "sfm" service
## NOTE: Please use at your own discrection. Not responsible for any damage or accidental deletion of AWS infrastructure.


### Parameters ###
cluster=''
region=''
####################


import boto3
import time

def divide_chunks(l, n):    
    for i in range(0, len(l), n):  
        yield l[i:i + n]

client = boto3.client('ecs', region_name = region)

#Retrieve all the services for the cluster in question
services = client.list_services(cluster=cluster,maxResults=100)

print('---------------------')

#Orginal service Names
service_names=[]
#Migrated service Names
service_list=[]

for i in services['serviceArns']:
	service_names.append(i.split('/', 1)[1])

#Only get services that start with "sfm"
for j in service_names:
    print(j)
    if(j.startswith('sfm')):
        response = client.describe_services(cluster=cluster,services=[j])
        current_runningCount = response['services'][0]['runningCount']
        if(current_runningCount == 0):
            print("SKIPPING - service " + j + "is not running")
        else:
            service_list.append(j)
    else:
        pass

#Get the service names for the migrated services. Convert back to orginal name
service_names=[]
for i in service_list:
	temp=i.split('-',1)
	service=temp[1]
	service_names.append(service)

#for i in range(len(task))

#delete orginal fargate services
for i in range(len(service_names)):
	print("Updating orginal Fargate service to Zero: "+service_names[i])	
	try:
		client.update_service(cluster=cluster,service=service_names[i],desiredCount=0)
		task=client.list_tasks(cluster=cluster,serviceName=service_names[i])
		for x in task['taskArns']:
			task_name=(x.split('/', 1)[1])
			print("Stopping task: "+task_name)
			client.stop_task(cluster=cluster,task=task_name)
	except:
		print("Service does not exist or already at zero")

	print("Deleting orginal Fargate service: "+service_names[i])
	try:
		client.delete_service(cluster=cluster,service=service_names[i])
	except:
		print("Service does not exist or can not be deleted")

#wait for the services to be deleted before creating new ones with the same name
time.sleep(60)

#describe the services from the cluster with a max of 10 at a time
#divide the list into chuncks of 1
n=1
x = list(divide_chunks(service_list, n)) 

#Get the configurations from the migrated services and create new service with corrected/original name
for i in range(len(x)):
	services = client.describe_services(cluster=cluster,services=x[i])
	temp = services.get('services')
	dict = temp[0]
	print("Creating EC2 Service: "+service_names[i])
	try:
		client.create_service(cluster=cluster,serviceName=service_names[i],taskDefinition=dict.get('taskDefinition'),loadBalancers=dict.get('loadBalancers'),serviceRegistries=dict.get('serviceRegistries'),desiredCount=dict.get('desiredCount'),launchType=dict.get('launchType'),deploymentConfiguration=dict.get('deploymentConfiguration'),placementConstraints=dict.get('placementConstraints'),placementStrategy=dict.get('placementStrategy'),networkConfiguration=dict.get('networkConfiguration'),schedulingStrategy=dict.get('schedulingStrategy'))
	except:
		print("Unable to create service")

#delete Migrated EC2 services with sfm
for i in range(len(service_list)):
	print("Deleting Migrated Sig Service: "+service_list[i])
	try:
		client.update_service(cluster=cluster,service=service_list[i],desiredCount=0)
	except:
		print("Service does not exist or already at zero")
	try:
		client.delete_service(cluster=cluster,service=service_list[i])
	except:
		print("Service does not exist or can not be deleted")

print("Completed")
print('---------------------')


