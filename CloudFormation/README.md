# Overview
Using the master template will allow you to select whether you want a full analysis or only an eco one, as well giving you the opportunity to create the FinOps role and/or the Elastigroup/Ocean role in full permission or read only format.

## Pre-req:

1. User with access to the Master Payer account. User will need at **least** the following permission:
    A. Create/run CF templates.  
    B. Create IAM Policy/Role.  
    C. Read-only permissions to AWS organization.
2. Enable Trusted Access with AWS Organizations. - [Doc](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/stacksets-orgs-enable-trusted-access.html)
3. Spot API token with admin access to Spot Organization. [Doc](https://docs.spot.io/administration/api/create-api-token)
4. Check the Spot ORG allows adding additional accounts (Contact Spot to enable).
