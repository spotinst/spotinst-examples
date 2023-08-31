#!/usr/bin/env

import argparse
import json
import re
import subprocess
import time

import requests
from azure.identity import DefaultAzureCredential
from azure.mgmt.subscription import SubscriptionClient
from spotinst_sdk2 import SpotinstSession
from spotinst_sdk2.models.setup.azure import *

CUSTOM_ROLE_NAME = "{customRoleName}"
SUBSCRIPTION_ID = "{subscriptionId}"
CUSTOM_ROLE_PERMISSION_URL = (
    "https://nirtest2.s3-us-west-2.amazonaws.com/custom_role_file.json"
)
HTTP_OK_RESPONSE_STATUSES = range(200, 300)


def get_subscription_name(subscription_id):
    """
    Retrieves the display name of a subscription based on the given subscription ID.

    Parameters:
        subscription_id (str): The ID of the subscription.

    Returns:
        str: The display name of the subscription.
    """
    credential = DefaultAzureCredential()
    subscription_client = SubscriptionClient(credential)
    subscription = subscription_client.subscriptions.get(subscription_id)
    return subscription.display_name


def create_spot_account(name, token):
    """
    Creates a spot account with the given name and token.

    Args:
        name (str): The name of the spot account.
        token (str): The authentication token.

    Returns:
        str: The ID of the created account.
    """
    session = SpotinstSession(auth_token=token)
    client = session.client("admin")
    account_result = client.create_account(name)
    return account_result["id"]


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
        >>> run_command("ls", "-l")
        {'file1.txt': 'rw-r--r--', 'file2.txt': 'rw-rw-r--'}
    """
    print(f"Run command: {cmd}")

    cmd_args = cmd.split()
    cmd_to_run = cmd_args + list(args)

    run_process_result = subprocess.run(
        cmd_to_run, stdout=subprocess.PIPE, stderr=subprocess.PIPE, encoding="utf-8"
    )  # Maybe need to change to check output because in python5 there isn't encoding

    # try:
    #    output = subprocess.check_output(
    #        cmnd, stderr=subprocess.STDOUT)
    # except subprocess.CalledProcessError as exc:
    #    print("Status : FAIL", exc.returncode, exc.output)
    # else:
    #    print(f"Output: \n{output}\n")

    if run_process_result.returncode != 0:
        raise Exception(
            f"Failed to run the command: {cmd}. Errors: {run_process_result.stderr}"
        )
    else:
        # Remove ANSI escape sequences from a string
        ansi_escape = re.compile(r"\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])")
        cleaned_command_result = ansi_escape.sub("", run_process_result.stdout)

        result = json.loads(cleaned_command_result)

        print("Succeeded to run command: {cmd}")

    return result


def display_result(subscription, create_or_get_service_principal_response):
    """
    Display the result of the subscription and create/get service principal response.

    Args:
        subscription (str): The subscription ID.
        create_or_get_service_principal_response (dict): The response from the create or get service principal API.

    Returns:
        None
    """
    print("Your credentials details:")
    print(f"Application (client) ID: {create_or_get_service_principal_response['appId']}")
    print(f"Client Secret: {create_or_get_service_principal_response['password']}")
    print(f"Tenant ID: {create_or_get_service_principal_response['tenant']}")
    print(f"Subscription ID: {subscription}")


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
    session = SpotinstSession(auth_token=token)
    client = session.client("setup_azure")
    client.account_id = account_id
    azure_credentials = AzureCredentials(
        client_id=client_id,
        client_secret=client_secret,
        tenant_id=tenant_id,
        subscription_id=subscription_id,
    )
    return client.set_credentials(azure_credentials)


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
        get_custom_role_from_s3_response = requests.get(CUSTOM_ROLE_PERMISSION_URL)

        if get_custom_role_from_s3_response.status_code in HTTP_OK_RESPONSE_STATUSES:
            result = (
                str(get_custom_role_from_s3_response.json())
                .replace(SUBSCRIPTION_ID, subscription)
                .replace(CUSTOM_ROLE_NAME, custom_role_name)
            )

    return result


def create_required_parameters_for_spot_registrations(
    subscription,
    custom_role_name,
    custom_role_json_local_path,
    service_principal_name,
    app_registration_id=None,
):
    if does_subscription_exist_for_account(subscription):
        custom_role_name = create_custom_role(
            custom_role_name, custom_role_json_local_path, subscription
        )
        print("Waiting 90 seconds for role to propagate.")
        time.sleep(90)
        if app_registration_id is not None:
            create_or_get_service_principal_response = get_service_principal(
                app_registration_id, custom_role_name, subscription, service_principal_name
            )
        else:
            create_or_get_service_principal_response = create_service_principal(
                custom_role_name, service_principal_name, subscription
            )

        result = create_or_get_service_principal_response
    else:
        raise Exception("Could not find the subscription in account subscriptions")

    return result


def get_service_principal(app_registration_id, custom_role_name, subscription, spot_account_id):
    """
    Generate a service principal for the given app registration ID, assign a custom role to the service principal, create a secret for the app registration, and return the result of creating the secret.

    Parameters:
    - app_registration_id (str): The ID of the app registration.
    - custom_role_name (str): The name of the custom role to assign to the service principal.
    - subscription (str): The ID of the subscription.

    Returns:
    - create_secret_result (dict): The result of creating the secret for the app registration.
    """
    app_reg_show_cmd = f"az ad sp show --id {app_registration_id}"
    run_command(app_reg_show_cmd)

    # Assign the custom role to the service principal
    app_reg_role_assignment_cmd = f"az role assignment create --assignee {app_registration_id} --role {custom_role_name} --scope /subscriptions/{subscription}"
    run_command(app_reg_role_assignment_cmd)

    # Create a secret for the App Registration
    create_secret_cmd = f"az ad app credential reset --id {app_registration_id} --append --display-name {spot_account_id}"
    create_secret_result = run_command(create_secret_cmd)

    return create_secret_result

def does_subscription_exist_for_account(subscription):
    """
    Check if a subscription exists for an account.

    Args:
        subscription (str): The ID of the subscription to check.

    Returns:
        bool: True if the subscription exists for the account, False otherwise.
    """
    get_account_cmd = "az account list --output json --all"
    accounts = list(run_command(get_account_cmd))
    account_property_with_subscription = next(
        (account for account in accounts if account["id"] == subscription), None
    )

    if account_property_with_subscription is not None:
        print(f"Found the subscription: {subscription} for account: {account_property_with_subscription}")
        return True
    else:
        return False


def create_service_principal(custom_role_name, service_principal_name, subscription):
    """
    Creates a service principal with the given custom role name, service principal name, and subscription.

    Args:
        custom_role_name (str): The name of the custom role.
        service_principal_name (str): The name of the service principal.
        subscription (str): The subscription ID.

    Returns:
        str: The result of creating the service principal.
    """
    print("Create service principal")
    create_service_principal_cmd = f"az ad sp create-for-rbac --name {service_principal_name} --role {custom_role_name} --scopes /subscriptions/{subscription}"
    result = run_command(create_service_principal_cmd)

    print(f"Finished to create service principal: {result}")

    return result


def create_custom_role(custom_role_name, custom_role_json_local_path, subscription):
    """
    Creates a custom role with the given parameters.

    Args:
        custom_role_name (str): The name of the custom role.
        custom_role_json_local_path (str): The local path to the custom role JSON file.
        subscription (str): The subscription to create the custom role in.

    Returns:
        str: The name of the created custom role.

    Raises:
        KeyError: If the 'roleName' key is not present in the response from the 'create_custom_role_cmd' command.
    """
    print("Create custom role")
    custom_role = build_custom_role(
        custom_role_name, custom_role_json_local_path, subscription
    )
    create_custom_role_cmd = "az role definition create"
    create_custom_role_response = run_command(
        create_custom_role_cmd, "--role-definition", custom_role
    )

    result = create_custom_role_response["roleName"]
    print(f"Finished to create custom role: {result}")

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
    print("Please login to azure (Web page should be opened)")
    azure_login_cmd = "az login"
    run_command(azure_login_cmd)


def check_azure_cli_installed():
    """
    Checks if the Azure CLI is installed by running the 'az' command.

    :return: None
    :raises Exception: If the 'az' command is not found
    """
    az_cmd = "az"
    exit_code = subprocess.call(
        az_cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
    )
    if exit_code != 0:
        raise Exception(
            "'az' command not found. Please install the Azure CLI and try again."
        )


def main():
    parser = argparse.ArgumentParser(
        description="Create required parameters for Spot registration"
    )
    parser.add_argument("--subscription", required=True, help="Azure Subscription ID")
    parser.add_argument("--token", required=True, help="Spot Organization Token")
    parser.add_argument("--customRoleName", required=True, help="Custom Role Name")
    parser.add_argument(
        "--customRoleJsonPath", required=False, help="Custom Role Json File Path"
    )
    parser.add_argument(
        "--appRegistrationId", required=False, help="Existing App Registration ID"
    )
    args = parser.parse_args()

    subscription = args.subscription
    token = args.token
    custom_role_name = args.customRoleName
    custom_role_json_local_path = args.customRoleJsonPath

    if custom_role_json_local_path is None:
        print("WARNING: --customRoleJsonPath not found, using default.")

    print(f"Start creating required credentials parameters for Spot registration. Subscription: {subscription}")

    try:
        check_azure_cli_installed()
        # login_to_azure()
        subscription_name = get_subscription_name(subscription)
        account_id = create_spot_account(subscription_name, token)
        service_principal_name = f"Spot-{subscription_name}-{account_id}".replace(" ", "")
        required_parameters_response = (
            create_required_parameters_for_spot_registrations(
                subscription,
                custom_role_name,
                custom_role_json_local_path,
                service_principal_name,
                args.appRegistrationId,
            )
        )
        if account_id is not None and token is not None:
            set_azure_credentials(
                token,
                account_id,
                required_parameters_response["appId"],
                required_parameters_response["password"],
                required_parameters_response["tenant"],
                subscription,
            )
        display_result(subscription, required_parameters_response)

        print("Finished creating required credentials parameters for Spot registration")
    except Exception as e:
        print(f"Failed to create required credentials. Errors: {e}")


if __name__ == "__main__":
    main()
