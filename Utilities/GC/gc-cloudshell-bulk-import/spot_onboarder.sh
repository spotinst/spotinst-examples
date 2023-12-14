#!/bin/bash

# Function to create a service account and download its key; Create annd connect GCP project to Spot.io account using a programitc user token
# Parameters:
# 1. spot_account_id: The Spot.io account ID. No default value.
# 2. spot_token: The Spot.io token. No default value.
# 3. project_ids: A comma-separated list of project IDs. No default value.
# 4. read_only: A boolean indicating whether the account should be read-only. Defaults to true.
create_service_account() {
    local service_account_name="spot-io-$(openssl rand -hex 4)"
    local spot_role_name="spot_io_Role_$(openssl rand -hex 4)"
    local spot_account_id=$1
    local spot_token=$2
    local project_ids=($(echo $3 | tr "," "\n"))
    local read_only=${4:-true}
    local ROLE_YML="spotinst_service_account_role.yml"
    local ROLE_URI="https://spotinst-public.s3.amazonaws.com/assets/gcp/spotinst-service-role.yaml"
    
    if [ "$read_only" = true ] ; then
        ROLE_URI="https://spot-connect-account-cf.s3.amazonaws.com/spot-gcp-service-role-read-only.yaml"
    fi

    if [ -z "$spot_account_id" ] || [ -z "$spot_token" ]; then
        echo "Spot account ID or token is not provided:"
        echo "Spot Account ID: ${spot_account_id}"
        echo "Spot Token: ${spot_token}"
        exit -1
    fi

    for project_id in "${project_ids[@]}"
    do
        # Downloading spotinst-service-role.yml to local folder
        curl ${ROLE_URI} -o ${ROLE_YML}
        # enable service management API
        gcloud services enable servicemanagement --project ${project_id}
        # create spotinst role from file
        gcloud iam roles create ${spot_role_name} --project ${project_id} --file ${ROLE_YML} -q
        # create spotinst ServiceAccount
        gcloud iam service-accounts create ${service_account_name} --display-name ${service_account_name} --project ${project_id}
        # add  spotinst role to spotinst service account
        gcloud projects add-iam-policy-binding ${project_id} \
            --member serviceAccount:${service_account_name}@${project_id}.iam.gserviceaccount.com \
            --role projects/${project_id}/roles/${spot_role_name} --condition=None
        # add  serviceAccountUser role to spotinst service account
        gcloud projects add-iam-policy-binding ${project_id} \
            --member serviceAccount:${service_account_name}@${project_id}.iam.gserviceaccount.com \
            --role roles/iam.serviceAccountUser --condition=None
        # Create and download key for service account
        gcloud iam service-accounts keys create spotinst_key.json \
            --iam-account ${service_account_name}@${project_id}.iam.gserviceaccount.com --project ${project_id}
        
        # Call Spot.io API to set existing user permissions
        response=$(curl -X POST "https://api.spotinst.io/setup/account" \
            -H "Authorization: Bearer $spot_token" \
            -H "Content-Type: application/json" \
            -d "{
                 \"account\": {
                     \"name\": \"GCP-$project_id\"
                 }
             }")

        # Extract the account id from the response and set it to new_spot_account_id
        new_spot_account_id=$(echo $response | jq -r '.response.items[0].id')

        # Call Spot.io API to create a programmatic user
        response=$(curl -X POST "https://api.spotinst.io/setup/user/programmatic" \
            -H "Authorization: Bearer $spot_token" \
            -H "Content-Type: application/json" \
            -d "{
                 \"name\": \"GCP-$project_id-$(openssl rand -hex 4)\",
                 \"accounts\": [
                    {
                        \"id\": \"$new_spot_account_id\",
                        \"role\": \"editor\"
                    }
                 ]
             }")

        # Extract the token from the response and update the Spot.io token
        programmatic_spot_token=$(echo $response | jq -r '.response.items[0].token')
        
        # Echo the Spot.io token to the console
        echo "The Spot.io token for the programmatic user is: $programmatic_spot_token"

        # Call Spot.io API to setup credentials
        service_account_key_data=$(cat spotinst_key.json | jq 'del(.universe_domain)')
        curl -X POST "https://api.spotinst.io/gcp/setup/credentials/?accountId=$new_spot_account_id" \
            -H "Authorization: Bearer $programmatic_spot_token" \
            -H "Content-Type: application/json" \
            -d "{
                \"serviceAccount\": $service_account_key_data
            }"
    done
}

# Call the function with command line arguments
create_service_account "$@"