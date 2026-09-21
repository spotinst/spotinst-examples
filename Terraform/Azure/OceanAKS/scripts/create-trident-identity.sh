#!/usr/bin/env bash
set -euo pipefail

INTERACTIVE="${INTERACTIVE:-true}"
CONFIRM_INPUTS="${CONFIRM_INPUTS:-false}"
TRIDENT_IDENTITY_NAME="${TRIDENT_IDENTITY_NAME:-trident-anf-${CLUSTER_NAME:-aks-ocean}}"
SECRET_YEARS="${SECRET_YEARS:-1}"

command -v az >/dev/null || { printf 'Azure CLI is required\n' >&2; exit 1; }
if [[ -z "${SUBSCRIPTION_ID:-}" ]]; then
  SUBSCRIPTION_ID="$(az account show --query id -o tsv 2>/dev/null || true)"
fi

read_input() {
  local variable_name="$1"
  local prompt_text="$2"
  local current_value="${!variable_name:-}"
  local answer

  while true; do
    if [[ -n "$current_value" ]]; then
      if [[ "$CONFIRM_INPUTS" != "true" || "$INTERACTIVE" != "true" ]]; then
        printf -v "$variable_name" '%s' "$current_value"
        return
      fi

      read -r -p "$prompt_text [$current_value]. Use it? [Y/n] " answer
      case "$answer" in
        [nN]*) current_value=""; printf -v "$variable_name" '%s' ""; continue ;;
        *) printf -v "$variable_name" '%s' "$current_value"; return ;;
      esac
    fi

    if [[ "$INTERACTIVE" != "true" ]]; then
      printf '%s must be set when INTERACTIVE=false\n' "$variable_name" >&2
      exit 1
    fi

    read -r -p "$prompt_text: " current_value
    if [[ -z "$current_value" ]]; then
      printf '%s cannot be empty\n' "$variable_name" >&2
      continue
    fi
    printf -v "$variable_name" '%s' "$current_value"
    return
  done
}

read_input SUBSCRIPTION_ID "Azure subscription ID"
read_input TRIDENT_IDENTITY_NAME "Trident service principal name"
read_input SECRET_YEARS "Client secret lifetime in years"

command -v jq >/dev/null || { printf 'jq is required\n' >&2; exit 1; }

az account set --subscription "$SUBSCRIPTION_ID"
az account show --query '{subscription:id, tenant:tenantId, user:user.name}' -o table

printf 'Creating Microsoft Entra service principal %s...\n' "$TRIDENT_IDENTITY_NAME"
credentials_json="$(az ad sp create-for-rbac \
  --name "$TRIDENT_IDENTITY_NAME" \
  --skip-assignment \
  --years "$SECRET_YEARS" \
  --output json)"

client_id="$(jq -r '.appId' <<<"$credentials_json")"
client_secret="$(jq -r '.password' <<<"$credentials_json")"
tenant_id="$(jq -r '.tenant' <<<"$credentials_json")"
principal_object_id="$(az ad sp show --id "$client_id" --query id -o tsv)"

if [[ -z "$client_id" || "$client_id" == "null" || -z "$client_secret" || "$client_secret" == "null" || -z "$principal_object_id" ]]; then
  printf 'Azure CLI did not return all required identity values.\n' >&2
  exit 1
fi

printf '\nIdentity created successfully. The secret is shown only once.\n'
printf '\nAdd this value to terraform/terraform.tfvars:\n'
printf 'trident_principal_object_id = "%s"\n' "$principal_object_id"
printf '\nExport these values in the shell used to run scripts/deploy-workloads.sh:\n'
printf 'export TRIDENT_CLIENT_ID="%s"\n' "$client_id"
printf 'export TRIDENT_CLIENT_SECRET="%s"\n' "$client_secret"
printf '\nUse this tenant value for TENANT_ID if needed:\n'
printf 'export TENANT_ID="%s"\n' "$tenant_id"
printf '\nTerraform will assign NetApp Contributor to this service principal.\n'
printf 'Do not commit the client secret or save this output in a tracked file.\n'
