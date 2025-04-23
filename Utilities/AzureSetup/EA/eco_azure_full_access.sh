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
az ad sp create --id $APP_ID

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

# assign enrollment reader role
az role assignment create --assignee $APP_ID --role "Enrollment Reader" --scope "/providers/Microsoft.Billing/billingAccounts/${BILLING_ACCOUNT_ID}"


# Print registered app info
echo "App ID: $APP_ID"
echo "Secret Key: $SECRET_KEY"
