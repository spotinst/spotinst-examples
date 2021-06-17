#########################################
##  Written by steven.feltner@spot.io
## Script to update the desiredCount (# of tasks) for all services
# Example usage: 'ecs_update_service_desiredCount.py -c <Cluster> -r <region> -d <desiredcount> -o <ALL|SFM>'
###

import getopt
import sys
import boto3
from botocore.exceptions import ClientError
from botocore.exceptions import ProfileNotFound

### Variables ###
# AWS Profile Name (Optional)
profile_name = ""
###################


def main(argv):
    try:
        opts, args = getopt.getopt(argv, "hc:r:d:o")
    except getopt.GetoptError:
        print('ecs_update_service_desiredCount.py -c <Cluster> -r <region> -d <desiredcount> -o <ALL|SFM>')
        sys.exit(2)
    for opt, arg in opts:
        if opt == '-h':
            print(
                'ecs_update_service_desiredCount.py -c <Cluster> -r <region> -d <desiredcount> -o <ALL|SFM> \n -o Options: \n \t ALL - Update all services \n \t SFM - Only Update services that start with "SFM"')
            sys.exit()
        elif opt in ("-c"):
            cluster = arg
        elif opt in ("-r"):
            region = arg
        elif opt in ("-d"):
            desiredCount = int(arg)
        elif opt in ("-o"):
            option = arg

    try:
        session = boto3.session.Session(profile_name=profile_name)
        client = session.client('ecs', region_name=region)
    except ProfileNotFound as e:
        print(e)
        print("Trying without profile...")
        client = boto3.client('ecs', region_name=region)

    services = client.list_services(cluster=cluster, maxResults=100)

    print('---------------------')

    service_names = []

    for i in services['serviceArns']:
        service_names.append(i.split('/', 1)[1])

    for j in service_names:
        if option == "SFM":
            if j.startswith('sfm'):
                client.update_service(cluster=cluster, service=j, desiredCount=desiredCount)
                print("Updated service: " + j + " to a desired count of: " + str(desiredCount))
            else:
                pass
        else:
            client.update_service(cluster=cluster, service=j, desiredCount=desiredCount)
            print("Updated service: " + j + " to a desired count of: " + str(desiredCount))


if __name__ == "__main__":
    main(sys.argv[1:])
