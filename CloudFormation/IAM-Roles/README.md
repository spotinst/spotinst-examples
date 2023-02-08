# Cloudformation - IAM Roles

This repository contains examples and complete CloudFormation templates for installing the Spot IAM role.

> **_NOTE:_**  All templates are located in us-east-1, please be sure to run in that region or download to create stack in different region.    
> 
## AWS - Elastigroup / Ocean:
### Stacks:
#### ReadOnly: 
```
https://spot-connect-account-cf.s3.amazonaws.com/Spot-AWS-ReadOnly.yaml
```
#### Full Permission:
```
https://spot-connect-account-cf.s3.amazonaws.com/Spot-AWS-FullPermission.yaml
```

### Stacksets:
If interested in connected all accounts within the AWS organization: [documentation](https://github.com/spotinst/spotinst-examples/blob/master/Utilities/AWS/StackSet/README.md)


## AWS - Eco:
### Standard Policies
#### ReadOnly:
```
https://spot-iam-permissions.s3.amazonaws.com/finops-iam-role-stack.template.json
```
#### Full Permission:
```
https://spot-iam-permissions.s3.amazonaws.com/finops-iam-role-stack-full-ri-management.template.json
```
### Restrictive Policies
#### Restrictive ReadOnly:
```
https://spot-connect-account-cf.s3.amazonaws.com/spot-iam-finopsrole-stack-restricted-read-only.json
```
#### Restrictive Full EC2 Only Permission:
```
https://spot-connect-account-cf.s3.amazonaws.com/spot-iam-finopsrole-stack-restricted-full-permissions-all-services.json
```
#### Restrictive Full Permission:
```
https://spot-connect-account-cf.s3.amazonaws.com/spot-iam-finopsrole-stack-restricted-full-permissions-ec2-only.json
```




