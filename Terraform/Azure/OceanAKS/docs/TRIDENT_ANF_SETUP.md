# Trident and Azure NetApp Files setup

This project uses NetApp Trident as the Kubernetes CSI driver for Azure NetApp
Files (ANF). Terraform creates the Azure networking and ANF capacity. The
`scripts/deploy-workloads.sh` script installs Trident and configures the
Kubernetes-side ANF backend.

## Architecture

```text
AKS
  |
  +-- Customer VNet
       +-- AKS node subnet
       +-- Delegated ANF subnet

Azure NetApp Files account
  +-- Ultra capacity pool
       +-- Volumes dynamically created by Trident

Kubernetes PVC
  -> StorageClass anf-ultra
  -> Trident CSI driver
  -> TridentBackendConfig
  -> Azure NetApp Files Ultra volume
```

The project does not create a fixed `azurerm_netapp_volume` resource. ANF
volumes are provisioned dynamically when Kubernetes creates a PVC.

## Prerequisites

Install and authenticate these tools:

- Azure CLI
- Terraform
- `kubectl`
- Helm
- `jq` for the identity creation script

Authenticate Azure CLI and select the target subscription:

```sh
az login
az account set --subscription "<subscription-id>"
```

The Azure subscription must permit creation of:

- AKS and virtual networks
- Azure NetApp Files accounts and capacity pools
- Resource group role assignments

## 1. Create the Trident identity

Trident needs a Microsoft Entra service principal to manage ANF resources.
Create it with the project script:

```sh
cd /path/to/OceanAKS
export SUBSCRIPTION_ID="<subscription-id>"
export CLUSTER_NAME="<cluster-name>"
./scripts/create-trident-identity.sh
```

The script creates the identity with no role assignment. It prints:

- `TRIDENT_CLIENT_ID`: application/client ID
- `TRIDENT_CLIENT_SECRET`: client secret
- `trident_principal_object_id`: service principal object ID

The client secret is printed once. Store it securely and do not commit it.
Terraform assigns the service principal the `NetApp Contributor` role on the
project resource group during the infrastructure apply.

To confirm an existing service principal object ID:

```sh
az ad sp show --id "<trident-client-id>" --query id -o tsv
```

## 2. Configure Terraform

Copy the example variables file:

```sh
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Set these ANF and identity values in `terraform.tfvars`:

```hcl
trident_principal_object_id = "<service-principal-object-id>"
vnet_name                  = "aks-network"
vnet_address_space         = "10.20.0.0/16"
aks_subnet_name            = "aks-nodes"
aks_subnet_address_prefix  = "10.20.0.0/20"
anf_subnet_name            = "anf-volumes"
anf_subnet_address_prefix  = "10.20.16.0/24"
anf_account_name           = "aksanf"
anf_pool_name              = "ultra"
anf_pool_size_gib          = 4096
```

The ANF subnet must be delegated to `Microsoft.Netapp/volumes`. Terraform
creates this delegation in `terraform/main.tf`.

The `anf_pool_size_gib` value is converted to TiB by Terraform. The default
`4096` GiB creates a 4 TiB Ultra capacity pool.

## 3. Apply Azure infrastructure

Run Terraform from the `terraform/` directory:

```sh
terraform init
terraform plan
terraform apply
```

Review the plan carefully. Moving an existing AKS cluster to a customer VNet
can replace the cluster and node pools.

Terraform creates:

- The resource group
- The customer VNet
- The AKS subnet
- The delegated ANF subnet
- The AKS cluster
- The ANF account
- The ANF Ultra capacity pool
- The `NetApp Contributor` role assignment

## 4. Deploy Trident and configure the backend

Export the Trident and project values required by the deployment script:

```sh
export RESOURCE_GROUP_NAME="<resource-group-name>"
export CLUSTER_NAME="<cluster-name>"
export SUBSCRIPTION_ID="<subscription-id>"
export TENANT_ID="<tenant-id>"
export TRIDENT_CLIENT_ID="<trident-client-id>"
export TRIDENT_CLIENT_SECRET="<trident-client-secret>"
export VNET_NAME="<vnet-name>"
export ANF_SUBNET_NAME="<anf-subnet-name>"
export RESOURCE_GROUP_LOCATION="<azure-region>"
export SPOTINST_ACCOUNT="<spot-account>"
export SPOTINST_TOKEN="<spot-token>"
```

Run:

```sh
cd ..
./scripts/deploy-workloads.sh
```

The script performs these Trident steps:

1. Creates the `trident` namespace.
2. Creates the `trident-azure-credentials` Kubernetes secret.
3. Installs the Trident operator Helm chart.
4. Creates the `anf-ultra` StorageClass.
5. Creates the `azure-netapp-files-ultra` TridentBackendConfig.
6. Applies the sample PVC and workload.

The backend configuration uses:

```yaml
storageDriverName: azure-netapp-files
serviceLevel: Ultra
virtualNetwork: <vnet-name>
subnet: <anf-subnet-name>
nfsMountOptions: nfsvers=4.1
```

## 5. How dynamic provisioning works

The sample workload requests storage with:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: web-logs
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: anf-ultra
  resources:
    requests:
      storage: 20Gi
```

The provisioning sequence is:

1. Kubernetes creates the `web-logs` PVC.
2. The `anf-ultra` StorageClass sends the request to Trident.
3. Trident authenticates with Azure using the Kubernetes secret.
4. Trident uses the ANF backend configuration and Ultra service level.
5. Azure NetApp Files creates a 20 GiB volume from the Ultra pool.
6. Trident creates the Kubernetes PersistentVolume and attaches it to the pod.

The volume uses `ReadWriteMany`, allowing both web replicas to mount the same
ANF-backed filesystem.

## 6. Validate the setup

Check the Trident resources:

```sh
kubectl get pods -n trident
kubectl get tridentbackendconfig -n trident
kubectl describe tridentbackendconfig azure-netapp-files-ultra -n trident
```

Check storage resources:

```sh
kubectl get storageclass anf-ultra
kubectl get pvc -n test-workloads
kubectl get pv
```

The PVC should eventually show `Bound`:

```sh
kubectl wait --for=jsonpath='{.status.phase}'=Bound \
  pvc/web-logs -n test-workloads --timeout=180s
```

Run the project validation script:

```sh
./scripts/validate-workloads.sh
```

## Troubleshooting

### PVC remains Pending

Check Trident pods and backend status:

```sh
kubectl get pods -n trident
kubectl describe pvc web-logs -n test-workloads
kubectl describe tridentbackendconfig azure-netapp-files-ultra -n trident
kubectl logs -n trident deploy/trident-operator
```

Common causes include an incorrect subnet name, a missing ANF subnet
 delegation, an incorrect service principal object ID, or a missing
`NetApp Contributor` role assignment.

### Backend authentication fails

Verify that:

- `TRIDENT_CLIENT_ID` is the application/client ID.
- `TRIDENT_CLIENT_SECRET` belongs to that application.
- `trident_principal_object_id` is the service principal object ID.
- The secret exists in the `trident` namespace.
- The client secret has not expired.

Inspect the secret metadata without printing secret values:

```sh
kubectl get secret trident-azure-credentials -n trident
```

### ANF subnet is not found

List the VNet subnets and verify the delegation:

```sh
az network vnet subnet list \
  --resource-group "<resource-group-name>" \
  --vnet-name "<vnet-name>" \
  -o table
```

The ANF subnet must have a delegation for:

```text
Microsoft.Netapp/volumes
```

Do not commit `terraform.tfvars`, client secrets, Spot tokens, Terraform state,
or generated plan files.
