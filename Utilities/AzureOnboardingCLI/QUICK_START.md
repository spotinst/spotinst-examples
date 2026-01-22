# Quick Start Guide

## 5-Minute Setup

### 1. Prerequisites Check
```bash
# Verify Python 3 is installed
python3 --version

# Verify Azure CLI is installed
az --version

# If not installed, visit: https://learn.microsoft.com/en-us/cli/azure/install-azure-cli
```

### 2. Install Dependencies
```bash
pip install -r requirements.txt
```

### 3. Authenticate to Azure
```bash
az login
```

This opens your browser for interactive login. Close the browser when done.

### 4. Get Spot Token
- Log into Spot console at https://console.spotinst.io
- Navigate to: Settings → Integrations → API
- Copy your organization token

### 5. Run Onboarding

#### Option A: Single Subscription
```bash
python azure-automatic-role-assignment.py \
  --token YOUR_SPOT_TOKEN \
  --subscription YOUR_SUBSCRIPTION_ID
```

#### Option B: All Subscriptions in Tenant
```bash
python azure-automatic-role-assignment.py \
  --token YOUR_SPOT_TOKEN
```

## Common Scenarios

### Scenario 1: Onboard Single Azure Subscription

```bash
# 1. Get your subscription ID
az account show --query id -o tsv

# 2. Run onboarding
python azure-automatic-role-assignment.py \
  --token YOUR_SPOT_TOKEN \
  --subscription YOUR_SUBSCRIPTION_ID

# 3. Check output for success message
```

**Expected Output:**
```
12:34:56.789 [INFO] Onboarding subscription 1 of 1 (My Subscription - /subscriptions/...)
12:34:57.890 [INFO] No Spot Account was not found for the subscription. Created Spot Account...
12:34:58.901 [INFO] Finished creating service principal...
12:34:59.012 [INFO] Finished to create custom role...
12:35:00.123 [INFO] Completed onboarding subscription 1 of 1...
12:35:01.234 [INFO] Operation completed. Summary:
12:35:01.345 [INFO]     Number of subscriptions attempted: 1
12:35:01.456 [INFO]     Number of subscriptions onboarded successfully: 1
```

### Scenario 2: Onboard Multiple Subscriptions from File

```bash
# 1. Create subscriptions.txt with your subscription IDs
cat > subscriptions.txt << EOF
00000000-0000-0000-0000-000000000001
00000000-0000-0000-0000-000000000002
00000000-0000-0000-0000-000000000003
EOF

# 2. Run onboarding
python azure-automatic-role-assignment.py \
  --token YOUR_SPOT_TOKEN \
  --subscriptionFileName subscriptions.txt

# 3. Check results
```

### Scenario 3: Reuse Existing Service Principal

```bash
# If you already have an app registration:
python azure-automatic-role-assignment.py \
  --token YOUR_SPOT_TOKEN \
  --appRegistrationId YOUR_APP_ID \
  --clientSecret YOUR_CLIENT_SECRET \
  --subscription YOUR_SUBSCRIPTION_ID
```

### Scenario 4: Skip Azure Resource Creation (Spot Only)

If you've already created Azure resources manually:

```bash
python azure-automatic-role-assignment.py \
  --token YOUR_SPOT_TOKEN \
  --subscription YOUR_SUBSCRIPTION_ID \
  --appRegistrationId YOUR_APP_ID \
  --clientSecret YOUR_CLIENT_SECRET \
  --skipResourceCreation
```

### Scenario 5: Use Custom Role Definition

```bash
# 1. Create your custom role JSON file (custom_role.json)
# 2. Run with --customRoleJsonPath
python azure-automatic-role-assignment.py \
  --token YOUR_SPOT_TOKEN \
  --subscription YOUR_SUBSCRIPTION_ID \
  --customRoleJsonPath ./custom_role.json \
  --customRoleName MyCustomRole
```

### Scenario 6: Register Multiple Products

```bash
python azure-automatic-role-assignment.py \
  --token YOUR_SPOT_TOKEN \
  --subscription YOUR_SUBSCRIPTION_ID \
  --products "core,cost-intelligence"
```

## Troubleshooting

### Error: 'az' command not found
**Solution:** Install Azure CLI
```bash
# macOS with Homebrew
brew install azure-cli

# Or visit: https://learn.microsoft.com/en-us/cli/azure/install-azure-cli
```

### Error: Not authenticated to Azure
**Solution:** Run `az login` and complete browser authentication
```bash
az login
```

### Error: Spotinst token is invalid
**Solution:** 
1. Verify token was copied correctly
2. Check token hasn't expired
3. Ensure you have organization admin permissions
4. Try token again from Settings → Integrations → API

### Error: Permission denied creating roles
**Solution:** Your Azure user needs these permissions:
- User Access Administrator (or Owner role) in the subscription
- Ability to create service principals

Contact your Azure subscription owner if needed.

### Error: Role assignment creation failed
**Solution:** Usually due to Azure propagation delay. Script automatically retries after 15 seconds.

### Error: Could not reach Spot API
**Solution:** 
- Check internet connectivity
- Verify Spot API is accessible (not blocked by firewall)
- Try again in a few moments
- Contact Spot support if persistent

### Script Hangs/Times Out
**Solution:** Some operations have timeouts. If it seems stuck for >5 minutes:
1. Press Ctrl+C to cancel
2. Check your internet connection
3. Try running with fewer subscriptions
4. Contact Spot support

## What Gets Created

When running without `--skipResourceCreation`, the script creates:

### In Azure:
1. **Service Principal**: Used for Azure-to-Spot authentication
2. **Custom Role**: With permissions needed for Spot to manage resources
3. **Role Assignments**: Grants the custom role to your service principal

### In Spot:
1. **Spot Account**: One per Azure subscription
2. **Linked Credentials**: Azure subscription linked to Spot account
3. **Product Enrollment**: Registers selected Spot products

## Verification

### Verify in Azure

```bash
# Check service principal was created
az ad sp list --display-name "Spot-App"

# Check custom role exists
az role definition list --custom-role-only true --query "[?contains(roleName, 'Spot')]"

# Check role assignments
az role assignment list --include-inherited --query "[?principalName=='Spot-App']"
```

### Verify in Spot Console

1. Log into Spot console: https://console.spotinst.io
2. Navigate to: Cloud Integrations → Azure
3. Verify your subscription appears and shows as "Connected"

## Next Steps

After successful onboarding:

1. **Configure Elastigroup**: Create Elastigroup to manage Azure VMs
2. **Set up Cost Intelligence**: Get Azure spending analytics
3. **Configure Notifications**: Set up alerts for savings and events
4. **Review Policies**: Adjust optimization policies for your workloads

## Support

If you encounter issues:

1. **Check logs**: Review the console output for error messages
2. **Review this guide**: See Troubleshooting section above
3. **Contact Spot Support**: https://spot.io/support
4. **GitHub Issues**: Report issues in the repository

## Advanced Topics

### Custom Role JSON Structure

If using `--customRoleJsonPath`, your JSON should follow Azure's custom role format:

```json
{
  "Name": "Spot-CoreRole",
  "IsCustom": true,
  "Description": "Custom role for Spot",
  "Actions": [
    "Microsoft.Authorization/*/read",
    "Microsoft.Compute/*/read",
    "Microsoft.Network/*/read",
    "Microsoft.Storage/*/read"
  ],
  "NotActions": [],
  "AssignableScopes": ["/subscriptions/{subscriptionId}"]
}
```

### Using with CI/CD

For automated deployments:

```bash
# Use environment variables for sensitive data
export SPOT_TOKEN="your-token"
export AZURE_SUBSCRIPTION_ID="sub-123"

python azure-automatic-role-assignment.py \
  --token "$SPOT_TOKEN" \
  --subscription "$AZURE_SUBSCRIPTION_ID"
```

### Batch Processing Multiple Tenants

```bash
#!/bin/bash

SPOT_TOKEN="your-token"

# Process multiple subscriptions
for SUB_ID in \
  "00000000-0000-0000-0000-000000000001" \
  "00000000-0000-0000-0000-000000000002" \
  "00000000-0000-0000-0000-000000000003"
do
  echo "Processing subscription: $SUB_ID"
  python azure-automatic-role-assignment.py \
    --token "$SPOT_TOKEN" \
    --subscription "$SUB_ID"
done
```

## FAQ

**Q: Can I use this multiple times safely?**
A: Yes. The script checks if resources already exist and reuses them.

**Q: Will this affect my existing Azure resources?**
A: No. It only creates new service principals and roles. Existing resources are unmodified.

**Q: Can I change the custom role name?**
A: Yes, use `--customRoleName "MyCustomName"`. Each Spot account gets a unique role.

**Q: Is the client secret safe?**
A: The script displays it once. Store it securely (Azure Key Vault recommended). It's equivalent to a password.

**Q: How long does onboarding take?**
A: Typically 2-5 minutes per subscription depending on Azure propagation delays.

**Q: Can I cancel mid-onboarding?**
A: Yes, press Ctrl+C. Partially created resources may remain and can be cleaned up manually.

**Q: What if I need to rotate credentials?**
A: Run with `--appRegistrationId` and `--clientSecret` will be auto-rotated, or create new ones manually.

**Q: Can I onboard the same subscription twice?**
A: Yes, it reuses existing resources. Useful for rotating credentials or updating products.
