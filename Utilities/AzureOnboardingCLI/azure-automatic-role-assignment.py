#!/usr/bin/env

import argparse
import re
import subprocess
import time
import uuid
from datetime import datetime

import requests
from requests import ConnectTimeout
from spotinst_sdk2 import SpotinstSession
from spotinst_sdk2.client import Client, SpotinstClientException
from spotinst_sdk2.models.setup.azure import *

CUSTOM_ROLE_NAME = "{customRoleName}"
SUBSCRIPTION_ID = "{subscriptionId}"
CORE_PRODUCT_CUSTOM_ROLE_URL = (
    "https://spotinst-public.s3.amazonaws.com/assets/azure/custom_role_file.json"
)
HTTP_OK_RESPONSE_STATUSES = range(200, 300)
SPOT_API_BASE_URL = 'https://api.spotinst.io'
SPOT_SETUP_CI_PATH = "/cbi/v1/setup/account"


class Products:
    CORE = 'core'
    COST_INTELLIGENCE = 'cost-intelligence'


class BuiltInAzureRoles:
    READER = 'READER'


class LogLevel:
    ERROR = "ERROR"
    INFO = "INFO"


# Pass through argument to subprocess.run(). See documentation there for additional information. When running in Windows
# and seeing errors executing commands, it may be helpful to use `shell=True`.
run_in_shell = False


def log(message, log_level=LogLevel.INFO):
    print(f"{datetime.now().strftime('%H:%M:%S.%f')[:-3]} [{log_level}] {message}")


def get_all_subscriptions_in_tenant():
    """
    Retrieves all the subscriptions in the tenant.
    Returns:
        list(str): The subscription ids in the tenant.
    """
    subscription_ids = run_command("az account subscription list --query [].subscriptionId")
    return subscription_ids


def get_active_tenant():
    """
    Gets the active tenant.
    Returns:
        str: The tenant id.
    """
    tenant_id = run_command("az account show --query tenantId")
    return tenant_id


def get_subscription_name(subscription_id):
    """
    Retrieves the display name of a subscription based on the given subscription ID.

    Parameters:
        subscription_id (str): The ID of the subscription.

    Returns:
        str: The display name of the subscription.
    """
    subscription_display_name = run_command(
        f'az account subscription show --subscription-id {subscription_id} --query displayName')

    return subscription_display_name


def get_or_create_spot_account(subscription_id, name, token):
    """
    Creates a spot account with the given name and token.

    Args:
        subscription_id (str) : External provider id.
        name (str): The name of the spot account.
        token (str): The authentication token.

    Returns:
        str: The ID of the created account.
    """
    try:
        session = SpotinstSession(auth_token=token, base_url=SPOT_API_BASE_URL)
    except SpotinstClientException as e:
        log(f"Spotinst token is invalid.", LogLevel.ERROR)
        raise e

    client = session.client("admin", timeout=15)

    try:
        existing_accounts = [account["account_id"] for account in client.get_accounts() if
                             account["provider_external_id"] == subscription_id and account["cloud_provider"] == 'AZURE']
    except ConnectTimeout as e:
        log(f"Could not reach Spot API. Please try again later.", LogLevel.ERROR)
        raise e

    except Exception as e:
        log(f"An exception of type {type(e).__name__} occurred while attempting to retrieve Spot Account information. {str(e)}", LogLevel.ERROR)
        raise e

    account_id = existing_accounts.pop() if len(existing_accounts) > 0 else None

    if not account_id:
        # there is no existing spot account so create it
        account_result = client.create_account(name)
        account_id = account_result["id"]
        log(f"No Spot Account was not found for the subscription.  Created Spot Account {account_id} for subscription {subscription_id}")
    else:
        log(f"Existing Spot Account found {account_id} for subscription {subscription_id}")

    return account_id


def run_command(cmd, *args):
    """
    Runs a command with the given arguments and returns the result.

    Args:
        cmd (str): The command to run.
        args (tuple): Additional arguments to pass to the command.

    Returns:
        dict: The result of the command, parsed as a JSON object.

    Raises:
        Exception: If the command fails to run, an exception is raised with the command and error message.

    Example:
        #>>> run_command("ls", "-l")
        {'file1.txt': 'rw-r--r--', 'file2.txt': 'rw-rw-r--'}
    """
    log(f"Running command: {cmd}")

    cmd_args = cmd.split()
    cmd_to_run = cmd_args + list(args)

    run_process_result = subprocess.run(
        cmd_to_run, stdout=subprocess.PIPE, stderr=subprocess.PIPE, encoding="utf-8", shell=run_in_shell
    )  # Maybe need to change to check output because in python there isn't encoding

    if run_process_result.returncode != 0:
        raise Exception(
            f"Failed to run the command: {cmd}. Errors: {run_process_result.stderr}"
        )
    else:
        # Remove ANSI escape sequences from a string
        ansi_escape = re.compile(r"\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])")
        cleaned_command_result = ansi_escape.sub("", run_process_result.stdout)

        print(cleaned_command_result)
        result = None if (cleaned_command_result is None) or (cleaned_command_result == '') else json.loads(cleaned_command_result)

        log(f"Succeeded running command: {cmd}")

    return result


def display_app_result(subscription_id, tenant_id, app_registration_id, client_secret):
    """
    Display the result of the subscription and service principal.

    Args:
        subscription_id (str): The subscription id.
        tenant_id (str): The tenant id.
        app_registration_id (str): The application registration id associated with the service principal.
        client_secret (str): The client secret associated with the service principal.

    Returns:
        None
    """
    log("Your credentials details:")
    log(f"Application Registration ID: {app_registration_id}")
    log(f"Client Secret: {client_secret}")
    log(f"Tenant ID: {tenant_id}")
    log(f"Subscription ID: {subscription_id}")


def set_azure_credentials(
    token, account_id, client_id, client_secret, tenant_id, subscription_id
):
    """
    Set Azure credentials to Spot Account

    Args:
        token (str): Spotinst API token
        account_id (str): Spotinst account ID
        client_id (str): Azure client ID
        client_secret (str): Azure client secret
        tenant_id (str): Azure tenant ID
        subscription_id (str): Azure subscription ID

    Returns:
        bool: True if credentials were set successfully, False otherwise
    """
    log(f"Updating linked credentials for Spot account {account_id}")
    try:
        session = SpotinstSession(auth_token=token, base_url=SPOT_API_BASE_URL)
        client = session.client("setup_azure", timeout=15)
        client.account_id = account_id
        azure_credentials = AzureCredentials(
            client_id=client_id,
            client_secret=client_secret,
            tenant_id=tenant_id,
            subscription_id=subscription_id,
        )
        result = client.set_credentials(azure_credentials)
    except SpotinstClientException as e:
        # the new credentials may have failed to be validated because of Azure propagation latency. try again after a brief delay
        time.sleep(15)
        result = client.set_credentials(azure_credentials)

    log(f"Successfully updated linked credentials.")
    return result


# todo nir - from where take the file in case of using --path param
def build_custom_role(custom_role_name, custom_role_json_local_path, subscription):
    """
    Builds a custom role using the provided custom role name, custom role JSON local path, and subscription.

    Args:
        custom_role_name (str): The name of the custom role.
        custom_role_json_local_path (str): The local path to the custom role JSON file. If None, the custom role will be retrieved from S3.
        subscription (str): The subscription ID.

    Returns:
        str: The built custom role as a string.

    Raises:
        FileNotFoundError: If the custom role JSON file is not found at the specified local path.
        requests.exceptions.RequestException: If there is an error retrieving the custom role from S3.

    """
    if custom_role_json_local_path is not None:
        with open(custom_role_json_local_path) as json_file:
            result = (
                str(json.load(json_file))
                .replace(SUBSCRIPTION_ID, subscription)
                .replace(CUSTOM_ROLE_NAME, custom_role_name)
            )
    else:
        get_custom_role_from_s3_response = requests.get(CORE_PRODUCT_CUSTOM_ROLE_URL)

        if get_custom_role_from_s3_response.status_code in HTTP_OK_RESPONSE_STATUSES:
            result = (
                str(get_custom_role_from_s3_response.json())
                .replace(SUBSCRIPTION_ID, subscription)
                .replace(CUSTOM_ROLE_NAME, custom_role_name)
            )

    return result


def get_roles_for_products(products, custom_role_name, custom_role_json_local_path, subscription):
    roles = []
    if Products.CORE in products:
        custom_role_name = get_or_create_custom_role(
            custom_role_name, custom_role_json_local_path, subscription
        )
        roles.append(custom_role_name)

    if Products.COST_INTELLIGENCE in products:
        # cost intelligence requires the Azure built-in READER role
        roles.append(BuiltInAzureRoles.READER)
    
    return roles


def create_client_secret(app_registration_id, credential_name):
    """
    Create a secret for the App Registration

    Parameters:
    - app_registration_id (str): The ID of the app registration.
    - credential_name (str): The display name to use for the credential.

    Returns:
    - create_secret_result (dict): The result of creating the secret for the app registration.
    """
    create_secret_cmd = f"az ad app credential reset --id {app_registration_id} --append --display-name {credential_name}"
    result = run_command(create_secret_cmd)

    return (result["appId"], result["password"], result["tenant"])


def assign_roles(app_registration_id, roles, subscription):
    """
    Assign the roles to the service principal.

    Parameters:
    - app_registration_id (str): The app registration id for the service principal.
      see https://learn.microsoft.com/en-us/cli/azure/role/assignment?view=azure-cli-latest#az-role-assignment-create
    - roles (list(str)): The names of the roles to assign to the service principal.
    - subscription (str): The ID of the subscription.
    """
    # Get the object_id for the service principal. This is used with --assignee-object-id to avoid errors caused by propagation latency in AAD Graph.
    # see https://learn.microsoft.com/en-us/cli/azure/role/assignment?view=azure-cli-latest#az-role-assignment-create
    get_app_object_id_cmd = f"az ad sp show --id {app_registration_id}"
    object_id_result = run_command(get_app_object_id_cmd)
    app_object_id = object_id_result.get('id')

    for role in roles:
        app_reg_role_assignment_cmd = f"az role assignment create --assignee-object-id {app_object_id} --assignee-principal-type ServicePrincipal"
        try:
            run_command(app_reg_role_assignment_cmd,
                        "--role", role,
                        "--scope", f"/subscriptions/{subscription}")
        except:
            # the role assignment may have failed because of propagation latency. try again after a brief delay
            time.sleep(15)
            run_command(app_reg_role_assignment_cmd,
                        "--role", role,
                        "--scope", f"/subscriptions/{subscription}")


def does_subscription_exist_for_account(subscription):
    """
    Check if a subscription exists for an account.

    Args:
        subscription (str): The ID of the subscription to check.

    Returns:
        bool: True if the subscription exists for the account, False otherwise.
    """
    get_account_cmd = "az account list --all"
    accounts = list(run_command(get_account_cmd))
    account_property_with_subscription = next(
        (account for account in accounts if account["id"] == subscription), None
    )

    if account_property_with_subscription is not None:
        log(f"Found the subscription: {subscription} for account: {account_property_with_subscription}")
        return True
    else:
        return False


def create_service_principal(service_principal_name):
    """
    Creates a new app registration and corresponding service principal.

    Args:
        service_principal_name (str): The name of the service principal.

    Returns:
        (str1, str2, str3) where:
            str1: The ID of the app registration.
            str2: The client secret that is the result of creating the service principal
            str3: The tenant id where app registration and service principal reside
    """
    log("Creating service principal")
    create_service_principal_cmd = f"az ad sp create-for-rbac"

    result = run_command(create_service_principal_cmd,
                         "--name", service_principal_name)

    log(f"Finished creating service principal: {result}")

    return (result["appId"], result["password"], result["tenant"])


def get_or_create_custom_role(custom_role_name, custom_role_json_local_path, subscription):
    """
    Creates a custom role with the given parameters if the role does not already exist.

    Args:
        custom_role_name (str): The name of the custom role.
        custom_role_json_local_path (str): The local path to the custom role JSON file.
        subscription (str): The subscription to create the custom role in.

    Returns:
        str: The name of the created custom role.

    Raises:
        KeyError: If the 'roleName' key is not present in the response from the 'create_custom_role_cmd' command.
    """
    get_custom_role_cmd = f'az role definition list --custom-role-only true'
    get_custom_role_response = run_command(
        get_custom_role_cmd,
        "--scope", f"subscriptions/{subscription}",
        "--name", custom_role_name
    )
    role_already_exists = get_custom_role_response is not None and len(get_custom_role_response) > 0

    if not role_already_exists:
        custom_role = build_custom_role(
            custom_role_name, custom_role_json_local_path, subscription
        )

        # the spot core product custom role is defined in the REST API format (slightly different from the CLI format)
        # so use the az rest command
        custom_role_id = uuid.uuid4()
        create_custom_role_cmd = "az rest --method put"
        create_custom_role_response = run_command(
            create_custom_role_cmd,
            "--url", f"https://management.azure.com/subscriptions/{subscription}/providers/Microsoft.Authorization/roleDefinitions/{custom_role_id}?api-version=2022-04-01",
            "--body", custom_role
        )
        result = create_custom_role_response["properties"]["roleName"]

        ''' If using a custom role in the CLI format, use the `az role definition create` command
        create_custom_role_cmd = "az role definition create"
        create_custom_role_response = run_command(
            create_custom_role_cmd, "--role-definition", custom_role
        )
        result = create_custom_role_response["roleName"]
        '''

        log(f"Finished to create custom role: {result}")
    else:
        result = get_custom_role_response[0]["roleName"]
        log(f"Found already existing custom role: {result}")

    return result


def login_to_azure():
    """
    Logs in to Azure by executing the `az login` command.

    This function opens a web page prompting the user to login to their Azure account. Once the user
    is authenticated, the function executes the `az login` command to complete the login process.

    Parameters:
    None

    Returns:
    None
    """
    log("Please login to azure (Web page should be opened)")
    azure_login_cmd = "az login"
    run_command(azure_login_cmd)


def ensure_azure_cli_automatic_extension_install_enabled():
    """
    Some of the Azure CLI commands used by this script require az cli extensions.
    If an extended command is run without extensions installed, the cli will prompt
    to install the extension, getting in the way of the script.  This configuration
    lets the script proceed without prompting, and automatically installs the required
    extension.
    """
    run_command('az config set',
                'extension.use_dynamic_install=yes_without_prompt')


def check_azure_cli_installed():
    """
    Checks if the Azure CLI is installed by running the 'az' command.

    :return: None
    :raises Exception: If the 'az' command is not found
    """
    az_cmd = "az"
    exit_code = subprocess.call(
        az_cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, shell=run_in_shell
    )
    if exit_code != 0:
        raise Exception(
            "'az' command not found. Please install the Azure CLI and try again."
        )


def register_products(spot_account_id, token, products):
    """
    Enrolls the spot account in the specified Spot products by communicating with the Spot api.
    Args:
        spot_account_id: The Spot account to enroll products for.
        token: The Spot api token.
        products: A string representing which products to enroll in.
    """
    session = SpotinstSession(auth_token=token, base_url=SPOT_API_BASE_URL)
    client = Client(session=session.session)
    if Products.COST_INTELLIGENCE in products:
        log(f"Enrolling Spot Account {spot_account_id} in Cost Intelligence.")

        client.send_post(url=SPOT_SETUP_CI_PATH,
                         body=json.dumps({"account": {"accountId": spot_account_id}}),
                         entity_name="cost-intelligence-enrollment")


def parse_args():
    """
    Retrieve the command line arguments.
    """
    parser = argparse.ArgumentParser(
        description="Create required parameters for Spot registration"
    )

    # Target Azure subscriptions
    parser.add_argument("--subscription", required=False, help="Azure Subscription ID to connect to Spot account. If unspecified all subscriptions in current tenant will be onboarded.")
    parser.add_argument("--subscriptionFileName", required=False, help="File path to csv list of subscriptions to connect to Spot accounts.")
    
    # Spot configuration
    parser.add_argument("--token", required=True, help="Spot organization token.")
    parser.add_argument("--products", required=False, help="Products to register (e.g. core, cost-intelligence)")

    # Azure resource configuration
    parser.add_argument("--skipResourceCreation", default=False, action="store_true", help="Skip creating any resources in Azure.  Only creates Spot resources.")
    parser.add_argument("--customRoleName", default="Spot-CoreRole", required=False, help="Name to use for the custom role.")
    parser.add_argument("--customRoleJsonPath", required=False, help="Custom role Json file path. If specified will not use the default role.")
    parser.add_argument("--appRegistrationId", required=False, help="Existing App Registration ID. If specified will not create a new app registration.")
    parser.add_argument("--clientSecret", required=False, help="Client secret for the app registration. If specified will not create a new client secret.")

    # other options    
    parser.add_argument('--shell', default=False, action='store_true',
        help="The command will be executed through the shell. May be helpful if seeing errors when running in Windows.")

    args = parser.parse_args()

    # custom argument validation
    if args.skipResourceCreation and not (args.appRegistrationId and args.clientSecret):
        parser.error("Argument --skipResourceCreation requires --appRegistrationId and --clientSecret to be specified.")

    return args


def main():
    # command line arguments
    args = parse_args()

    # shell configuration
    global run_in_shell
    run_in_shell = args.shell

    # assign args
    if args.skipResourceCreation:
        log("Argument `--skipResourceCreation` specified, no Azure resources will be created.")

    subscription_id = args.subscription
    if subscription_id is None:
        log("Optional argument `--subscription` not specified, looking for csv list or will default to tenant scope.")
        if args.subscriptionFileName != "":
            subscription_id_list_file_name = args.subscriptionFileName
            log("will look for csv file in local path and try to open")
    
    if subscription_id is None:
        log("Optional argument `--subscription` not specified, defaulting to tenant scope.")
        
    products = args.products
    if products is None:
        log("Optional argument `--product` not specified, defaulting to `core` product.")
        products = f"{Products.CORE}"

    custom_role_name_base = args.customRoleName
    custom_role_json_local_path = args.customRoleJsonPath

    if not args.skipResourceCreation and custom_role_json_local_path is None:
        log("Optional argument `--customRoleJsonPath` not specified, using recommended custom role definition.")

    token = args.token
    app_registration_id = args.appRegistrationId
    client_secret = args.clientSecret

    try:
        check_azure_cli_installed()

        # Subscriptions / tenant
        tenant_id = get_active_tenant()
        if subscription_id:
            subscription_ids = [subscription_id]
        elif subscription_id_list_file_name:
            f = open(subscription_id_list_file_name, 'r') 
            data = f.read()
            subscription_ids = str.split(data,"\n")
            f.close()
        else:
            ensure_azure_cli_automatic_extension_install_enabled()
            subscription_ids = get_all_subscriptions_in_tenant()
            log(f"Found {len(subscription_ids)} subscriptions in tenant.")

        # App registration
        if not args.skipResourceCreation:
            service_principal_name = "Spot-App"
            should_create_app = args.appRegistrationId is None
            if should_create_app:
                # create the app registration
                (app_registration_id, client_secret, tenant) = create_service_principal(service_principal_name)
            else:
                # if the client secret was not supplied, create a new one
                should_reset_client_secret = client_secret is None
                if should_reset_client_secret:
                    (app_registration_id, client_secret, tenant) = create_client_secret(app_registration_id, service_principal_name)

        number_successfully_onboarded = 0
        failed_subscriptions = []

        # process each subscription specified
        for index, subscription_id in enumerate(subscription_ids):
            try:
                subscription_name = get_subscription_name(subscription_id)
                log(f"Onboarding subscription {index+1} of {len(subscription_ids)} ({subscription_name} - {subscription_id})")

                account_id = get_or_create_spot_account(subscription_id, subscription_name, token)
                
                # only create Azure resources (app registration, client secret, custom role, et al.) if specified
                if not args.skipResourceCreation:
                    custom_role_name = f"{custom_role_name_base}_{account_id}"
                    roles = get_roles_for_products(products, custom_role_name, custom_role_json_local_path, subscription_id)
                    
                    # assign the roles to the service principal
                    assign_roles(app_registration_id, roles, subscription_id)

                # set the credentials in Spot
                set_azure_credentials(
                    token,
                    account_id,
                    app_registration_id,
                    client_secret,
                    tenant_id,
                    subscription_id,
                )

                # register the selected products in Spot
                register_products(account_id, token, products)

                if not args.clientSecret:
                    display_app_result(subscription_id, tenant_id, app_registration_id, client_secret)

                log(f"Completed onboarding subscription {index+1} of {len(subscription_ids)} ({subscription_name} - {subscription_id})\n")
                number_successfully_onboarded += 1

            except SpotinstClientException as e:
                # the spotinst token is invalid. halt all onboarding
                log(f"Spot client exception.  Error: {str(e)}")
                failed_subscriptions.append((subscription_id, subscription_name))
                break
            except ConnectTimeout as e:
                # the Spot API cannot be reached.  halt all onboarding
                log(f"Spot client connection has timed out.  Error: {str(e)}")
                failed_subscriptions.append((subscription_id, subscription_name))
                break
            except Exception as e:
                '''
                a non-transaction breaking exception occurred. stop processing this subscription but continue if
                there are more subscriptions to be processed
                '''
                log(
                    f"Error occurred during onboarding process for subscription {subscription_name} - {subscription_id}. Reason: {str(e)}",
                    LogLevel.ERROR,
                )
                failed_subscriptions.append((subscription_id, subscription_name))
                continue

        # print the summary here
        log("Operation completed.  Summary:")
        log(f"    Number of subscriptions attempted:                {len(subscription_ids)}")
        log(f"    Number of subscriptions onboarded successfully:   {number_successfully_onboarded}")
        log(f"    Number of subscriptions onboard was unsuccessful: {len(failed_subscriptions)}")
        if len(failed_subscriptions) > 0:
            log(f"    List of subscriptions onboard was unsuccessful:")
            for subscription_name, subscription_id in failed_subscriptions:
                log(f"        {subscription_name} - {subscription_id}")
    except Exception as e:
        log(f"A general error occurred during onboarding. Errors: {e}", LogLevel.ERROR)

if __name__ == "__main__":
    main()
