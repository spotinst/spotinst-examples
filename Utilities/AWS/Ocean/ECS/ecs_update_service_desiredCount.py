###
## Script to update the desiredCount (# of tasks) for all services
# Example usage: 'ecs_update_service_desiredCount.py -c <Cluster> -r <region> -d <desiredcount> -o <ALL|SFM>'
###

import boto3
import getopt
import sys


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

    client = boto3.client('ecs', region_name=region)

    services = client.list_services(cluster=cluster, maxResults=100)

    print('---------------------')

    serivce_names = []

    for i in services['serviceArns']:
        serivce_names.append(i.split('/', 1)[1])

    for j in serivce_names:
        if (option == "SFM"):
            if (j.startswith('sfm')):
                client.update_service(cluster=cluster, service=j, desiredCount=desiredCount)
                print("Updated service: " + j + " to a desired count of: " + str(desiredCount))
            else:
                pass
        else:
            client.update_service(cluster=cluster, service=j, desiredCount=desiredCount)
            print("Updated service: " + j + " to a desired count of: " + str(desiredCount))


if __name__ == "__main__":
    main(sys.argv[1:])
