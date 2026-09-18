# Deployment stages

Run Terraform commands from the `azure_sales_lab_aks_ocean/terraform` directory.

The existing AKS cluster was created with managed `kubenet` networking and no customer VNet. Azure NetApp Files requires a reachable delegated subnet, so the first apply can replace the cluster and its node pools. Kubernetes and Helm providers cannot initialize while that replacement endpoint is unknown.

Use two applies for this migration:

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
terraform plan
terraform apply
```

Review the first plan for the AKS replacement before approving it. The second plan installs Argo CD, creates the GitHub repository and its configuration, creates the sensitive Trident/Argo secrets, and applies the Spot, monitoring, storage, and web workload resources.

Do not commit `terraform.tfstate`, `terraform.tfstate.backup`, generated plans, or secret-bearing tfvars files. Rotate any Spot token that was previously stored in a tracked or shared tfvars file.