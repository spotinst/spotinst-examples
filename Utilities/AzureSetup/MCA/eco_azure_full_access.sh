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
az role assignment create --assignee $APP_ID --role "Reservations Reader" --scope "/providers/Microsoft.Capacity"

# assign reservation purchaser role
az role assignment create --assignee $APP_ID --role "Reservations Purchaser" --scope "/providers/Microsoft.Management/managementGroups/${TENANT_ID}"

# assign reservation administrator role
az role assignment create --assignee $APP_ID --role "Reservations Administrator" --scope "/providers/Microsoft.Capacity"

# assign savings plan reader role
az role assignment create --assignee $APP_ID --role "Savings plan Reader" --scope "/providers/Microsoft.BillingBenefits"

# assign savings plan purchaser role
az role assignment create --assignee $APP_ID --role "Savings plan Purchaser" --scope "/providers/Microsoft.Management/managementGroups/${TENANT_ID}"

# assign savings plan administrator role
az role assignment create --assignee $APP_ID --role "Savings plan Administrator" --scope "/providers/Microsoft.BillingBenefits"

# assign cost management reader role
az role assignment create --assignee $APP_ID --role "Cost Management Reader" --scope "/providers/Microsoft.Management/managementGroups/${TENANT_ID}"

# assign Billing Reader role using REST API
ROLE_DEF_ID="50000000-aaaa-bbbb-cccc-100000000002"
API_VERSION="2019-10-01-preview"
SCOPE="providers/Microsoft.Billing/billingAccounts/${BILLING_ACCOUNT_ID}"
ACCESS_TOKEN=$(az account get-access-token --resource https://management.azure.com/ --query accessToken -o tsv)
DATA='{\"Properties\": {\"RoleDefinitionId\": \"/${SCOPE}/billingRoleDefinitions/${ROLE_DEF_ID}\", \"PrincipalId\": \"${PRINCIPAL_ID}\"}}'
curl -X POST \
  "https://management.azure.com/${SCOPE}/createBillingRoleAssignment?api-version=${API_VERSION}" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -d "${DATA}"


# Print registered app info
echo "App ID: $APP_ID"
echo "Secret Key: $SECRET_KEY"
