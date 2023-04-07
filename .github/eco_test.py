import time
import boto3
import boto3.session
import logging
import sys
import random
import string
import os

# Configure the logger
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

json_directory = '../CloudFormation/IAM-Roles/Eco/json'  # replace with your directory path
yaml_directory = '../CloudFormation/IAM-Roles/Eco/yaml'  # replace with your directory path
prefix = 'https://spot-connect-account-cf.s3.amazonaws.com/'  # replace with your desired prefix
file_list = []
file_list_external = []
file_list_linked = []

for filename in os.listdir(json_directory):
    if os.path.isfile(os.path.join(json_directory, filename)):
        if filename != "README.md":
            if 'externalid' in filename:
                file_list_external.append((prefix + filename))
            elif 'linked' in filename:
                file_list_linked.append((prefix + filename))
            else:
                file_list.append(prefix + filename)


# Set up the boto3 session with clients
def session_setup():
    """Setup boto3 session"""
    try:
        session = boto3.session.Session(region_name="us-east-1")
        client = session.client('cloudformation')
    except Exception as e:
        logger.debug(f'Error creating session object:')
        logger.error(e, exc_info=True)
        sys.exit(1)
    else:
        logger.info('Session object created')
    return client


def get_random_string():
    # choose from all lowercase letter
    letters = string.ascii_lowercase
    result_str = ''.join(random.choice(letters) for i in range(8))
    return result_str


def create(client):
    stacks = []
    for x in file_list:
        try:
            response = client.create_stack(
                StackName="Testing-Eco-" + get_random_string(),
                TemplateURL=x,
                Parameters=[
                    {
                        'ParameterKey': 'CostAndUsageBucket',
                        'ParameterValue': 'test-eco-policy'
                    },
                    {
                        'ParameterKey': 'RoleName',
                        'ParameterValue': 'SpotByNetApp_Finops'+get_random_string()
                    },
                    {
                        'ParameterKey': 'PolicyName',
                        'ParameterValue': 'SpotByNetApp_Finops'+get_random_string()
                    }
                ],
                Capabilities=['CAPABILITY_NAMED_IAM']
            )
            stacks.append(response['StackId'].split('/')[1].strip())
            print(response)
        except Exception as e:
            print(e)

    for x in file_list_external:
        try:
            response = client.create_stack(
                StackName="Testing-Eco-" + get_random_string(),
                TemplateURL=x,
                Parameters=[
                    {
                        'ParameterKey': 'CostAndUsageBucket',
                        'ParameterValue': 'test-eco-policy'
                    },
                    {
                        'ParameterKey': 'RoleName',
                        'ParameterValue': 'SpotByNetApp_Finops'+get_random_string()
                    },
                    {
                        'ParameterKey': 'PolicyName',
                        'ParameterValue': 'SpotByNetApp_Finops'+get_random_string()
                    },
                    {
                        'ParameterKey': 'ExternalId',
                        'ParameterValue': '123456789'
                    }
                ],
                Capabilities=['CAPABILITY_NAMED_IAM']
            )
            stacks.append(response['StackId'].split('/')[1].strip())
            print(response)
        except Exception as e:
            print(e)

    for x in file_list_linked:
        try:
            response = client.create_stack(
                StackName="Testing-Eco-" + get_random_string(),
                TemplateURL=x,
                Parameters=[
                    {
                        'ParameterKey': 'RoleName',
                        'ParameterValue': 'SpotByNetApp_Finops'+get_random_string()
                    },
                    {
                        'ParameterKey': 'PolicyName',
                        'ParameterValue': 'SpotByNetApp_Finops'+get_random_string()
                    }
                ],
                Capabilities=['CAPABILITY_NAMED_IAM']
            )
            stacks.append(response['StackId'].split('/')[1].strip())
            print(response)
        except Exception as e:
            print(e)

    return stacks


def destroy(client, stacks):
    for x in stacks:
        try:
            response = client.delete_stack(
                StackName=x
            )
            print(response)
        except Exception as e:
            print(e)
            sys.exit(1)
    return


def main():
    client = session_setup()
    stacks = create(client)
    time.sleep(200)
    destroy(client, stacks)


if __name__ == '__main__':
    sys.exit(main())
