# Roll Back Spot Ocean on AKS

This example shows the minimum Terraform changes required to return node capacity to Azure-managed AKS node pools and remove Spot Ocean resources.

Replace placeholder values with values from your configuration. Resource names, module names, variable names, and file locations are intentionally omitted.

## Before You Begin

Ensure that:

- Terraform is using the correct backend and workspace.
- Azure credentials can read and update the AKS cluster.
- Spot credentials remain available until Ocean resources are destroyed.
- Workloads have enough capacity during the transition.

Create a backup of the Terraform state using your normal state-management process.

## Restore an AKS Node Pool

For an existing `azurerm_kubernetes_cluster_node_pool`, restore the minimum capacity fields required by the configuration:

```hcl
resource "azurerm_kubernetes_cluster_node_pool" "example" {
  kubernetes_cluster_id = azurerm_kubernetes_cluster.example.id
  name                  = "<pool-name>"
  vm_size               = "<vm-size>"

  node_count          = <approved-node-count>
  auto_scaling_enabled = true
  min_count           = <approved-min-count>
  max_count           = <approved-max-count>
}
```

If the resource already exists, change only the capacity fields. Do not change the cluster ID, pool name, network settings, OS settings, or immutable fields unless replacement is explicitly approved.

If the configuration controls capacity through variables, update only those values instead:

```hcl
node_count = <approved-node-count>
min_count  = <approved-min-count>
max_count  = <approved-max-count>
```

Use the autoscaling argument supported by the installed AzureRM provider. The current resource commonly uses `auto_scaling_enabled`; older configurations may use a different schema.

## Restore Multiple Pools

Repeat the same minimum capacity change for every VMSS-backed user pool that must take over workloads. Do not assume a fixed number of pools or a particular variable collection:

```text
For each approved user pool:
  desired capacity = <approved-node-count>
  minimum capacity = <approved-min-count>
  maximum capacity = <approved-max-count>
  autoscaling      = enabled, if required
```

Keep the minimum above zero until the cluster is stable unless zero capacity is an intentional design requirement.

## Scale Down Ocean Virtual Node Groups

After Azure-managed capacity is ready, scale every Ocean VNG to zero before removing any Spot resource. Change only the VNG capacity fields:

```hcl
resource "spotinst_ocean_aks_np_virtual_node_group" "example" {
  name     = "<vng-name>"
  ocean_id = "<ocean-id>"

  min_count = 0
  max_count = 0
}
```

If the VNG capacity is supplied through variables, set the corresponding minimum and maximum values to zero instead:

```hcl
vng_min_count = 0
vng_max_count = 0
```

Create and apply a separate plan for this scale-down:

```bash
terraform validate
terraform plan -out=<vng-scale-down-plan>
terraform apply <vng-scale-down-plan>
```

Verify that the VNGs are scaled to zero and that workloads have moved to the restored Azure-managed pools. Use the Spot console or API, Azure node-pool status, and Kubernetes node labels according to the customer's normal verification process:

```bash
kubectl get nodes --show-labels
kubectl get pods --all-namespaces
```

Do not remove the Ocean controller, Ocean integration, or VNG resources until the scale-down has completed and the cluster is healthy on Azure-managed capacity.

## Remove the Ocean Controller

Remove the Ocean controller module or resource from the configuration. The minimum module inputs commonly look like this before removal:

```hcl
module "<ocean-controller>" {
  source = "spotinst/kubernetes-controller/ocean"

  spotinst_token   = var.spotinst_token
  spotinst_account = var.spotinst_account
  cluster_identifier = "<cluster-identifier>"
}
```

Delete or comment out the complete block. Remove any output that references the block.

## Remove the Ocean AKS Integration

Remove the Ocean AKS integration module or resource that manages the cluster's Ocean capacity. Its minimum inputs commonly include:

```hcl
module "<ocean-aks>" {
  source = "spotinst/ocean-aks-np-k8s/spotinst"

  spotinst_token   = var.spotinst_token
  spotinst_account = var.spotinst_account

  ocean_cluster_name                     = "<ocean-cluster-name>"
  controller_cluster_id                  = "<controller-cluster-id>"
  aks_cluster_name                       = azurerm_kubernetes_cluster.example.name
  aks_region                             = "<region>"
  aks_resource_group_name                = "<resource-group>"
  aks_infrastructure_resource_group_name = "<node-resource-group>"
}
```

Delete or comment out the complete block. Do not remove the AKS cluster resource.

## Remove Ocean Virtual Node Groups

Remove each `spotinst_ocean_aks_np_virtual_node_group` resource:

```hcl
resource "spotinst_ocean_aks_np_virtual_node_group" "example" {
  name     = "<vng-name>"
  ocean_id = module.<ocean-aks>.ocean_id
}
```

Remove outputs that reference the VNG or Ocean module at the same time.

## Review and Apply

Run validation and create a saved plan:

```bash
terraform validate
terraform plan -out=<plan-file>
```

The plan should:

- Restore the approved capacity on existing AKS user pools.
- Show the Ocean VNG scale-down as a completed prior change, with no Ocean-managed capacity still running.
- Destroy only the Ocean controller, Ocean integration, and Ocean VNG resources.
- Leave the AKS cluster and resource group unchanged.
- Avoid replacing existing node pools.

Apply only after reviewing the complete plan:

```bash
terraform apply <plan-file>
```

Then confirm the cluster and node pools through the Azure portal or the customer's normal Azure and Kubernetes checks.

## Provider Cleanup

After the apply succeeds, remove provider configuration only when it is unused elsewhere:

```hcl
spotinst/spotinst
```

Also remove Ocean-only variables and outputs. Keep the Helm or Kubernetes providers if other resources still use them.

Run the final drift check:

```bash
terraform plan -detailed-exitcode
```

A successful rollback has restored Azure-managed node capacity, removed Ocean-managed resources, preserved the AKS cluster, and produced no unexpected Terraform changes.
