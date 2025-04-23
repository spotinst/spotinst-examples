$appName = "{{app_name}}"
$tenantId = "{{tenant_id}}"
$billingAccountId = "{{billing_account_id}}"

# Connect to Azure AD
Connect-AzAccount -TenantId $tenantId

# Register the app
$app = New-AzADApplication -DisplayName $appName

# Create a service principal
New-AzADServicePrincipal -ApplicationId $app.AppId

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

# assign billing reader role
New-AzRoleAssignment -ApplicationId $appId -RoleDefinitionName "Billing Reader" -Scope "/providers/Microsoft.Billing/billingAccounts/$billingAccountId"

# Output app details
Write-Host "App ID:" $app.AppId
Write-Host "Secret Key:" $secret.SecretText
