$appName = "{{app_name}}"
$tenantId = "{{tenant_id}}"
$billingAccountId = "{{billing_account_id}}"

# Connect to Azure AD
Connect-AzAccount -TenantId $tenantId

# Register the app
$app = New-AzADApplication -DisplayName $appName

# Create a service principal and get its ID
$sp = New-AzADServicePrincipal -ApplicationId $app.AppId
$principalId = $sp.Id

# Delete all secret keys
$secretKeys = Get-AzADAppCredential -ApplicationId $appId
foreach ($secretKey in $secretKeys) {
    # Remove the secret key
    Remove-AzADAppCredential -ApplicationId $appId -KeyId $secretKey.KeyId
}

# Create a client secret
$secret = New-AzADAppCredential -ApplicationId $app.AppId -StartDate (Get-Date) -EndDate (Get-Date).AddYears(1)

# Role assignments
# assign reservation reader role
New-AzRoleAssignment -ApplicationId $appId -RoleDefinitionName "Reservations Reader" -Scope "/providers/Microsoft.Capacity"

# assign reservation purchaser role
New-AzRoleAssignment -ApplicationId $appId -RoleDefinitionName "Reservations Purchaser" -Scope "/providers/Microsoft.Management/managementGroups/$tenantId"

# assign reservation administrator role
New-AzRoleAssignment -ApplicationId $appId -RoleDefinitionName "Reservations Administrator" -Scope "/providers/Microsoft.Capacity"

# assign savings plan reader role
New-AzRoleAssignment -ApplicationId $appId -RoleDefinitionName "Savings plan Reader" -Scope "/providers/Microsoft.BillingBenefits"

# assign savings plan purchaser role
New-AzRoleAssignment -ApplicationId $appId -RoleDefinitionName "Savings plan Purchaser" -Scope "/providers/Microsoft.Management/managementGroups/$tenantId"

# assign savings plan administrator role
New-AzRoleAssignment -ApplicationId $appId -RoleDefinitionName "Savings plan Administrator" -Scope "/providers/Microsoft.BillingBenefits"

# assign cost management reader role
New-AzRoleAssignment -ApplicationId $appId -RoleDefinitionName "Cost Management Reader" -Scope "/providers/Microsoft.Management/managementGroups/$tenantId"

# assign billing reader role via REST API
$ROLE_DEF_ID = "50000000-aaaa-bbbb-cccc-100000000002"
$API_VERSION = "2019-10-01-preview"
$SCOPE = "providers/Microsoft.Billing/billingAccounts/$billingAccountId"
$ACCESS_TOKEN = az account get-access-token --resource https://management.azure.com/ --query accessToken -o tsv
$DATA = @{
    Properties = @{
        RoleDefinitionId = "/$SCOPE/billingRoleDefinitions/$ROLE_DEF_ID"
        PrincipalId      = $principalId
    }
} | ConvertTo-Json
$headers = @{
    "Content-Type"  = "application/json"
    "Authorization" = "Bearer $ACCESS_TOKEN"
}
Invoke-RestMethod -Method Post `
    -Uri "https://management.azure.com/$SCOPE/createBillingRoleAssignment?api-version=$API_VERSION" `
    -Headers $headers `
    -Body $DATA


# Output app details
Write-Host "App ID:" $app.AppId
Write-Host "Secret Key:" $secret.SecretText
