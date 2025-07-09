import requests
from azure.identity import DefaultAzureCredential
import uuid

from Utilities.AzureSetup.CSP.eco_azure_full_access import BILLING_ACCOUNT_ID

# Set up the necessary variables
TENANT_ID = "{{tenant_id}}"
APP_NAME = "{{app_name}}"
BILLING_ACCOUNT_ID = "{{billing_account_id}}"

# Authenticate using DefaultAzureCredential
credential = DefaultAzureCredential()
graph_token = credential.get_token("https://graph.microsoft.com/.default")
management_token = credential.get_token("https://management.azure.com/.default")
graph_header = {"Authorization": f"Bearer {graph_token.token}", "Content-Type": "application/json"}
management_header = {"Authorization": f"Bearer {management_token.token}", "Content-Type": "application/json"}

# Register the application
resp = requests.post(headers=graph_header, url=f"https://graph.microsoft.com/v1.0/applications", json={"displayName": APP_NAME})
app_id = resp.json()["appId"]

# Remove the existing secret keys
resp = requests.get(f"https://graph.microsoft.com/v1.0/applications(appId='{app_id}')", headers=graph_header)
resp.raise_for_status()
keys = [pc["keyId"] for pc in resp.json()["passwordCredentials"]]
for key in keys:
    delete_response = requests.post(url=f"https://graph.microsoft.com/v1.0/applications(appId='{app_id}')/removePassword", headers=graph_header, json={"keyId": key})
    delete_response.raise_for_status()

# Create the secret key
resp = requests.post(headers=graph_header, url=f"https://graph.microsoft.com/v1.0/applications(appId='{app_id}')/addPassword", json={"passwordCredential": {}})
resp.raise_for_status()
secret_key = resp.json()["secretText"]

# Create the service principal
resp = requests.post(headers=graph_header, url=f"https://graph.microsoft.com/v1.0/servicePrincipals", json={"appId": app_id})
resp.raise_for_status()
object_id = resp.json()["id"]

# setup for role assignments
# assign reservation reader role
role_definition_id = "582fc458-8989-419f-a480-75249bc5db7e"
scope = "providers/Microsoft.Capacity"
role_assignments_url = f"https://management.azure.com/{scope}/providers/Microsoft.Authorization/roleAssignments/{str(uuid.uuid4())}?api-version=2022-04-01"
data = {
    "properties": {
        "roleDefinitionId": f"{scope}/providers/Microsoft.Authorization/roleDefinitions/{role_definition_id}",
        "principalId": object_id
    }
}
resp = requests.put(url=role_assignments_url, headers=management_header, json=data)
resp.raise_for_status()

# assign cost management reader role
role_definition_id = "72fafb9e-0641-4937-9268-a91bfd8191a3"
scope = f"providers/Microsoft.Management/managementGroups/{TENANT_ID}"
role_assignments_url = f"https://management.azure.com/{scope}/providers/Microsoft.Authorization/roleAssignments/{str(uuid.uuid4())}?api-version=2022-04-01"
data = {
    "properties": {
        "roleDefinitionId": f"{scope}/providers/Microsoft.Authorization/roleDefinitions/{role_definition_id}",
        "principalId": object_id
    }
}
resp = requests.put(url=role_assignments_url, headers=management_header, json=data)
resp.raise_for_status()

# assign billing reader role
role_definition_id = "50000000-aaaa-bbbb-cccc-100000000002"
scope = f"providers/Microsoft.Billing/billingAccounts/{BILLING_ACCOUNT_ID}"
role_assignments_url = f"https://management.azure.com/{scope}/createBillingRoleAssignment?api-version=2019-10-01-preview"
data = {
    "Properties": {
        "RoleDefinitionId": f"{scope}/billingRoleDefinitions/{role_definition_id}",
        "PrincipalId": object_id
    }
}
resp = requests.post(url=role_assignments_url, headers=management_header, json=data)
resp.raise_for_status()


print(f"App ID: {app_id}")
print(f"Secret Key: {secret_key}")
