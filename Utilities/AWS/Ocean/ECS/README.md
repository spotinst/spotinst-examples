# Importing ECS Fargate into Ocean ECS 

### Pre-req: 
- Spot Organization has been created. If you’re not signed up, create your Spot Organization.
- AWS account linked to a Spot Organization
- Creation of a Spot platform API Token 
- Fargate uses a network mode of: “awsvpc”. In order to assign each task with an ENI you must enable VPCtrunking in your account to allow multiple ENIs to get assigned to a single EC2 instance. Documentation
`aws ecs put-account-setting-default --name awsvpcTrunking --value enabled --region us-west2`
- Use an ECS optimized AMI: Documentation
- Python 3 and pip 3 installed. 


## Part 1: Replicate the Fargate services as EC2 services 
The below script will automatically import and replicate all current running Fargate services in a specified ECS cluster to EC2 services managed by Spot’s ECS integration with Ocean.

The script starts off by parsing through every Fargate-defined security group and will add all existing rules to a new single security group. This is required if you have more than five security groups as only five security groups are permitted to be attached to a single EC2 instance. After the creation of the new security group, a new Ocean ECS cluster will be created in the Spot SaaS platform. Lastly, the script will begin to replicate all Fargate services by creating a new task definition and new EC2 service.

Download `spot_ecs_fargate.py` and `requirements.txt` from: https://github.com/spotinst/spotinst-examples/tree/master/Utilities/AWS/Ocean/ECS

Run:
`pip install –r requirements.txt`
 
 View the help documentation to view all of the required arguments:
`python3 01_ecs_create_ocean_import_fargate.py import-fargate –help`

```hcl
Usage: spot_ecs_fargate.py import-fargate
           [OPTIONS]

  ## The script will gather all services and do the following: ## 1) Describe
  all services within specified ECS cluster ## 2) Gather all SGs for each
  service ## 3) Create new Master SG ## 4) Copy all rules from existing SGS
  into master SG ## 5) Create a Spot Ocean Cluster ## 6) Copy/Import all
  fargate services into EC2 services (This does not remove/delete original
  fargate services) ## NOTE: Please use at your own discretion. Not
  responsible for any damage or accidental deletion of AWS infrastructure.

-a, --account_id=STRING.
Spot Account ID 

-t, --token=STRING 
Spot.io Token 

-e, --ecs_cluster=STRING 
Spot Account ID 

--sg_name=STRING 
Name for the security group that will get created. 

--sg_description=STRING
Description of the newly created security group. 

-r, --region=STRING
Region code (ie. us-west-2) 

-v, --vpc=STRING 
VPC ID 

-s, --subnet_ids=STRING 
List of subnets ids. Syntax ‘[“subnet123456789”,”subnet123456789”]’ 

--iam_instance_role=STRING 
This is the instance profile for the AWS ecsInstanceRole. The instance profile arn EX: arn:aws:iam:123456789:instance-profile/ecsInstanceRole. Documentation 

--ecs_ami=STRING 
ECS Optimized AMI. Can be retrieved here 

--profile=STRING 
AWS Profile Name (Optional) 

--access_key=STRING 
AWS access key (Optional) 

--secret_key=STRING 
AWS secret key (Optional) 

--session_token=STRING 
AWS session token (Optional) 

--help display this help and exit
```

Run the script using:

`python3 py import-fargate [OPTIONS]`

Outputs:

Security Group ID.   
Ocean Cluster ID.   
Migration Status.   

## Part 2 (Optional): Rename the EC2 Services that were replicated and delete the original Fargate services.
The goal is to automatically delete the existing Fargate services and rename the new EC2 services to keep the same naming convention as the original Fargate services. During the import process, a prefix is added to all the imported services because AWS will not allow two services with the same name. This script is optional and not required as one can scale the existing Fargate services to zero and use the newly imported services from part 1.

This process will scale down the original Fargate services to zero and delete them. After deletion, the script will re-create the services with the exact same name but using the new task definition for a launch type of EC2. Once the new services are created, we will delete the migrated services with the prefix so that you will have the same number of services and tasks prior to starting the migration.

View the help documentation to view all the required arguments:

`python3 spot_ecs_fargate.py rename-fargate –help`

Run the script using:

`python3 spot_ecs_fargate.py rename-fargate [OPTIONS]`

Example:

`python3 spot_ecs_fargate.py rename-fargate -e Steven-ECS -r us-west-2`
