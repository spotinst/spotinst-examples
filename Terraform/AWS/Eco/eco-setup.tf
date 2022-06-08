########
## S3 ##
########

variable "bucket_name" {
  type        = string
  description = "The name of the s3 bucket, must be lowercase and alphanumeric"
}

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

############
# IAM Role #
############

variable "role_name" {
  type        = string
  description = "IAM Role name for Spot FinOps Eco role"
  default     = "Spot-Eco-FinOps"
}

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

# iam policy for spot-io-management role
resource "aws_iam_policy" "spot_io_management" {
  name        = "spot-io-management"
  description = "For use with spot-io verified role with Eco full permission"

  tags = {
    service     = "spot"
    environment = "prod"
    role        = "eco"
    terraformed = "true"
  }

  policy = <<EOF
{
          "Version": "2012-10-17",
          "Statement": [
            {
              "Sid": "FullPolicy",
              "Effect": "Allow",
              "Action": [
                "cloudformation:DescribeStacks",
                "cloudformation:GetStackPolicy",
                "cloudformation:GetTemplate",
                "cloudformation:ListStackResources",
                "dynamodb:List*",
                "dynamodb:Describe*",
                "ec2:Describe*",
                "ec2:List*",
                "ec2:GetHostReservationPurchasePreview",
                "ec2:GetReservedInstancesExchangeQuote",
                "elasticache:List*",
                "elasticache:Describe*",
                "elasticache:PurchaseReservedCacheNodesOffering",
                "savingsplans:*",
                "cur:*",
                "ce:*",
                "rds:Describe*",
                "rds:List*",
                "rds:PurchaseReservedDBInstancesOffering",
                "redshift:Describe*",
                "redshift:PurchaseReservedNodeOffering",
                "trustedadvisor:*",
                "support:*",
                "ec2:ModifyReservedInstances",
                "ec2:AcceptReservedInstancesExchangeQuote",
                "ec2:CancelReservedInstancesListing",
                "ec2:CreateReservedInstancesListing",
                "ec2:PurchaseHostReservation",
                "ec2:PurchaseReservedInstancesOffering",
                "ec2:PurchaseScheduledInstances",
                "organizations:List*",
                "organizations:Describe*",
                "es:List*",
                "es:Describe*",
                "es:PurchaseReservedElasticsearchInstanceOffering",
                "organizations:InviteAccountToOrganization",
                "organizations:CancelHandshake"
              ],
              "Resource": [
                "*"
              ]
            },
            {
              "Sid": "S3SyncPermissions",
              "Effect": "Allow",
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
              "Resource": "arn:aws:s3:::sc-customer-*"
            },
            {
              "Sid": "S3BillingDBR",
              "Effect": "Allow",
              "Action": [
                "s3:GetBucketLocation",
                "s3:ListBucket",
                "s3:GetObject",
                "s3:GetObjectAcl"
              ],
              "Resource": ["arn:aws:s3:::${var.bucket_name}","arn:aws:s3:::${var.bucket_name}/*"]
            }
          ]
        }
EOF
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

resource "aws_iam_role_policy_attachment" "spot_io_management" {
  role       = aws_iam_role.spot_io.name
  policy_arn = aws_iam_policy.spot_io_management.arn
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