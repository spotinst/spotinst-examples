Azure Subscription Onboarding to Spot by Flexera (Quick Guide)

Prerequisites
•	Azure CLI installed
•	Python 3.x installed
•	Spot Organization API Token
•	Azure account with permissions to create:
o	Service Principal
o	Custom Role
o	Role Assignments
________________________________________
1. Login to Azure
az login
Verify subscriptions:
az account list --output table
(Optional) Set the active subscription:
az account set --subscription <SUBSCRIPTION_ID>
________________________________________
2. Configure Azure CLI
Enable automatic extension installation:
az config set extension.use_dynamic_install=yes_without_prompt
________________________________________
3. Install Python Dependencies
pip install requests
pip install spotinst-sdk2
________________________________________
4. Onboard a Single Subscription
python azure-automatic-role-assignment.py ^
  --token <SPOT_ORG_TOKEN> ^
  --subscription <SUBSCRIPTION_ID> ^
  --shell
________________________________________
5. Onboard Multiple Subscriptions
Create a text file (e.g., subscriptions.txt) with one Subscription ID per line.
Example:
11111111-1111-1111-1111-111111111111
22222222-2222-2222-2222-222222222222
33333333-3333-3333-3333-333333333333
Run:
python azure-automatic-role-assignment.py ^
  --token <SPOT_ORG_TOKEN> ^
  --subscriptionFileName subscriptions.txt ^
  --shell
________________________________________
What the Script Does
•	Creates (or uses) an Azure Service Principal
•	Creates a Spot Account
•	Creates the required Azure Custom Role
•	Assigns Azure RBAC permissions
•	Links Azure credentials to the Spot Account
•	Registers the subscription with Spot
________________________________________
Common Issues
Issue	Resolution
az command not found	Install Azure CLI
Please run az login	Execute az login
Script hangs waiting for extension	Run az config set extension.use_dynamic_install=yes_without_prompt
WinError 2	Run the script with --shell
Spot authentication error	Verify the Spot Organization API Token

