
# Spot.io GCP Cloudshell Bulk Onboarder

This is a Spot.io bulk onboarding cloudshell script that can be ran directly in a GC console terminal. It creates GC roles, service accounts, a Spot.io token per project and will onboard GC projects to the Spot console using the Spot API and gcloud commands. It takes in four parameters; spot acct, spot token, csv list of GCP projects and read-only (bool).

## Prerequisites
* A Spot.io account is required with a provisioned API admin token. See more [here](https://docs.spot.io/administration/api/create-api-token) if you need to setup a token.
* GC Projects must have the Compute Engine API enabled. You can check the status for each project using the following url. https://console.developers.google.com/apis/api/compute.googleapis.com/overview?project=#####insert_project_name######
* A single, comma separated string of GC Projects that need to be onboarded.
* GC Admin access to all target projects and access to the GC cloudshell console

## Limitations and considerations
* There is no rollback feature for this script. Duplicate assets will be generated if the script is run to onboard the same project twice. Any duplicate assets created in GC will need to be cleaned up manually.
* Once the GC read-only Roles have been deployed; this tool cannot upgrade deployed Roles to full permissions down the road.

## Automation Flow
All assets created by the script are on a per project basis for security purposes. Each connected project will have a unique Spot.io token resticted to the matching GC service account within the target project. 

. Iterate through the input list of projects\
.. Create GC Service Account\
... Create and download Service Account Key\
.... Create Spot.io account\
..... Create unique programmatic user API token\
...... Import GC account using Service Account Key, Spot.io Acct number and unique programmatic API user token\
(loop)

## Deployment
To deploy this script run the following shell commands

```bash
  wget URL https://s3-url-tbd/spot_onboarder.sh
  chmod +x spot_onboarder.sh
```

## Script Usage Example
```bash
  
  ./spot_onboarder.sh spot-acct-id apit-token-value csv-list-of-projects true

```

## Input Parameters
* (String) Spot.io account ID - act-00000000
* (String) API token
* (String) CSV list of GC Projects
* (boolean) Read-only Role deployment flag 


