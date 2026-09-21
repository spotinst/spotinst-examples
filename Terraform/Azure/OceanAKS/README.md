# Azure AKS Spot Ocean test project

This project provisions an AKS cluster, Spot Ocean capacity, automatic Ocean rightsizing, Azure NetApp Files Ultra capacity, and example Kubernetes workloads. Terraform creates the Azure infrastructure; [`scripts/deploy-workloads.sh`](scripts/deploy-workloads.sh) installs the required Helm charts and applies the Kubernetes resources directly to AKS.

## Prerequisites

- Azure subscription permissions for AKS, networking, Azure NetApp Files, and `NetApp Contributor` role assignments.
- Terraform 1.x, Azure CLI authentication, `kubectl`, Helm, and `jq`.
- `SPOTINST_TOKEN` and `TRIDENT_CLIENT_SECRET` supplied outside tracked files.
- See [`docs/CREDENTIALS.md`](docs/CREDENTIALS.md) for the Trident service principal values.
- See [`docs/TRIDENT_ANF_SETUP.md`](docs/TRIDENT_ANF_SETUP.md) for the complete Trident and Azure NetApp Files setup.

## Important migration note

The original cluster used managed `kubenet` networking without a customer VNet. This configuration moves AKS to a dedicated VNet/subnet so the delegated Azure NetApp Files subnet is reachable. Review `terraform plan` carefully because Azure may replace the existing AKS cluster during this network change.

## Apply order

Copy `terraform.tfvars.example` to the ignored `terraform.tfvars` file and set customer-specific values. Review [`docs/DEPLOYMENT_STAGES.md`](docs/DEPLOYMENT_STAGES.md) and [`docs/TRIDENT_ANF_SETUP.md`](docs/TRIDENT_ANF_SETUP.md) before applying the AKS networking migration.

Create the Trident service principal before the infrastructure apply:

```sh
az login
export SUBSCRIPTION_ID="<subscription-id>"
export CLUSTER_NAME="<aks-cluster-name>"
./scripts/create-trident-identity.sh
```

Put the printed `trident_principal_object_id` in `terraform/terraform.tfvars`.
Keep the printed client ID and secret available for the workload deployment.

Apply the Azure infrastructure:

```sh
cd terraform
terraform init
terraform plan
terraform apply
cd ..
```

After Terraform creates the infrastructure, deploy the charts and example workload. Azure CLI can discover the subscription, tenant, resource group, region, VNet, and delegated ANF subnet. The script prompts for values it cannot discover:

```sh
export TRIDENT_CLIENT_ID="<trident-client-id>"
export TRIDENT_CLIENT_SECRET="<trident-client-secret>"
export SPOTINST_ACCOUNT="<spot-account>"
export SPOTINST_TOKEN="<spot-token>"
./scripts/deploy-workloads.sh
./scripts/validate-workloads.sh
```

`deploy-workloads.sh` prompts for missing values and hides secret input. Set
`CONFIRM_INPUTS=true` to verify values already present in the environment, or
set `INTERACTIVE=false` for non-interactive automation.

When authenticated with Azure CLI, the script prepopulates the subscription
and tenant, then discovers the resource group, region, AKS VNet, and delegated
ANF subnet from the selected cluster. Explicit environment variables override
these discovered values. Trident client credentials and Spot credentials are
never discoverable from this script and must be supplied manually.

The deployment script creates the namespaces and secrets, installs Trident, monitoring, and Spot Ocean Helm releases, configures ANF storage, and applies the web workload. The validation script verifies AKS nodes, Trident, Spot Ocean, monitoring, ANF storage, PVC binding, the web page, and timestamped logs.

The `trident-azure-credentials` and `spotinst-credentials` Kubernetes secrets are created by the deployment script from environment variables. Do not commit those values.

## Project layout

- `terraform/`: Terraform providers, infrastructure, AKS, ANF, Ocean, and configuration examples.
- `terraform/terraform.tfvars.example`: tracked customer configuration template.
- `terraform/terraform.tfvars`: ignored local configuration and secret placeholders.
- `scripts/`: executable identity creation, deployment, and validation scripts.
- `docs/`: deployment, credential, and rollback documentation.
- `.terraform/`, state files, and plan files: local Terraform runtime artifacts; do not commit them.
