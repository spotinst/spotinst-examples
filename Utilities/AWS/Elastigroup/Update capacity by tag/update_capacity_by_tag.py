#!/usr/bin/env python3
# coding: utf-8

import requests
import boto3
import json


# This script will update capacity of group by tag
# account_id -> insert the account id
# token      -> Generated token from spotinst
# tagKey     -> The tag key to filter 
# tagValue   -> The Value of the tag to filter
# target     -> target capacity
# minimum    -> minimum capacity
# maximum    -> maximum capacity

# Parameters
account_id = ""
token = ""
tagKey = ""
tagValue = ""
target = ""
minimum = ""
maximum = ""

# Getting all elstigroups
print('Getting all elastigroups')

headers = {'Authorization': 'Bearer ' + token}
url = 'https://api.spotinst.io/aws/ec2/group?accountId=' + account_id

# Getting all elastigroup
allGroups = requests.get(url, headers=headers).json()["response"]["items"]

for group in allGroups:
    print('Group - ' + group["id"])
    lanspec = group["compute"]["launchSpecification"]
    
    # If there is tags on 
    if lanspec.get("tags") is not None:
        for tag in lanspec["tags"]:
            print('Group tag - ' + tag["tagKey"] + " = " + tag["tagValue"])

            # If the tag matches recycle
            if (tag["tagKey"] == tagKey) and (tag["tagValue"] == tagValue):
                print("Update")
                url = "https://api.spotinst.io/aws/ec2/group/" + group["id"] + "/capacity?accountId=" + account_id
                capacity = {"capacity": {"minimum": minimum,"maximum": maximum,"target":target}}
                response = requests.put(url, headers=headers,json=capacity)