# Azure Automatic Role Assignment

This script automates the onboarding of Azure subscriptions to Spot by creating and configuring required Azure resources (service principals, custom roles, and role assignments) and registering them with the Spot platform.

## Overview

The script performs the following key operations:

1. **Authentication**: Validates Azure CLI installation and authenticates to Azure
2. **Service Principal Management**: Creates or uses an existing app registration and service principal
3. **Custom Role Creation**: Builds and creates custom Azure roles for Spot products
4. **Role Assignment**: Assigns roles to the service principal within target subscriptions
5. **Spot Account Registration**: Creates Spot accounts and links Azure credentials
6. **Product Enrollment**: Registers selected Spot products (Core, Cost Intelligence)

## Prerequisites

### Required Software
- **Azure CLI**: Must be installed and accessible via the `az` command
  - Installation: https://learn.microsoft.com/en-us/cli/azure/install-azure-cli
- **Python 3.x**: Runtime for executing the script

### Required Python Dependencies
All dependencies are listed in `requirements.txt`. Install with:
```bash
pip install -r requirements.txt
```

Key dependencies:
- `spotinst-sdk2`: Spotinst SDK for interacting with Spot API
- `azure-*`: Azure SDK packages for Azure resource management
- `requests`: HTTP library for S3 role definition retrieval

### Required Permissions
- **Azure**: Must be authenticated to Azure with sufficient permissions to:
  - Create service principals and app registrations
  - Create custom roles
  - Assign roles within subscriptions
  - Access subscription information

- **Spot**: Must have a valid Spot organization token with account creation permissions

## Usage

### Basic Usage

#### Single Subscription Onboarding
```bash
python azure-automatic-role-assignment.py \
  --token YOUR_SPOT_TOKEN \
  --subscription YOUR_SUBSCRIPTION_ID
```

#### All Subscriptions in Tenant
```bash
python azure-automatic-role-assignment.py \
  --token YOUR_SPOT_TOKEN
```

#### Multiple Subscriptions from File
```bash
python azure-automatic-role-assignment.py \
  --token YOUR_SPOT_TOKEN \
  --subscriptionFileName subscriptions.txt
```

### Command Line Arguments

| Argument | Required | Default | Description |
|----------|----------|---------|-------------|
| `--token` | Yes | - | Spot organization token |
| `--subscription` | No | All tenant subscriptions | Azure Subscription ID to onboard |
| `--subscriptionFileName` | No | - | File path with newline-separated subscription IDs |
| `--products` | No | `core` | Products to register (comma-separated: `core`, `cost-intelligence`) |
| `--customRoleName` | No | `Spot-CoreRole` | Name for the custom role |
| `--customRoleJsonPath` | No | Download from S3 | Path to custom role JSON definition file |
| `--appRegistrationId` | No | Create new | Use existing App Registration ID |
| `--clientSecret` | No | Create new | Client secret for existing app registration |
| `--skipResourceCreation` | No | `False` | Skip Azure resource creation (requires `--appRegistrationId` and `--clientSecret`) |
| `--shell` | No | `False` | Execute commands through shell (helpful on Windows) |

### Advanced Usage Examples

#### Using Existing App Registration
```bash
python azure-automatic-role-assignment.py \
  --token YOUR_SPOT_TOKEN \
  --appRegistrationId YOUR_APP_ID \
  --clientSecret YOUR_CLIENT_SECRET
```

#### Custom Role with Local JSON
```bash
python azure-automatic-role-assignment.py \
  --token YOUR_SPOT_TOKEN \
  --customRoleJsonPath ./my_custom_role.json
```

#### Only Spot Resource Creation (No Azure Resources)
```bash
python azure-automatic-role-assignment.py \
  --token YOUR_SPOT_TOKEN \
  --subscription YOUR_SUBSCRIPTION_ID \
  --appRegistrationId YOUR_APP_ID \
  --clientSecret YOUR_CLIENT_SECRET \
  --skipResourceCreation
```

#### Register Multiple Products
```bash
python azure-automatic-role-assignment.py \
  --token YOUR_SPOT_TOKEN \
  --products "core,cost-intelligence"
```

### Configuration File Format

**subscriptions.txt** (when using `--subscriptionFileName`):
```
subscription-id-1
subscription-id-2
subscription-id-3
```

## Architecture

### Main Workflow

```
1. validate_environment()
   ├─ Check Azure CLI installation
   ├─ Enable automatic extension installation
   └─ Authenticate to Azure

2. process_subscriptions()
   ├─ Retrieve tenant ID
   ├─ Get list of subscriptions to onboard
   └─ For each subscription:
      ├─ Create/Get service principal & app registration
      ├─ Create custom roles
      ├─ Assign roles to service principal
      ├─ Create Spot account
      ├─ Set Azure credentials in Spot
      └─ Register products

3. output_results()
   └─ Display summary and any failures
```

## Function Reference

### Core Functions

#### Authentication & Validation

**`login_to_azure()`**
- Opens web browser for interactive Azure CLI authentication
- No parameters or return value

**`check_azure_cli_installed()`**
- Verifies Azure CLI is installed and accessible
- Raises `Exception` if Azure CLI not found

**`ensure_azure_cli_automatic_extension_install_enabled()`**
- Configures Azure CLI to auto-install required extensions without prompting
- Necessary for unattended script execution

#### Azure Resource Management

**`get_active_tenant()`**
- Returns: `str` - Current tenant ID

**`get_all_subscriptions_in_tenant()`**
- Returns: `list[str]` - Subscription IDs in current tenant

**`get_subscription_name(subscription_id: str)`**
- Parameters:
  - `subscription_id`: Azure subscription ID
- Returns: `str` - Display name of subscription

**`does_subscription_exist_for_account(subscription: str)`**
- Parameters:
  - `subscription`: Subscription ID to check
- Returns: `bool` - True if subscription exists for account

**`create_service_principal(service_principal_name: str)`**
- Creates new app registration and service principal
- Parameters:
  - `service_principal_name`: Name for the service principal
- Returns: `tuple[str, str, str]` - (app_id, client_secret, tenant_id)

**`create_client_secret(app_registration_id: str, credential_name: str)`**
- Adds new client secret to existing app registration
- Parameters:
  - `app_registration_id`: ID of the app registration
  - `credential_name`: Display name for the credential
- Returns: `tuple[str, str, str]` - (app_id, password, tenant_id)

#### Custom Role Management

**`build_custom_role(custom_role_name: str, custom_role_json_local_path: str, subscription: str)`**
- Constructs custom role JSON with substituted values
- Parameters:
  - `custom_role_name`: Name for the role
  - `custom_role_json_local_path`: Path to local JSON file (or None to fetch from S3)
  - `subscription`: Subscription ID
- Returns: `str` - Custom role JSON as string
- Fetches from S3 if local path not provided

**`get_or_create_custom_role(custom_role_name: str, custom_role_json_local_path: str, subscription: str)`**
- Returns existing custom role or creates new one
- Parameters:
  - `custom_role_name`: Name for the role
  - `custom_role_json_local_path`: Path to custom role JSON file
  - `subscription`: Subscription ID
- Returns: `str` - Name of the custom role
- Uses Azure REST API for role creation

**`get_roles_for_products(products: str, custom_role_name: str, custom_role_json_local_path: str, subscription: str)`**
- Determines which roles to assign based on products
- Parameters:
  - `products`: Comma-separated product list
  - `custom_role_name`: Custom role name
  - `custom_role_json_local_path`: Path to custom role JSON
  - `subscription`: Subscription ID
- Returns: `list[str]` - Roles to assign
- "core" product → custom role
- "cost-intelligence" → adds built-in READER role

#### Role Assignment

**`assign_roles(app_registration_id: str, roles: list[str], subscription: str)`**
- Assigns specified roles to service principal in subscription
- Parameters:
  - `app_registration_id`: App registration ID
  - `roles`: List of role names to assign
  - `subscription`: Subscription ID
- Handles propagation latency with retry (15 second delay)

#### Spot Integration

**`get_or_create_spot_account(subscription_id: str, name: str, token: str)`**
- Returns existing Spot account or creates new one
- Parameters:
  - `subscription_id`: Azure subscription ID (external provider ID)
  - `name`: Name for Spot account
  - `token`: Spotinst API token
- Returns: `str` - Spot account ID
- Matches accounts by subscription ID and AZURE cloud provider

**`set_azure_credentials(token: str, account_id: str, client_id: str, client_secret: str, tenant_id: str, subscription_id: str)`**
- Links Azure credentials to Spot account
- Parameters:
  - `token`: Spotinst API token
  - `account_id`: Spot account ID
  - `client_id`: Azure app registration ID
  - `client_secret`: Azure client secret
  - `tenant_id`: Azure tenant ID
  - `subscription_id`: Azure subscription ID
- Returns: `bool` - True if successful
- Handles propagation latency with retry (15 second delay)

**`register_products(spot_account_id: str, token: str, products: str)`**
- Enrolls Spot account in specified products
- Parameters:
  - `spot_account_id`: Spot account ID
  - `token`: Spotinst API token
  - `products`: Comma-separated product list
- Handles Cost Intelligence enrollment via Spot Setup API

#### Utility Functions

**`run_command(cmd: str, *args) -> dict`**
- Executes shell command and returns JSON-parsed output
- Parameters:
  - `cmd`: Command string (space-separated)
  - `args`: Additional command arguments
- Returns: `dict` - Parsed JSON output from command
- Raises `Exception` if command fails
- Removes ANSI escape sequences from output

**`log(message: str, log_level: str = "INFO")`**
- Logs timestamped message to console
- Parameters:
  - `message`: Message to log
  - `log_level`: "INFO" or "ERROR"
- Format: `HH:MM:SS.fff [LEVEL] message`

**`display_app_result(subscription_id: str, tenant_id: str, app_registration_id: str, client_secret: str)`**
- Displays final credentials for logging/reference
- Parameters: All credential/ID values to display

**`parse_args()`**
- Parses and validates command line arguments
- Returns: `argparse.Namespace` - Parsed arguments
- Validates `--skipResourceCreation` requirements

## Error Handling

The script implements multi-level error handling:

### Critical Errors (Halt Processing)
- Invalid Spot token (`SpotinstClientException`)
- Spot API unreachable (`ConnectTimeout`)
- Azure CLI not installed

### Non-Critical Errors (Skip Subscription)
- Subscription onboarding failures
- Role assignment failures (with automatic retry)
- Credential setting failures (with automatic retry)

### Retry Logic
Certain operations retry after 15 seconds when expected propagation delays may occur:
- Role assignment creation
- Credential setting

### Output
All errors and failures are logged with:
- Clear error messages
- Failed subscription tracking
- Final summary with success count

## Output

### Log Format
```
HH:MM:SS.fff [INFO] Your credentials details:
HH:MM:SS.fff [INFO] Application Registration ID: <id>
HH:MM:SS.fff [INFO] Client Secret: <secret>
HH:MM:SS.fff [INFO] Tenant ID: <tenant>
HH:MM:SS.fff [INFO] Subscription ID: <subscription>
```

### Summary Output
```
Operation completed.  Summary:
    Number of subscriptions attempted:                X
    Number of subscriptions onboarded successfully:   Y
    Number of subscriptions onboard was unsuccessful: Z
    List of subscriptions onboard was unsuccessful:
        <subscription_name> - <subscription_id>
```

## Dependencies

### Core Dependencies
- **spotinst-sdk2 (2.1.38)**: Spotinst platform integration
- **azure-core (1.28.0)**: Azure SDK base
- **azure-identity (1.13.0)**: Azure authentication
- **azure-mgmt-subscription (3.1.1)**: Subscription management
- **requests (2.31.0)**: HTTP requests for S3 role definitions

### Security Dependencies
- **cryptography (41.0.4)**: Encryption support
- **PyJWT (2.7.0)**: JWT token handling
- **msal (1.22.0)**: Azure authentication
- **oauthlib (1.3.1)**: OAuth support

### Other Dependencies
- **PyYAML (6.0)**: YAML parsing
- **urllib3 (2.0.6)**: HTTP client
- **certifi (2023.7.22)**: SSL certificates

## Security Considerations

1. **Token Storage**: Never hardcode Spot tokens. Use environment variables or secure secret management
2. **Client Secrets**: Client secrets should be stored securely and never logged
3. **Azure CLI Authentication**: Use device flow or service principal authentication for CI/CD
4. **Shell Execution**: The `--shell` parameter executes commands through shell - use carefully
5. **Credential Display**: By default, credentials are displayed when `--clientSecret` not provided

## Troubleshooting

### Azure CLI Not Found
```
Error: 'az' command not found. Please install the Azure CLI and try again.
```
**Solution**: Install Azure CLI from https://learn.microsoft.com/en-us/cli/azure/install-azure-cli

### Role Assignment Failures
The script automatically retries role assignments after 15 seconds to handle AAD propagation delays.

### Spot API Connection Timeout
```
Error: Could not reach Spot API. Please try again later.
```
**Solution**: Check internet connectivity and Spot API status. Verify token validity.

### Invalid Spot Token
```
Error: Spotinst token is invalid.
```
**Solution**: Verify token is correct and has account creation permissions.

### Extension Not Found
If seeing Azure CLI extension errors, ensure `--ensure_azure_cli_automatic_extension_install_enabled()` is called or run:
```bash
az config set extension.use_dynamic_install=yes_without_prompt
```

## Example Workflow

### Scenario: Onboard Multiple Subscriptions with Custom Role

1. Create subscription list file:
```bash
cat > subscriptions.txt << EOF
/subscriptions/sub-1
/subscriptions/sub-2
/subscriptions/sub-3
EOF
```

2. Create custom role JSON:
```bash
cat > custom_role.json << 'EOF'
{
  "Name": "{customRoleName}",
  "IsCustom": true,
  "Description": "Custom role for Spot",
  "Actions": [...],
  "AssignableScopes": ["/subscriptions/{subscriptionId}"]
}
EOF
```

3. Run onboarding:
```bash
python azure-automatic-role-assignment.py \
  --token abc123xyz \
  --subscriptionFileName subscriptions.txt \
  --customRoleJsonPath ./custom_role.json \
  --customRoleName SpotCustomRole \
  --products "core,cost-intelligence"
```

## Constants

- `CUSTOM_ROLE_NAME`: Template placeholder `{customRoleName}`
- `SUBSCRIPTION_ID`: Template placeholder `{subscriptionId}`
- `CORE_PRODUCT_CUSTOM_ROLE_URL`: S3 URL for default custom role definition
- `SPOT_API_BASE_URL`: Spot API endpoint (https://api.spotinst.io)
- `SPOT_SETUP_CI_PATH`: Spot Cost Intelligence setup endpoint

## Classes

### Products
Enum-like class for product identifiers:
- `CORE`: Core Spot product
- `COST_INTELLIGENCE`: Spot Cost Intelligence product

### BuiltInAzureRoles
Enum-like class for Azure built-in roles:
- `READER`: Azure built-in Reader role

### LogLevel
Enum-like class for logging levels:
- `ERROR`: Error level logging
- `INFO`: Info level logging
