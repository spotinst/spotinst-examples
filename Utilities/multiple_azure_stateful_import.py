# This script recieves Spot account_id, Spot token and VM Info filename and imports Stateful VMs as specified in the given file.
# Every line in the file is equal to one VM to import
# The line format should be: statefulnodeName;region;originalVmName;resourceGroupName;odSizes;spotSizes;OS
# OD/Spot VM size list should be written as: InstanceType1,InstanceType2,...
# Example: dev_spot;westus2;dev1;dev-worloads;standard_d2s_v3;standard_d2s_v3,standard_d2s_v4;Linux
# Stateful Import Logs can be found in multiple_stateful_import_log.txt

#!/usr/bin/env python
import requests
import json


# Parameters
account_id = ""
token = ""
filename = ""

# Opening file
f = open(filename, "r")
content = f.read()
lines = content.split("\n")

# Creating log file
log_file = open("multiple_stateful_import_log.txt", "w+")
count = 0

# Running on the lines in the file
for line in lines:
    if line == "":
        break

    # Getting required API inputs from the line
    # Line Format: statefulnodeName;region;originalVmName;resourceGroupName;odSizes;spotSizes;OS
    # Example: prod_db;westus2;prodDB;db-workloads;standard_d2s_v3;standard_d2s_v3,standard_d2s_v4;Windows
    columns = line.split(";")
    name = columns[0]
    region = columns[1]
    originalVmName = columns[2]
    resourceGroupName = columns[3]
    odSizesList = columns[4]
    spotSizesList = columns[5]
    OS = columns[6]
    vmName = columns[2] # To Keep VM name same as Original

    # Fixing OD instance sizes list
    odSizes = odSizesList.split(",")
    # Fixing Spot instance sizes list
    spotSizes = spotSizesList.split(",")

    # Building API Call for Stateful VM Import
    print('Importing Stateful VM:', originalVmName, 'In region:', region)
    headers = {'Authorization': 'Bearer ' + token, 'Content-Type': 'application/json'}
    url = 'https://api.spotinst.io/azure/compute/statefulNode/import?accountId=' + account_id
    payload = json.dumps({"statefulNodeImport":{"resourceGroupName": resourceGroupName,"originalVmName": originalVmName,"node":{"name": name,"region": region,"resourceGroupName": resourceGroupName,"compute":{"os": OS,"vmSizes":{"odSizes": odSizes,"spotSizes": spotSizes},"launchSpecification":{"tags":[{"tagKey":"creator","tagValue":"spot"}],"vmName": originalVmName}},"persistence":{"shouldPersistOsDisk":True,"osDiskPersistenceMode":"reattach","shouldPersistDataDisks":True,"dataDisksPersistenceMode":"reattach","shouldPersistNetwork":True}}}})

    response = requests.request("POST", url, headers=headers, data=payload)
    print(response.text)
    response_text = str(response.text)
    log_file = open("multiple_stateful_import_log.txt", "a+")
    log_file.write(response_text)

    # Printing result for this instance
    if response.status_code == 200:
        print("Import of Stateful Instance:",originalVmName, "completed succesfully!")
        count = count + 1
    else:
        print("Import of Stateful Instance:", originalVmName,"failed with status code:", response.status_code)

print("Succesfuly imported", count, "of", len(lines),"Stateful Instance, for more information see multiple_stateful_import_log.txt")
