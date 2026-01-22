# API Reference

## Module Overview

This module provides automated Azure subscription onboarding to Spot platform through service principal configuration and role assignment.

## Classes

### Products
Enum-like class defining available Spot products.

**Attributes:**
- `CORE` (str): The Core Spot product
- `COST_INTELLIGENCE` (str): The Cost Intelligence product

**Usage:**
```python
if Products.CORE in products:
    # Handle core product
    pass
```

### BuiltInAzureRoles
Enum-like class for Azure built-in roles.

**Attributes:**
- `READER` (str): Azure built-in Reader role

**Usage:**
```python
roles.append(BuiltInAzureRoles.READER)
```

### LogLevel
Enum-like class for logging levels.

**Attributes:**
- `ERROR` (str): Error level logging
- `INFO` (str): Info level logging (default)

## Global Variables

| Variable | Type | Value | Purpose |
|----------|------|-------|---------|
| `CUSTOM_ROLE_NAME` | str | `"{customRoleName}"` | Template placeholder for role names |
| `SUBSCRIPTION_ID` | str | `"{subscriptionId}"` | Template placeholder for subscription IDs |
| `CORE_PRODUCT_CUSTOM_ROLE_URL` | str | S3 URL | Default custom role definition location |
| `HTTP_OK_RESPONSE_STATUSES` | range | 200-299 | Successful HTTP status codes |
| `SPOT_API_BASE_URL` | str | `https://api.spotinst.io` | Spot API endpoint |
| `SPOT_SETUP_CI_PATH` | str | `/cbi/v1/setup/account` | Cost Intelligence setup endpoint |
| `run_in_shell` | bool | False | Execute commands through shell |

## Functions

### Logging

#### `log(message: str, log_level: str = LogLevel.INFO) -> None`

Logs a timestamped message to console.

**Parameters:**
- `message` (str): Message to log
- `log_level` (str, optional): Log level - `LogLevel.ERROR` or `LogLevel.INFO`. Defaults to `LogLevel.INFO`

**Returns:** None

**Format:** `HH:MM:SS.fff [LEVEL] message`

**Example:**
```python
log("Operation started", LogLevel.INFO)
log("An error occurred", LogLevel.ERROR)
```

---

### Utility Functions

#### `run_command(cmd: str, *args) -> dict`

Executes a shell command and returns parsed JSON output.

**Parameters:**
- `cmd` (str): Command string with space-separated parts
- `*args` (tuple): Additional command arguments

**Returns:** `dict` - Parsed JSON output from command

**Raises:**
- `Exception`: If command returns non-zero exit code

**Details:**
- Removes ANSI escape sequences from output
- Commands split by spaces
- Additional args appended to command
- Uses `subprocess.run()` with `shell=run_in_shell` setting

**Example:**
```python
result = run_command("az account show --query tenantId")
subscriptions = run_command("az account subscription list --query [].subscriptionId")
```

#### `display_app_result(subscription_id: str, tenant_id: str, app_registration_id: str, client_secret: str) -> None`

Displays application credentials.

**Parameters:**
- `subscription_id` (str): Azure subscription ID
- `tenant_id` (str): Azure tenant ID
- `app_registration_id` (str): Azure app registration ID
- `client_secret` (str): Azure app client secret

**Returns:** None

**Output:**
```
HH:MM:SS.fff [INFO] Your credentials details:
HH:MM:SS.fff [INFO] Application Registration ID: <id>
HH:MM:SS.fff [INFO] Client Secret: <secret>
HH:MM:SS.fff [INFO] Tenant ID: <tenant>
HH:MM:SS.fff [INFO] Subscription ID: <subscription>
```

#### `parse_args() -> argparse.Namespace`

Parses and validates command line arguments.

**Parameters:** None

**Returns:** `argparse.Namespace` - Parsed arguments with the following attributes:
- `subscription` (str|None)
- `subscriptionFileName` (str|None)
- `token` (str)
- `products` (str|None)
- `skipResourceCreation` (bool)
- `customRoleName` (str)
- `customRoleJsonPath` (str|None)
- `appRegistrationId` (str|None)
- `clientSecret` (str|None)
- `shell` (bool)

**Raises:**
- `SystemExit`: If `--skipResourceCreation` used without `--appRegistrationId` and `--clientSecret`

---

### Azure Authentication

#### `login_to_azure() -> None`

Authenticates to Azure using interactive browser login.

**Parameters:** None

**Returns:** None

**Details:**
- Opens web browser for login prompt
- Executes `az login` command
- Required for initial setup or when authentication expires

**Example:**
```python
login_to_azure()
```

#### `check_azure_cli_installed() -> None`

Verifies Azure CLI is installed and accessible.

**Parameters:** None

**Returns:** None

**Raises:**
- `Exception`: If `az` command not found

**Example:**
```python
check_azure_cli_installed()  # Raises exception if not installed
```

#### `ensure_azure_cli_automatic_extension_install_enabled() -> None`

Configures Azure CLI to auto-install extensions without prompting.

**Parameters:** None

**Returns:** None

**Details:**
- Sets `extension.use_dynamic_install=yes_without_prompt`
- Necessary for unattended script execution
- Some Azure CLI commands require extensions

**Example:**
```python
ensure_azure_cli_automatic_extension_install_enabled()
```

---

### Subscription Management

#### `get_active_tenant() -> str`

Retrieves the active Azure tenant ID.

**Parameters:** None

**Returns:** `str` - Tenant ID

**Example:**
```python
tenant_id = get_active_tenant()
print(f"Current tenant: {tenant_id}")
```

#### `get_all_subscriptions_in_tenant() -> list[str]`

Retrieves all subscription IDs in the active tenant.

**Parameters:** None

**Returns:** `list[str]` - Subscription IDs

**Example:**
```python
subscriptions = get_all_subscriptions_in_tenant()
print(f"Found {len(subscriptions)} subscriptions")
```

#### `get_subscription_name(subscription_id: str) -> str`

Retrieves the display name of a subscription.

**Parameters:**
- `subscription_id` (str): Azure subscription ID

**Returns:** `str` - Subscription display name

**Example:**
```python
name = get_subscription_name("00000000-0000-0000-0000-000000000000")
print(f"Subscription name: {name}")
```

#### `does_subscription_exist_for_account(subscription: str) -> bool`

Checks if a subscription exists in the account.

**Parameters:**
- `subscription` (str): Subscription ID to check

**Returns:** `bool` - True if subscription exists, False otherwise

**Example:**
```python
if does_subscription_exist_for_account(sub_id):
    print("Subscription found")
```

---

### Service Principal Management

#### `create_service_principal(service_principal_name: str) -> tuple[str, str, str]`

Creates a new Azure app registration and service principal.

**Parameters:**
- `service_principal_name` (str): Name for the service principal

**Returns:** `tuple[str, str, str]` - (app_id, client_secret, tenant_id)

**Details:**
- Creates both app registration and service principal in one operation
- Uses `az ad sp create-for-rbac` command
- Returns credentials that can be used immediately

**Example:**
```python
app_id, secret, tenant = create_service_principal("Spot-App")
```

#### `create_client_secret(app_registration_id: str, credential_name: str) -> tuple[str, str, str]`

Creates a new client secret for an existing app registration.

**Parameters:**
- `app_registration_id` (str): App registration ID
- `credential_name` (str): Display name for the credential

**Returns:** `tuple[str, str, str]` - (app_id, password, tenant_id)

**Details:**
- Appends to existing credentials (doesn't replace)
- Uses `az ad app credential reset --append` command

**Example:**
```python
app_id, secret, tenant = create_client_secret("00000000-0000-0000-0000-000000000000", "Spot-Credential")
```

---

### Custom Role Management

#### `build_custom_role(custom_role_name: str, custom_role_json_local_path: str | None, subscription: str) -> str`

Constructs custom role JSON with substituted placeholders.

**Parameters:**
- `custom_role_name` (str): Name for the custom role
- `custom_role_json_local_path` (str|None): Path to local role JSON file. If None, fetches from S3
- `subscription` (str): Subscription ID

**Returns:** `str` - Custom role definition as JSON string

**Details:**
- Replaces `{customRoleName}` with provided name
- Replaces `{subscriptionId}` with provided subscription
- If no local path, downloads from S3: `CORE_PRODUCT_CUSTOM_ROLE_URL`
- Returns role as string (not parsed JSON)

**Example:**
```python
# Using S3 default
role_json = build_custom_role("SpotRole", None, "sub-123")

# Using local file
role_json = build_custom_role("SpotRole", "./role.json", "sub-123")
```

#### `get_or_create_custom_role(custom_role_name: str, custom_role_json_local_path: str | None, subscription: str) -> str`

Gets existing custom role or creates new one.

**Parameters:**
- `custom_role_name` (str): Name for the custom role
- `custom_role_json_local_path` (str|None): Path to custom role JSON file
- `subscription` (str): Subscription ID

**Returns:** `str` - Name of the custom role

**Details:**
- First checks if role already exists
- If not found, creates using `build_custom_role()` and Azure REST API
- Uses REST API `PUT` method to `/subscriptions/{id}/providers/Microsoft.Authorization/roleDefinitions/{uuid}`
- Generates UUID for new role ID

**Example:**
```python
role_name = get_or_create_custom_role("SpotRole", None, "sub-123")
```

#### `get_roles_for_products(products: str, custom_role_name: str, custom_role_json_local_path: str | None, subscription: str) -> list[str]`

Determines which roles to assign based on selected products.

**Parameters:**
- `products` (str): Comma-separated product list (e.g., "core,cost-intelligence")
- `custom_role_name` (str): Custom role name
- `custom_role_json_local_path` (str|None): Path to custom role JSON
- `subscription` (str): Subscription ID

**Returns:** `list[str]` - List of role names to assign

**Role Mapping:**
- `core` product → Custom role created/retrieved
- `cost-intelligence` product → Built-in READER role added

**Example:**
```python
roles = get_roles_for_products("core,cost-intelligence", "SpotRole", None, "sub-123")
# Returns: ["SpotRole", "READER"]
```

---

### Role Assignment

#### `assign_roles(app_registration_id: str, roles: list[str], subscription: str) -> None`

Assigns specified roles to a service principal within a subscription.

**Parameters:**
- `app_registration_id` (str): App registration ID
- `roles` (list[str]): List of role names to assign
- `subscription` (str): Subscription ID

**Returns:** None

**Details:**
- Gets service principal object ID using `az ad sp show`
- Assigns each role using object ID (avoids propagation delays)
- Retries after 15 seconds on failure (handles AAD propagation delays)
- Scope: `/subscriptions/{subscription}`

**Error Handling:**
- Automatic retry after 15 second delay on failure
- Handles AAD propagation latency

**Example:**
```python
assign_roles("00000000-0000-0000-0000-000000000000", ["READER", "SpotRole"], "sub-123")
```

---

### Spot Integration

#### `get_or_create_spot_account(subscription_id: str, name: str, token: str) -> str`

Gets or creates a Spot account linked to an Azure subscription.

**Parameters:**
- `subscription_id` (str): Azure subscription ID
- `name` (str): Display name for Spot account
- `token` (str): Spotinst API token

**Returns:** `str` - Spot account ID

**Details:**
- Queries existing accounts for matching subscription_id and cloud_provider='AZURE'
- If found, returns existing account ID
- If not found, creates new account
- Uses SpotinstSession and admin client

**Exception Handling:**
- `SpotinstClientException`: Invalid token (halts processing)
- `ConnectTimeout`: Spot API unreachable (halts processing)
- `Exception`: Other errors (retryable)

**Example:**
```python
account_id = get_or_create_spot_account("sub-123", "My Spot Account", "token-abc")
```

#### `set_azure_credentials(token: str, account_id: str, client_id: str, client_secret: str, tenant_id: str, subscription_id: str) -> bool`

Links Azure credentials to a Spot account.

**Parameters:**
- `token` (str): Spotinst API token
- `account_id` (str): Spot account ID
- `client_id` (str): Azure app registration ID
- `client_secret` (str): Azure app client secret
- `tenant_id` (str): Azure tenant ID
- `subscription_id` (str): Azure subscription ID

**Returns:** `bool` - True if successful

**Details:**
- Uses SpotinstSession setup_azure client
- Creates AzureCredentials object
- Calls `client.set_credentials()`
- Retries after 15 seconds on failure (handles Azure propagation delays)

**Error Handling:**
- Automatic retry after 15 second delay on Azure propagation failures
- Validates credentials with Azure

**Example:**
```python
success = set_azure_credentials(
    "token-abc",
    "account-123",
    "client-id",
    "client-secret",
    "tenant-id",
    "sub-123"
)
```

#### `register_products(spot_account_id: str, token: str, products: str) -> None`

Enrolls a Spot account in specified products.

**Parameters:**
- `spot_account_id` (str): Spot account ID
- `token` (str): Spotinst API token
- `products` (str): Comma-separated product list

**Returns:** None

**Details:**
- Handles `cost-intelligence` product enrollment via POST to `SPOT_SETUP_CI_PATH`
- Sends JSON body with account ID

**Example:**
```python
register_products("account-123", "token-abc", "core,cost-intelligence")
```

---

### Main Entry Point

#### `main() -> None`

Main execution function orchestrating the entire onboarding workflow.

**Parameters:** None

**Returns:** None

**Workflow:**
1. Parse command line arguments
2. Validate Azure CLI installation
3. Retrieve tenant ID and subscriptions
4. Create/retrieve service principal
5. For each subscription:
   - Create Spot account
   - Create/assign custom roles
   - Set Azure credentials
   - Register products
6. Output summary

**Error Handling:**
- Critical errors (invalid token, API timeout) halt all processing
- Subscription-level errors skip that subscription but continue others
- Final summary shows successful and failed subscriptions

**Example:**
```python
if __name__ == "__main__":
    main()
```

---

## Constants

### API Endpoints
```python
SPOT_API_BASE_URL = 'https://api.spotinst.io'
SPOT_SETUP_CI_PATH = "/cbi/v1/setup/account"
CORE_PRODUCT_CUSTOM_ROLE_URL = "https://spotinst-public.s3.amazonaws.com/assets/azure/custom_role_file.json"
```

### Template Placeholders
```python
CUSTOM_ROLE_NAME = "{customRoleName}"
SUBSCRIPTION_ID = "{subscriptionId}"
```

### HTTP Status Codes
```python
HTTP_OK_RESPONSE_STATUSES = range(200, 300)  # 200-299
```

---

## Exception Handling

### Handled Exceptions

| Exception | Cause | Action |
|-----------|-------|--------|
| `SpotinstClientException` | Invalid Spot token | Log error, halt all processing |
| `ConnectTimeout` | Spot API unreachable | Log error, halt all processing |
| `FileNotFoundError` | Custom role file not found | Raise to caller |
| `RequestException` | S3 download failure | Raise to caller |
| `Exception` (general) | Subscription-level errors | Log, skip subscription, continue |

### Retry Logic

Automatic retry after 15-second delay for:
- Role assignment creation (AAD propagation latency)
- Credential setting (Azure propagation latency)

---

## Integration Example

Complete workflow example:

```python
from spotinst_sdk2.models.setup.azure import AzureCredentials

# Setup
token = "your-spot-token"
subscription_id = "sub-123"
check_azure_cli_installed()
ensure_azure_cli_automatic_extension_install_enabled()

# Get tenant and subscription info
tenant_id = get_active_tenant()
sub_name = get_subscription_name(subscription_id)

# Create service principal
app_id, secret, tenant = create_service_principal("Spot-App")

# Create Spot account
account_id = get_or_create_spot_account(subscription_id, sub_name, token)

# Create and assign custom role
roles = get_roles_for_products("core", "SpotRole", None, subscription_id)
assign_roles(app_id, roles, subscription_id)

# Set credentials and register
set_azure_credentials(token, account_id, app_id, secret, tenant_id, subscription_id)
register_products(account_id, token, "core,cost-intelligence")

# Display results
display_app_result(subscription_id, tenant_id, app_id, secret)
```
