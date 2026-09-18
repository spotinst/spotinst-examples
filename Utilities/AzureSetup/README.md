# Azure Setup Scripts
This repository contains scripts to assist with setting up Eco Azure. The following Azure agreement types are supported:
* Microsoft CSP (Cloud Solution Provider)
    * Full Access
    * Read Only
* Enterprise Agreement
    * Full Access
    * Read Only
* Microsoft Customer Agreement (MCA)
    * Full Access
    * Read Only
* Pay-As-You-Go
    * Full Access
    * Read Only
    
## Usage
1. Chose an appropriate script to run based on permissions level and Azure agreement type. 
2. Update the following variables to values appropriate for your environment: 
```
$appName = "{{app_name}}"
$tenantId = "{{tenant_id}}"
$billingAccountId = "{{billing_account_id}}"
```
3. If using the provided python scripts: install the requirements using pip
```
pip install -r requirements.txt
```
4. Execute the script
```
# For example
python PAYG/eco_azure_full_access.py
```

