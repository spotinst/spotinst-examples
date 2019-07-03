#!/usr/bin/python3
import requests
import boto3
import json
from datetime import datetime, timedelta

# This script monitors Elastilog and sends an SNS alert when the message was matched.
# Paramters example
# groupId = is the elstigrop id - oesg-123 or sig-123
# token = Spotinst token -  '1234abc'
# account = The account id - act-123456
# arnTopicSNS = The arn topic name - arn:aws:sns:us-west-2:123345:Test
# interval = The time frame of secounds to take from the elstilog
# message = The massage to filter


groupId = "oesg-1233"
token = "1234abc"
account = "act-12345"
arnTopicSNS = "arn:aws:sns:us-west-2:123345:Test"
interval = 60
message = "The spotinst cluster controller has not reported a heartbeat to the spotinst API."

# Create an SNS client
sns = boto3.client('sns')

# Convert dates to timestamp
toDate = int(datetime.utcnow().timestamp() * 1000)
beforeDate = int((datetime.utcnow() - timedelta(seconds=interval)).timestamp() * 1000)

# Getting elastilog
headers = {'Authorization': 'Bearer ' + token}
url = 'https://api.spotinst.io/aws/ec2/group/' + groupId + '/logs?fromDate=' + str(beforeDate)  + '&toDate=' +  str(toDate) + '&accountId=' + account
responseMessages = requests.get(url, headers=headers).json()["response"]["items"]

for item in responseMessages:
    if message in item["message"]:
        # Publish a simple message to the specified SNS topic
        sns.publish(
            TopicArn=arnTopicSNS,    
            Message=message,    
        )
        break