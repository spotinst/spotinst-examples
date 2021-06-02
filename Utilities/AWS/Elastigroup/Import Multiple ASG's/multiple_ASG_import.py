#!/usr/bin/env python
# coding: utf-8

#This script imports multiple ASG's from a file, it requires an account id, a token and a file to import from


__author__ = "Spotinst SA Team"
__email__ = "sales@spotinst.com"
__status__ = "Production"

import requests

print("-------- Hello from Spotinst SA Team! --------\n\nThe following script will help you migrate multiple Auto Scaling Groups to Elastigroup. You will need to provide it with your Account ID (act-xxxxxxxx), a temporary / permanent security token and a file path.")
print("\nThe file format should be in the form of:\nasg_name;region\nasg_name;region\nasg_name;region")
print("--------> Important to note to use NO spaces between the ';'<--------\n")
account_id = input("Please provide your account ID: ")
token = input("Please provide a permanent or temporary access token: ")
filename = input("Please provide a csv file path & name: ")
f = open(filename, "r")
content = f.read()
lines = content.split("\n")
log_file = open("multiple_asg_import_log.txt","w+")
count = 0
for line in lines:
    if line=="":
        break
    columns = line.split(";")
    asg_name = columns[0]
    region = columns[1]
    print('Importing ASG:',asg_name,'In region:', region)
    headers = {'Authorization': 'Bearer ' + token}
    url = 'https://api.spotinst.io/aws/ec2/group/autoScalingGroup/import'
    data = {'region': region, 'accountId': account_id, 'autoScalingGroupName': asg_name, 'dryRun': 'false'}
    r = requests.post(url, params=data, headers =headers)
    r_text = str(r.text)
    log_file = open("multiple_asg_import_log.txt","a+")
    log_file.write(r_text)
    if r.status_code == 200:
        print("Import of group:",asg_name, "completed succesfully!\n")
        count = count + 1
    else:
        print ("Import of group:", asg_name,"failed with status code:",r.status_code,"\n")
        
print ("Succesfuly imported",count,"of",len(lines)-1, "Auto Scaling Groups, for more information see multiple_asg_import_log.txt")    
