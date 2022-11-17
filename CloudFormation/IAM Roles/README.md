# Cloudformation - IAM Roles

This repository contains examples and complete CloudFormation templates for installing the Spot IAM role.

## AWS - Elastigroup / Ocean:
### Stacks:
#### ReadOnly: 
```
  https://spot-connect-account-cf.s3.amazonaws.com/Spot-AWS-ReadOnly.yaml
```
#### Full Permission:
```
  https://spot-connect-account-cf.s3.amazonaws.com/Spot-AWS.yaml
```

### Stacksets:
If interested in connected all accounts within the AWS organization: [documentation](/spotinst-examples/Utilities/AWS/StackSet/README.md)

## AWS - Eco:
#### ReadOnly:
```
  https://spot-connect-account-cf.s3.amazonaws.com/spot-iam-finopsrole-stack-restricted-read-only.json
```
#### Full Permission:
```
  https://spot-connect-account-cf.s3.amazonaws.com/spot-iam-finopsrole-stack-restricted-full-permissions-all-services.json
```