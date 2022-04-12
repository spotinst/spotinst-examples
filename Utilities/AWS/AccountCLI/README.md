# Readme
The following CLI script can be used to do the following:
* Create new Account within Spot.io Platform
* Delete a Spot Account within Spot.io Platform
* Retrieve and generate an External ID for an AWS connection
* Set the cloud credentials (ARN) for an AWS linked account to the Spot.io Account
* Get the Spot Account ID

# Pre-req
Make sure to install the packages from requirements.txt
`pip install -r requirements.txt`

Spot Admin API Token needs to be stored as an environment variable under a variable called `SPOTINST_TOKEN`

# Example Usage
```hcl
python3 spot_aws_connect.py --help
Usage: spot_aws_connect.py [OPTIONS] COMMAND [ARGS]...

Options:
  --help  Show this message and exit.

Commands:
  create                 Create a new Spot Account
  create-external-id     Generate the Spot External ID for Spot Account...
  delete                 Delete a Spot Account
  get                    Retrieve the Spot Account ID.
  set-cloud-credentials  Set AWS ROLE ARN to Spot Account
  ```
  
### Get AccountID:
```hcl
python3 spot_aws_connect.py get --filter=name='AccountName' --attr-account_id
```
  


