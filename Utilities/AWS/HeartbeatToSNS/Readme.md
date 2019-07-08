# Heartbeat To SNS

This is a python script that reads a message that you will specify as a parameter from the Elastigroup Log and send SNS message. 

Parameters to specify:


* groupId = The Elstigrop id - oesg-123 or sig-123
* token = Spotinst token -  '1234abc'
* account = The account id - act-123456
* arnTopicSNS = The ARN topic name - arn:aws:sns:us-west-2:123345:Test
* interval = The time frame of secounds to take from the elstilog
* message = The massage to filter
