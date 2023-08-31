# Cloudformation - IAM Roles

This repository contains examples and complete CloudFormation templates for installing the Spot IAM role.

> **_NOTE:_**  All templates are located in us-east-1, please be sure to run in that region or download to create stack in different region.
>

## AWS - Eco:
### Read-Only
#### Restrictive ReadOnly:
```
https://spot-connect-account-cf.s3.amazonaws.com/spot-iam-finopsrole-stack-restricted-read-only.json
```
#### Restrictive ReadOnly with CUR creation:
```
https://spot-connect-account-cf.s3.amazonaws.com/spot-iam-finopsrole-stack-restricted-read-only-with-cur-and-bucket.json
```
#### Restrictive ReadOnly with limited roles for assuming:
```
https://spot-connect-account-cf.s3.amazonaws.com/spot-iam-finopsrole-stack-restricted-read-only-limited-assume.json
```
#### Restrictive ReadOnly with limited roles for assuming and externalID:
```
https://spot-connect-account-cf.s3.amazonaws.com/spot-iam-finopsrole-stack-restricted-read-only-limited-assume-with-externalid.json
```

### Full Permissions
#### Restrictive Full Permissions:
```
https://spot-connect-account-cf.s3.amazonaws.com/spot-iam-finopsrole-stack-restricted-full-permissions-all-services.json
```
#### Restrictive Full Permissions with CUR creation:
```
https://spot-connect-account-cf.s3.amazonaws.com/spot-iam-finopsrole-stack-restricted-full-permissions-all-services-with-cur-and-bucket.json
```
#### Restrictive Full EC2 Only Permission:
```
https://spot-connect-account-cf.s3.amazonaws.com/spot-iam-finopsrole-stack-restricted-full-permissions-ec2-only.json
```
#### Restrictive Full Permission with limited roles for assuming:
```
https://spot-connect-account-cf.s3.amazonaws.com/spot-iam-finopsrole-stack-restricted-full-permissions-all-services-limited-assume.json
```
