#!/usr/bin/env python3
# coding: utf-8

import requests
import boto3
import json


# This script will resume \ puase \ recycle stateful instances by tag
# account_id -> insert the account id
# token      -> Generated token from spotinst
# tagKey     -> The tag key to filter 
# tagValue   -> The Value of the tag to filter
# action     -> resume \ pause \ recycle


# Parameters
account_id = ""
token = ""
tagKey = ""
tagValue = ""
action = ""

# Getting all elstigroups
print('Getting all elastigroups')

headers = {'Authorization': 'Bearer ' + token}
url = 'https://api.spotinst.io/aws/ec2/group?accountId=' + account_id

# Getting all elastigroup
allGroups = requests.get(url, headers=headers).json()["response"]["items"]

for group in allGroups:
    print('Group - ' + group["id"])
    url = 'https://api.spotinst.io/aws/ec2/group/' + group["id"] + '/statefulInstance?accountId=' + account_id
    response = requests.get(url, headers=headers)
    statefulInstances = response.json()["response"]

    # If group has stateful instance
    if (statefulInstances["count"] > 0):
        print('Group is stateful')

        # Getting the lanspec of the group
        url = 'https://api.spotinst.io/aws/ec2/group/' + group["id"] + '?accountId=' + account_id
        response = requests.get(url, headers=headers)
        lanspec = response.json()["response"]["items"][0]["compute"]["launchSpecification"]
        
        # If there is tags on 
        if lanspec.get("tags") is not None:
            for tag in lanspec["tags"]:
                print('Group tag - ' + tag["tagKey"] + " = " + tag["tagValue"])

                # If the tag matches recycle
                if (tag["tagKey"] == tagKey) and (tag["tagValue"] == tagValue):
                        for stateful in statefulInstances["items"]:
                            print('instance stateful id - ' + stateful["id"] + " " + action)
                            url = "https://api.spotinst.io/aws/ec2/group/" + group["id"] + "/statefulInstance/" + stateful["id"] + "/" + action + "?accountId=" + account_id
                            response = requests.put(url, headers=headers)
