from constructs import Construct
from lib.util.manifest_reader import *
from aws_cdk import Stack
from aws_cdk import aws_eks as eks
from aws_cdk import aws_ec2 as ec2
from aws_cdk import aws_iam as iam
from aws_cdk import CustomResource

class CdkOceanStack(Stack):

    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)

        """
        Variables:
        - token_id: str - The Spotinst API token.
        - account_id: str - The Spotinst account ID.
        - cluster_name_1: str - The name of the EKS cluster.
        - region: str - The AWS region where the cluster will be deployed.
        - vpc_id: str - The ID of the existing VPC.
        - subnetIds: List[str] - The list of subnet IDs for the VPC.
        - imageId: str - The AMI ID for the worker nodes.
        """

        # variables
        token_id = 'your_spotinst_api_token'
        account_id = 'your_spotinst_account_id'
        cluster_name = 'your_cluster_name'
        region = 'your_aws_region'
        vpc_id = 'your_vpc_id'
        subnetIds = ['your_subnet_id_1', 'your_subnet_id_2', 'your_subnet_id_3', 'your_subnet_id_4']
        imageId = 'your_ami_id'

        # get existing vpc attributes
        vpc = ec2.Vpc.from_lookup(self, "VPC",
            vpc_id = vpc_id
        )

        # provisiong a cluster for cluster_name
        cluster = eks.Cluster(self, "eks clusters",
            version=eks.KubernetesVersion.V1_25,
            cluster_name = cluster_name,
            vpc = vpc,
            default_capacity = 0
        )

        # get eks cluster security gruop, will be used in vng
        securityGroupIds = [cluster.cluster_security_group_id]

        # create node IAM role
        node_iam_role = iam.Role(self, 'node_iam_role',
            role_name = f'{cluster_name}_node_iam_role',
            description = 'Deployed from the CDK',
            assumed_by = iam.ServicePrincipal('ec2.amazonaws.com'),
        )

        # add node IAM role to eks config map
        cluster.aws_auth.add_role_mapping(role=node_iam_role, groups=["system:bootstrappers", "system:nodes"], username= "system:node:{{EC2PrivateDNSName}}")

        # add aws managed policies to IAM role
        AmazonEKSWorkerNodePolicy = iam.ManagedPolicy.from_aws_managed_policy_name('AmazonEKSWorkerNodePolicy')
        node_iam_role.add_managed_policy(AmazonEKSWorkerNodePolicy)
        AmazonEKS_CNI_Policy = iam.ManagedPolicy.from_aws_managed_policy_name('AmazonEKS_CNI_Policy')
        node_iam_role.add_managed_policy(AmazonEKS_CNI_Policy)
        AmazonEC2ContainerRegistryReadOnly = iam.ManagedPolicy.from_aws_managed_policy_name('AmazonEC2ContainerRegistryReadOnly')
        node_iam_role.add_managed_policy(AmazonEC2ContainerRegistryReadOnly)

        # create instance profile for VNG
        node_instance_profile = iam.CfnInstanceProfile(self, "node_instance_profile",
            instance_profile_name = f'{cluster_name}_node_iam_role',
            roles = [node_iam_role.role_name]
        )

        # create Ocean cluster
        ocean = CustomResource(self, "Ocean", 
            service_token = f"arn:aws:lambda:{region}:178579023202:function:spotinst-cloudformation",
            resource_type = "Custom::ocean",
            properties = { 
                "accessToken": token_id,
                "accountId": account_id,
                "autoTag": True,
                "updatePolicy": {
                "shouldUpdateTargetCapacity": False
                },
                "ocean": {
                    "name": cluster_name,
                    "controllerClusterId": cluster_name,
                    "region": region,
                    "compute": {
                        "subnetIds": subnetIds,
                        "launchSpecification": {
                            "securityGroupIds": securityGroupIds,
                            "imageId": imageId,
                            "iamInstanceProfile": { "arn": node_instance_profile.attr_arn }, 
                            "tags": [
                                {
                                "tagKey": "Name",
                                "tagValue": f"{cluster_name}-ocean-node"
                                },
                                {
                                "tagKey": f"kubernetes.io/cluster/{cluster_name}",
                                "tagValue": "owned"
                                },
                                {
                                "tagKey": "creator",
                                "tagValue": "josh.lee"
                                },
                                {
                                "tagKey": "protected",
                                "tagValue": "weekend"
                                }
                            ],
                            "userData": {
                                "Fn::Base64": {
                                "Fn::Join": ["", [
                                        "#!/bin/bash\n",
                                        "set -o xtrace\n",
                                        f"/etc/eks/bootstrap.sh {cluster_name}"
                                        ]
                                    ]
                                }
                            }
                        }
                    }
                }
            }
        )

        # install ocean controller
        cluster.add_helm_chart("spot_controller",
            chart = "spotinst-kubernetes-cluster-controller",
            repository = "https://spotinst.github.io/spotinst-kubernetes-helm-charts",
            namespace = "kube-system",
            values = load_yaml_replace_var_local('../../controller/values.yaml',
                fields={
                    '{{token_id}}': token_id,
                    '{{account_id}}': account_id,
                    '{{cluster_name}}': cluster_name,
                }
            )
        )
