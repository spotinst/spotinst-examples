# Credentials setup: Trident and Azure NetApp Files

This guide explains how to obtain the Trident-related values used by
`scripts/deploy-workloads.sh`:

```
trident_principal_object_id  = "00000000-0000-0000-0000-000000000000"
```

Copy `terraform.tfvars.example` to the ignored `terraform.tfvars` and replace
the Terraform placeholders. Export `TRIDENT_CLIENT_ID`,
`TRIDENT_CLIENT_SECRET`, and `SPOTINST_TOKEN` only in the shell used to run the
deployment script.

## `trident_client_id`, `trident_principal_object_id`, and `trident_client_secret`

These identify a Microsoft Entra ID (Azure AD) app registration/service
principal that NetApp Trident uses to call the Azure NetApp Files API. Terraform
grants this principal the `NetApp Contributor` role on the resource group
(see [`terraform/anf.tf`](../terraform/anf.tf)).

### Create the app registration and secret

Using the Azure CLI directly:

```sh
az ad sp create-for-rbac --name "trident-anf-<cluster-name>" \
  --skip-assignment
```

The command output contains:

- `appId` → use as `TRIDENT_CLIENT_ID`
- `password` → use as `TRIDENT_CLIENT_SECRET` (shown only once; store it securely)
- `tenant` → should match your `tenant_id` value

To find the corresponding **object ID** of the service principal (not the
`appId`) for `trident_principal_object_id` in `terraform.tfvars`:

```sh
az ad sp show --id <appId> --query id -o tsv
```

This project also provides [scripts/create-trident-identity.sh](../scripts/create-trident-identity.sh), which performs these steps and prints the values needed by Terraform and `scripts/deploy-workloads.sh`:

```sh
cd /path/to/OceanAKS
export SUBSCRIPTION_ID="<subscription-id>"
export CLUSTER_NAME="<cluster-name>"
./scripts/create-trident-identity.sh
```

The script requires Azure CLI, `jq`, and an authenticated Azure CLI session.
It creates a new service principal with `--skip-assignment`; Terraform assigns
it `NetApp Contributor` during the infrastructure apply. The generated client
secret is printed once and is not written to a file. Save it only in a secure
secret manager or export it in the shell used for workload deployment.

The identity script prompts for missing values. Set `CONFIRM_INPUTS=true` to
confirm values that are already set, or set `INTERACTIVE=false` to make missing
values fail immediately for automation.

If Azure CLI is already authenticated, the script uses the current subscription
automatically. Set `SUBSCRIPTION_ID` explicitly to override it.

### Or find an existing app registration in the Azure Portal

1. **Microsoft Entra ID > App registrations** to find the application/client
  ID for `TRIDENT_CLIENT_ID` and to create a client secret under
  **Certificates & secrets** for `TRIDENT_CLIENT_SECRET`.
2. **Microsoft Entra ID > Enterprise applications**, search for the app
   registration by name, and copy its **Object ID** for
   `trident_principal_object_id`. This is the service principal object,
   distinct from the application (client) ID.

### Notes

- Do not pre-assign roles with `--skip-assignment` omitted; Terraform's
  `azurerm_role_assignment.trident_netapp_contributor` resource assigns
  `NetApp Contributor` for you.
- Rotate `TRIDENT_CLIENT_SECRET` before it expires (Microsoft Entra app
  secrets have a maximum lifetime).
- Never commit real values for these variables; `terraform.tfvars` is
  git-ignored specifically so secrets stay local.
