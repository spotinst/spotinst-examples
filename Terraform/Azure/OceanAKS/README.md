# Azure AKS Spot Ocean test project

This project provisions an AKS cluster, Spot Ocean capacity, automatic Ocean rightsizing, Azure NetApp Files Ultra capacity, and an Argo CD GitOps bootstrap. Terraform creates the private GitHub repository and commits the Kubernetes configuration into it. Argo CD then reconciles the workload and chart applications from that repository.

## Prerequisites

- Azure subscription permissions for AKS, networking, Azure NetApp Files, and `NetApp Contributor` role assignments.
- Terraform 1.x, Azure CLI authentication, and GitHub CLI authentication.
- `GITHUB_TOKEN` or the GitHub provider's supported authentication environment, plus `TF_VAR_argocd_github_token` for Argo CD to read the private repository.
- `TF_VAR_spotinst_token`, `TF_VAR_spotinst_account`, and `TF_VAR_trident_client_secret` supplied outside tracked files.

## Important migration note

The original cluster used managed `kubenet` networking without a customer VNet. This configuration moves AKS to a dedicated VNet/subnet so the delegated Azure NetApp Files subnet is reachable. Review `terraform plan` carefully because Azure may replace the existing AKS cluster during this network change.

## Apply order

Run Terraform from the `terraform/` directory. Copy `terraform.tfvars.example` to the ignored `terraform.tfvars` file and set customer-specific values. Review [`docs/DEPLOYMENT_STAGES.md`](docs/DEPLOYMENT_STAGES.md) before applying the AKS networking migration.

After deployment, refresh kubeconfig and run the validation script:

```sh
cd terraform
az aks get-credentials --resource-group <resource-group-name> \
	--name <aks-cluster-name> --overwrite-existing
cd ..
./scripts/validate-workloads.sh
```

The script verifies AKS nodes, Trident, Spot Ocean, monitoring, ANF storage, PVC binding, the web page, and timestamped logs.

The `trident-azure-credentials` and `gitops-repository` Kubernetes secrets are intentionally Terraform-managed because their values must not be committed to GitHub. All non-secret Kubernetes configuration and Helm application definitions live in the provisioned GitHub repository.

## Project layout

- `terraform/`: Terraform providers, infrastructure, AKS, ANF, Ocean, GitOps bootstrap, and configuration examples.
- `terraform/terraform.tfvars.example`: tracked customer configuration template.
- `terraform/terraform.tfvars`: ignored local configuration and secret placeholders.
- `scripts/`: executable operational validation scripts.
- `docs/`: migration, rollback, and policy documentation.
- `.terraform/`, state files, and plan files: local Terraform runtime artifacts; do not commit them.
