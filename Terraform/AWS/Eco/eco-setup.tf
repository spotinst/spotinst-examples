#################
### Variables ###
#################

variable "is_admin" {
  type = bool
  default = true
  description = "If True, Eco Admin policy is applied to the role. If False, Eco Read Only policy is applied to the role."
}

variable "bucket_name" {
  type        = string
  description = "The name of the s3 bucket, must be lowercase and alphanumeric"
}

variable "role_name" {
  type        = string
  description = "IAM Role name for Spot FinOps Eco role"
  default     = "Spot-Eco-FinOps"
}

variable "readonly_policy" {
    type = string
    default = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "es:ListElasticsearchInstanceTypes",
                "es:DescribeReservedElasticsearchInstanceOfferings",
                "es:DescribeReservedElasticsearchInstances"
            ],
            "Resource": [
                "*"
            ],
            "Effect": "Allow",
            "Sid": "ReadOnlyElasticSearch"
        },
        {
            "Action": [
                "rds:DescribeReservedDBInstances",
                "rds:DescribeDBInstances",
                "rds:DescribeReservedDBInstancesOfferings"
            ],
            "Resource": [
                "*"
            ],
            "Effect": "Allow",
            "Sid": "ReadOnlyRDS"
        },
        {
            "Action": [
                "redshift:DescribeReservedNodeOfferings",
                "redshift:DescribeReservedNodes",
                "redshift:DescribeClusters"
            ],
            "Resource": [
                "*"
            ],
            "Effect": "Allow",
            "Sid": "ReadOnlyRedshift"
        },
        {
            "Action": [
                "elasticache:DescribeReservedCacheNodesOfferings",
                "elasticache:DescribeReservedCacheNodes",
                "elasticache:DescribeCacheClusters"
            ],
            "Resource": [
                "*"
            ],
            "Effect": "Allow",
            "Sid": "ReadOnlyElasticache"
        },
        {
            "Action": [
                "dynamodb:DescribeReservedCapacityOfferings",
                "dynamodb:DescribeReservedCapacity"
            ],
            "Resource": [
              "*"
            ],
            "Effect": "Allow",
            "Sid": "ReadOnlyDynamoDB"
        },
        {
            "Action": [
                "ec2:DescribeHostReservations",
                "ec2:DescribeReservedInstances"
            ],
            "Resource": [
                "*"
            ],
            "Effect": "Allow",
            "Sid": "ReadOnlyRI"
        },
        {
            "Action": [
                "cur:DescribeReportDefinitions",
                "ce:List*",
                "ce:Get*",
                "ce:Describe*",
                "aws-portal:ViewBilling",
                "aws-portal:ViewUsage",
                "savingsplans:get*",
                "savingsplans:describe*",
                "savingsplans:list*"
            ],
            "Resource": [
                "*"
            ],
            "Effect": "Allow",
            "Sid": "BillingPolicy"
        },
        {
            "Action": [
                "s3:GetBucketLocation",
                "s3:ListBucketMultipartUploads",
                "s3:AbortMultipartUpload",
                "s3:ListMultipartUploadParts",
                "s3:PutObject",
                "s3:ListBucket",
                "s3:List*",
                "s3:PutObjectTagging",
                "s3:PutObjectAcl"
            ],
            "Resource": "arn:aws:s3:::sc-customer-*",
            "Effect": "Allow",
            "Sid": "S3SyncPermissions"
        },
        {
            "Action": [
                "s3:ListBucket",
                "s3:ListBucketVersions",
                "s3:ListBucketMultipartUploads",
                "s3:GetBucketLocation"
            ],
            "Resource": [
                "arn:aws:s3:::<Name of Bucket that contains CUR>"
            ],
            "Effect": "Allow",
            "Sid": "S3CURBucket"
        },
        {
            "Action": [
                "s3:get*",
                "s3:List*",
                "s3:Describe*"
            ],
            "Resource": [
                "arn:aws:s3:::<Name of Bucket that contains CUR>/*"
            ],
            "Effect": "Allow",
            "Sid": "S3CURObject"
        }
    ]
}
EOF
}

variable "admin_policy" {
    type = string
    default = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "es:ListElasticsearchInstanceTypes",
        "es:DescribeReservedElasticsearchInstanceOfferings",
        "es:DescribeReservedElasticsearchInstances",
        "es:PurchaseReservedElasticsearchInstanceOffering"
      ],
      "Resource": [
        "*"
      ],
      "Effect": "Allow",
      "Sid": "FullPolicyElasticSearch"
    },
    {
      "Action": [
        "rds:DescribeReservedDBInstances",
        "rds:DescribeDBInstances",
        "rds:DescribeReservedDBInstancesOfferings",
        "rds:PurchaseReservedDBInstancesOffering"
      ],
      "Resource": [
        "*"
      ],
      "Effect": "Allow",
      "Sid": "FullPolicyRDS"
    },
    {
      "Action": [
        "redshift:DescribeReservedNodeOfferings",
        "redshift:DescribeReservedNodes",
        "redshift:DescribeClusters",
        "redshift:PurchaseReservedNodeOffering"
      ],
      "Resource": [
        "*"
      ],
      "Effect": "Allow",
      "Sid": "FullPolicyRedshift"
    },
    {
      "Action": [
        "elasticache:DescribeReservedCacheNodesOfferings",
        "elasticache:DescribeReservedCacheNodes",
        "elasticache:DescribeCacheClusters",
        "elasticache:PurchaseReservedCacheNodesOffering"
      ],
      "Resource": [
        "*"
      ],
      "Effect": "Allow",
      "Sid": "FullPolicyElasticache"
    },
    {
      "Action": [
        "dynamodb:DescribeReservedCapacityOfferings",
        "dynamodb:DescribeReservedCapacity",
        "dynamodb:PurchaseReservedCapacityOfferings"
      ],
      "Resource": [
        "*"
      ],
      "Effect": "Allow",
      "Sid": "FullPolicyDynamoDB"
    },
    {
      "Action": [
        "ec2:Describe*",
        "ec2:List*",
        "ec2:GetHostReservationPurchasePreview",
        "ec2:GetReservedInstancesExchangeQuote",
        "ec2:ModifyReservedInstances",
        "ec2:AcceptReservedInstancesExchangeQuote",
        "ec2:CancelReservedInstancesListing",
        "ec2:CreateReservedInstancesListing",
        "ec2:PurchaseHostReservation",
        "ec2:PurchaseReservedInstancesOffering",
        "ec2:PurchaseScheduledInstances"
      ],
      "Resource": [
        "*"
      ],
      "Effect": "Allow",
      "Sid": "FullPolicyEC2"
    },
    {
      "Action": [
        "cur:DescribeReportDefinitions",
        "cur:PutReportDefinition",
        "cur:ModifyReportDefinition",
        "ce:List*",
        "ce:Get*",
        "ce:Describe*",
        "aws-portal:ViewBilling",
        "aws-portal:ViewUsage",
        "savingsplans:list*",
        "savingsplans:Describe*",
        "savingsplans:CreateSavingsPlan",
        "organizations:List*",
        "organizations:DescribeOrganization",
        "servicequotas:List*",
        "servicequotas:Get*",
        "support:*"
      ],
      "Resource": [
        "*"
      ],
      "Effect": "Allow",
      "Sid": "FullPolicy"
    },
    {
      "Action": [
        "iam:CreateServiceLinkedRole",
        "iam:PutRolePolicy"
      ],
      "Resource": "arn:aws:iam::*:role/aws-service-role/elasticache.amazonaws.com/AWSServiceRoleForElastiCache*",
      "Condition": {"StringLike": {"iam:AWSServiceName": "elasticache.amazonaws.com"}},
      "Effect": "Allow",
      "Sid": "CreateServiceLinkedRole"
    },
    {
      "Action": [
        "s3:GetBucketLocation",
        "s3:ListBucketMultipartUploads",
        "s3:AbortMultipartUpload",
        "s3:ListMultipartUploadParts",
        "s3:PutObject",
        "s3:ListBucket",
        "s3:List*",
        "s3:PutObjectTagging",
        "s3:PutObjectAcl"
      ],
      "Resource": "arn:aws:s3:::sc-customer-*",
      "Effect": "Allow",
      "Sid": "S3SyncPermissions"
    },
    {
      "Action": [
        "s3:ListBucket",
        "s3:ListBucketVersions",
        "s3:ListBucketMultipartUploads",
        "s3:GetBucketLocation"
      ],
      "Resource": [
        "arn:aws:s3:::<Name of Bucket that contains CUR>"
      ],
      "Effect": "Allow",
      "Sid": "S3CURBucket"
    },
    {
      "Action": [
        "s3:get*",
        "s3:List*",
        "s3:Describe*"
      ],
      "Resource": [
        "arn:aws:s3:::<Name of Bucket that contains CUR>/*"
      ],
      "Effect": "Allow",
      "Sid": "S3CURObject"
    }
  ]
}
EOF
}

#############################
### Cost and Usage Report ###
#############################

resource "aws_cur_report_definition" "spot_io_cur_report" {
  report_name                = "spot-io-cur"
  time_unit                  = "HOURLY"
  format                     = "Parquet"
  compression                = "Parquet"
  s3_prefix                  = "spot-io-cur"
  additional_schema_elements = ["RESOURCES"]
  s3_bucket                  = aws_s3_bucket.spot_io_cur_report.id
  s3_region                  = "us-east-1"
  additional_artifacts       = ["ATHENA"]
  report_versioning          = "OVERWRITE_REPORT"
}

########
## S3 ##
########

resource "aws_s3_bucket" "spot_io_cur_report" {
  bucket = var.bucket_name
  tags = {
    environment = "prod"
    service     = "spot-io"
    terraform   = "true"
    role        = "eco"
  }
}

resource "aws_s3_bucket_policy" "spot_io_cur_report" {
  bucket = aws_s3_bucket.spot_io_cur_report.id

  policy = <<POLICY
{
  "Version": "2008-10-17",
  "Id": "Policy1335892530063",
  "Statement": [
    {
      "Sid": "Stmt1335892150622",
      "Effect": "Allow",
      "Principal": {
        "Service": "billingreports.amazonaws.com"
      },
      "Action": [
        "s3:GetBucketAcl",
        "s3:GetBucketPolicy"
      ],
      "Resource": "arn:aws:s3:::${var.bucket_name}"
    },
    {
      "Sid": "Stmt1335892526596",
      "Effect": "Allow",
      "Principal": {
        "Service": "billingreports.amazonaws.com"
      },
      "Action": [
        "s3:PutObject"
      ],
      "Resource": "arn:aws:s3:::${var.bucket_name}/*"
    }
  ]
}
POLICY
}

############
# IAM Role #
############

resource "aws_iam_role" "spot_io" {
  name               = var.role_name
  description        = "Spot role with full billing admin access"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.spot_io.json

  tags = {
        environment = "prod"
        role        = "eco"
        service     = "spot"
        terraform   = "true"
  }
}

data "aws_iam_policy_document" "spot_io" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = [
        "arn:aws:iam::884866656237:root",
        "arn:aws:iam::627743545735:root"
      ]
    }
  }
}

################
# IAM Policies #
################

# Admin iam policy for spot-io-management role
resource "aws_iam_policy" "spot_io_eco_management" {
  name        = "spot-io-eco-policy"
  description = "For use with spot-io verified role with Eco full permission"

  tags = {
    service     = "spot"
    environment = "prod"
    role        = "eco"
    terraformed = "true"
  }

  policy = var.is_admin ? var.admin_policy : var.readonly_policy
}

##########################
# IAM Policy Attachments #
##########################

resource "aws_iam_role_policy_attachment" "spot_io_billing" {
  role       = aws_iam_role.spot_io.name
  policy_arn = "arn:aws:iam::aws:policy/job-function/Billing"
}

resource "aws_iam_role_policy_attachment" "spot_io_AWSCloudFormationReadOnlyAccess" {
  role       = aws_iam_role.spot_io.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCloudFormationReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "spot_io_AmazonEC2ReadOnlyAccess" {
  role       = aws_iam_role.spot_io.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "spot_io_ServiceQuotasFullAccess" {
  role       = aws_iam_role.spot_io.name
  policy_arn = "arn:aws:iam::aws:policy/ServiceQuotasFullAccess"
}

resource "aws_iam_role_policy_attachment" "spot_io_iam_policy" {
  role       = aws_iam_role.spot_io.name
  policy_arn = aws_iam_policy.spot_io_eco_management.arn
}

###########
# Outputs #
###########

output "bucket_name" {
  value = aws_s3_bucket.spot_io_cur_report.bucket
}

output "aws_iam_role" {
  value = aws_iam_role.spot_io.arn
}