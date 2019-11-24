##################################################################################################################3
# Cluster name
# Syntax: CLUSTER-NAME=[name of cluster] (string)
# Default:
CLUSTER_NAME=""
######################### AWS Services Configuration ######################################################
# Region in which AWS services should run
# Syntax: AWS-REGION =[region] (string)
# Default:"us-west-2"
AWS_REGION=""
# Subnet of the EKS workers
# Syntax: SUBNET-ID =[subnet id] (string) Example="subnet-0001"
# Default:
SUBNET_ID=[""]
# A security group is a set of firewall rules that control the traffic for your instance
# Syntax: SECURITY-GROUPS =[security group] (string) Example=["sg-001","sg-002"]
# Default:[""]
SECURITY_GROUPS=[""]
# Specify tags to be used for the creation of AWS services
# Syntax: TAGS = [{ key="test" value="test" }]
TAGS=""
###########################################################################################################
######################### Security Configuration ######################################################
# AWS access key
# Syntax: ACCESS-KEY =[access key] (string)
# Default:
ACCESS_KEY=""
# AWS secret key
# Syntax: SECRET-KEY =[access key] (string)
# Default:
SECRET_KEY=""
###########################################################################################################
######################### Launch Configuration ############################################################
# An AMI is a template that contains the software configuration (operating system, application server, and applications) required to launch your instance
# Syntax: AMI-ID =[id] (string) Example="ami-0001"
# Default: AMI-ID = "ami-0abcb9f9190e867ab"
#AMI_ID=""
# A key pair consists of a public key that AWS stores, and a private key file that you store. Together, they allow you to connect to your instance securely
# Syntax: KEY_NAME =[.pem file name] (string)
# Default:
KEY_NAME=""
# VPC in which EC2 instances to be launched
# Syntax: VPC_ID =[id] (string) Example="vpc-001"
# Default:
VPC_ID=""
# Volume size to be used for EC2 instances (root volume)
# Syntax: ROOT_VOL_SIZE =[size] (int)
# Default:"100"
ROOT_VOL_SIZE=""
##########################################################################################################
############################ Spotinst Account Configuration ##########################################
# The Spotinst account id
# Syntax: SPOTINST_ACC="act-12345"
# Default:""
SPOTINST_ACC=""
# The Spotinst token
# Syntax: SPOTINST_TOKEN="abcd"
# Default:""
SPOTINST_TOKEN=""
##################################################################################################################################################################################################################
