APP_NAME="{{app_name}}"
TENANT_ID="{{tenant_id}}"
BILLING_ACCOUNT_ID="{{billing_account_id}}"

az login --tenant $TENANT_ID

# Create app
APP_ID=$(az ad app create --display-name $APP_NAME  --output json --query appId)
APP_ID=$(echo $APP_ID | tr -d '"')

# Generate secret key
SECRET_KEY=$(az ad app credential reset --id $APP_ID --output json --query password)
SECRET_KEY=$(echo $SECRET_KEY | tr -d '"')

# Create service principal
PRINCIPAL_ID=$(az ad sp create --id $APP_ID --output json --query id | tr -d '"')

# Role assignments
# assign reservation reader role
az role assignment create --assignee "{{app_id}}" --role "Reservations Reader" --scope "/providers/Microsoft.Capacity"

# assign savings plan reader role
az role assignment create --assignee $APP_ID --role "Savings plan Reader" --scope "/providers/Microsoft.BillingBenefits"

# assign cost management reader role
az role assignment create --assignee "{{app_id}}" --role "Cost Management Reader" --scope "/providers/Microsoft.Management/managementGroups/${TENANT_ID}"

# assign Enrollment Reader role using REST API
ROLE_ASSIGNMENT_ID=$(uuidgen | tr 'A-F' 'a-f')
ROLE_DEF_ID="24f8edb6-1668-4659-b5e2-40bb5f3a7d7e"
API_VERSION="2019-10-01-preview"
SCOPE="providers/Microsoft.Billing/billingAccounts/${BILLING_ACCOUNT_ID}"
ACCESS_TOKEN=$(az account get-access-token --resource https://management.azure.com/ --query accessToken -o tsv)
DATA='{\"properties\": {\"roleDefinitionId\": \"/${SCOPE}/billingRoleDefinitions/${ROLE_DEF_ID}\", \"principalTenantId\": \"${TENANT_ID}\", \"principalId\": \"${PRINCIPAL_ID}\"}}'
curl -X PUT \
  "https://management.azure.com/${SCOPE}/billingRoleAssignments/${ROLE_ASSIGNMENT_ID}?api-version=${API_VERSION}" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -d "${DATA}"


# Print registered app info
echo "App ID: $APP_ID"
echo "Secret Key: $SECRET_KEY"
