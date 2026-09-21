# Deployment stages

Run commands from the project directory:

```sh
cd /path/to/OceanAKS
```

The existing AKS cluster was created with managed `kubenet` networking and no
customer VNet. Azure NetApp Files requires AKS to use a customer VNet with a
delegated ANF subnet, so review the Terraform plan carefully because this
network migration can replace the cluster and its node pools.

## 1. Apply infrastructure

Copy and configure the Terraform variables:

```sh
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
cd terraform
terraform init
terraform plan
terraform apply
cd ..
```

For an existing cluster undergoing the network migration, use targeted
planning/apply first and review the proposed AKS replacement:

```sh
terraform plan -target=azurerm_resource_group.rg \
  -target=azurerm_virtual_network.aks \
  -target=azurerm_subnet.aks \
  -target=azurerm_subnet.anf \
  -target=azurerm_kubernetes_cluster.k8s \
  -target=azurerm_kubernetes_cluster_node_pool.vmss \
  -target=azurerm_netapp_account.aks \
  -target=azurerm_netapp_pool.ultra
terraform apply -target=azurerm_resource_group.rg \
  -target=azurerm_virtual_network.aks \
  -target=azurerm_subnet.aks \
  -target=azurerm_subnet.anf \
  -target=azurerm_kubernetes_cluster.k8s \
  -target=azurerm_kubernetes_cluster_node_pool.vmss \
  -target=azurerm_netapp_account.aks \
  -target=azurerm_netapp_pool.ultra
```

After the targeted apply, run the complete plan/apply from the `terraform/`
directory so Terraform creates the remaining Azure resources and the ANF role
assignment.

## 2. Create the Trident identity

The identity is separate from Terraform. Create it once with:

```sh
export SUBSCRIPTION_ID="<subscription-id>"
export CLUSTER_NAME="<cluster-name>"
./scripts/create-trident-identity.sh
```

The script prompts for missing values and uses the active Azure CLI
subscription when available. It creates the service principal with no role
assignment and prints:

- `TRIDENT_CLIENT_ID`
- `TRIDENT_CLIENT_SECRET`
- `trident_principal_object_id`

Put only `trident_principal_object_id` in `terraform/terraform.tfvars`. Export
the client ID and secret for the workload deployment. The secret is displayed
once and must not be committed.

## 3. Deploy Kubernetes workloads

Run the deployment script after the AKS cluster and ANF infrastructure exist:

```sh
./scripts/deploy-workloads.sh
```

The script requires Azure CLI, `kubectl`, and Helm. It automatically discovers
the subscription and tenant from Azure CLI, then uses the AKS cluster to find
the resource group, region, VNet, and delegated ANF subnet. It prompts for
values it cannot discover, including the cluster name, Trident credentials,
and Spot credentials.

The script then:

1. Retrieves AKS credentials with `az aks get-credentials`.
2. Creates the Trident, Spot, and monitoring namespaces.
3. Creates the Trident Azure credentials and Spot credentials secrets.
4. Installs Trident, kube-prometheus-stack, and Spot Ocean Helm charts.
5. Creates the `anf-ultra` StorageClass and Trident backend configuration.
6. Applies the sample web workload and its ANF-backed PVC.

Use `CONFIRM_INPUTS=true` to confirm values already set in the environment:

```sh
CONFIRM_INPUTS=true ./scripts/deploy-workloads.sh
```

Use `INTERACTIVE=false` for automation. In that mode, every required value
must already be set:

```sh
INTERACTIVE=false ./scripts/deploy-workloads.sh
```

## 4. Validate

Run the project validation script:

```sh
./scripts/validate-workloads.sh
```

It checks AKS nodes, Trident, Spot Ocean, monitoring, the ANF StorageClass,
PVC binding, the web service, and timestamped logs.

Do not commit `terraform.tfstate`, `terraform.tfstate.backup`, generated plans, or secret-bearing tfvars files. Rotate any Spot token that was previously stored in a tracked or shared tfvars file.