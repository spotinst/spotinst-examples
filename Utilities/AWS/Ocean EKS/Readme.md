This Cloudformation template will Create an EKS cluster using exsiting VPC and Subnets, After the EKS creation the CFN will create Ocean cluster.

Parameters to fill:

Parameters:

* AccessToken - Provide Spotinst API Token
* AccountID - Provide Spotinst Account ID
* KeyName - The EC2 Key Pair to allow SSH access to the instances
* ResourceLimitsCPU - Maximun Amount of CPU cores in the Cluster
* ResourceLimitsMemory - Maximun Amount of Memory (Gib) in the Cluster
* AMIID - AMI id for the node instances (Latest can be found here https://docs.aws.amazon.com/eks/latest/userguide/getting-started.html#eks-launch-workers)
* OceanName - Provide a Name for the Elastigroup
* VPC - The VPC for Ocean
* SubnetIds - The subnet IDs for the cluster (must be from the selected VPC).
* EKSClusterName - Name for EKS Cluster
* EKSVersion - Kubernetes Cluster Version
* EKSRole - Name for EKS Cluster Plane IAM Role (A-Z,a-z,_,-)
* BootstrapArguments - User data script
