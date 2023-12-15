
# Spot.io GC Cloudshell Bulk Onboarder


Spot.io GC Cloudshell Bulk Onboarder is a bulk GC project import tool that can be ran directly in the GC console terminal. It creates Spot.io required GC roles, service accounts, a Spot.io token per project and will onboard GC projects to the Spot console using the Spot.io API and gcloud commands. 


## Prerequisites
* A Spot.io account is required with a provisioned API admin token. See [here](https://docs.spot.io/administration/api/create-api-token) if you need to setup a token.
* GC Projects must have the Compute Engine API enabled. You can check the status for each project using the following url. https://console.developers.google.com/apis/api/compute.googleapis.com/overview?project=#####insert_project_name######
* A single, comma separated string of GC Projects that need to be onboarded.
* GC Admin access to all target projects and access to the GC cloudshell console

## Limitations and considerations
* There isn't a rollback feature for this script. Duplicate assets will be generated if the script is run more than once to onboard the same project. All duplicate assets created in will need to be cleaned up manually.
* Once the GC read-only Roles have been deployed; this tool cannot upgrade deployed Roles to full permissions down the road.

## Automation Flow
All assets created by the script are on a per project basis for security purposes. Each connected project will have a unique Spot.io token resticted to the matching GC service account within the target project. 

. Iterate through the input list of projects\
.. Create GC Service Account\
... Create and download Service Account Key\
.... Create Spot.io account\
..... Create unique programmatic user API token\
...... Import GC project using the downloaded Service Account Key, Spot.io Acct ID and unique programmatic API user token\
(loop)

## Deployment
To deploy this script run the following shell commands

```bash
  wget https://s3-url-tbd/spot_onboarder.sh
  chmod +x spot_onboarder.sh
```

## Script Usage Example
```bash
  
  ./spot_onboarder.sh spot-acct-id apit-token-value csv-list-of-projects true

```

## Logging
The script will generate a lot of log prints. It would be best if you pipe them to a log file for follow-up analysis. 

```bash
  
  ./spot_onboarder.sh spot-acct-id apit-token-value csv-list-of-projects true >> spot_onboarder.log

```


## Input Parameters
* (String) Spot.io account ID - Example: act-00000000
* (String) API token
* (String) CSV list of GC Projects
* (boolean) Read-only Role deployment flag - Default: false


