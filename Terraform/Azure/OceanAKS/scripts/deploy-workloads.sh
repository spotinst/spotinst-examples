#!/usr/bin/env bash
set -euo pipefail

INTERACTIVE="${INTERACTIVE:-true}"
CONFIRM_INPUTS="${CONFIRM_INPUTS:-false}"

command -v az >/dev/null || { printf 'Azure CLI is required\n' >&2; exit 1; }

if [[ -z "${SUBSCRIPTION_ID:-}" ]]; then
  SUBSCRIPTION_ID="$(az account show --query id -o tsv 2>/dev/null || true)"
fi

read_input() {
  local variable_name="$1"
  local prompt_text="$2"
  local secret_input="${3:-false}"
  local current_value="${!variable_name:-}"
  local answer

  while true; do
    if [[ -n "$current_value" ]]; then
      if [[ "$CONFIRM_INPUTS" != "true" || "$INTERACTIVE" != "true" ]]; then
        return
      fi

      if [[ "$secret_input" == "true" ]]; then
        read -r -p "$prompt_text is set. Use it? [Y/n] " answer
      else
        read -r -p "$prompt_text [$current_value]. Use it? [Y/n] " answer
      fi
      case "$answer" in
        [nN]*) current_value=""; printf -v "$variable_name" '%s' ""; continue ;;
        *) return ;;
      esac
    fi

    if [[ "$INTERACTIVE" != "true" ]]; then
      printf '%s must be set when INTERACTIVE=false\n' "$variable_name" >&2
      exit 1
    fi

    if [[ "$secret_input" == "true" ]]; then
      read -r -s -p "$prompt_text: " current_value
      printf '\n'
    else
      read -r -p "$prompt_text: " current_value
    fi
    if [[ -z "$current_value" ]]; then
      printf '%s cannot be empty\n' "$variable_name" >&2
      continue
    fi
    printf -v "$variable_name" '%s' "$current_value"
    return
  done
}

read_input SUBSCRIPTION_ID "Azure subscription ID"
az account set --subscription "$SUBSCRIPTION_ID"
if [[ -z "${TENANT_ID:-}" ]]; then
  TENANT_ID="$(az account show --query tenantId -o tsv 2>/dev/null || true)"
fi
read_input TENANT_ID "Microsoft Entra tenant ID"
read_input CLUSTER_NAME "AKS cluster name"
if [[ -z "${RESOURCE_GROUP_NAME:-}" && -n "${CLUSTER_NAME:-}" ]]; then
  RESOURCE_GROUP_NAME="$(az aks show --name "$CLUSTER_NAME" --query resourceGroup -o tsv 2>/dev/null || true)"
fi
read_input RESOURCE_GROUP_NAME "Azure resource group name"
read_input TRIDENT_CLIENT_ID "Trident client ID"
read_input TRIDENT_CLIENT_SECRET "Trident client secret" true
read_input SPOTINST_ACCOUNT "Spot account ID"
read_input SPOTINST_TOKEN "Spot token" true
if [[ -n "${RESOURCE_GROUP_NAME:-}" && -n "${CLUSTER_NAME:-}" ]]; then
  if [[ -z "${RESOURCE_GROUP_LOCATION:-}" ]]; then
    RESOURCE_GROUP_LOCATION="$(az aks show --resource-group "$RESOURCE_GROUP_NAME" --name "$CLUSTER_NAME" --query location -o tsv 2>/dev/null || true)"
  fi
  if [[ -z "${VNET_NAME:-}" ]]; then
    aks_subnet_id="$(az aks show --resource-group "$RESOURCE_GROUP_NAME" --name "$CLUSTER_NAME" --query 'agentPoolProfiles[0].vnetSubnetId' -o tsv 2>/dev/null || true)"
    if [[ -n "$aks_subnet_id" ]]; then
      VNET_NAME="$(awk -F/ '{print $(NF-2)}' <<<"$aks_subnet_id")"
    fi
  fi
  if [[ -z "${ANF_SUBNET_NAME:-}" && -n "${VNET_NAME:-}" ]]; then
    ANF_SUBNET_NAME="$(az network vnet subnet list --resource-group "$RESOURCE_GROUP_NAME" --vnet-name "$VNET_NAME" --query "[?delegations[?serviceName=='Microsoft.Netapp/volumes']].name | [0]" -o tsv 2>/dev/null || true)"
  fi
fi
read_input VNET_NAME "AKS VNet name"
read_input ANF_SUBNET_NAME "ANF subnet name"
read_input RESOURCE_GROUP_LOCATION "Azure resource group location"

TRIDENT_NAMESPACE="${TRIDENT_NAMESPACE:-trident}"
SPOT_NAMESPACE="${SPOT_NAMESPACE:-spot-system}"
MONITORING_NAMESPACE="${MONITORING_NAMESPACE:-monitoring}"
WORKLOAD_NAMESPACE="${WORKLOAD_NAMESPACE:-test-workloads}"
TRIDENT_CHART_VERSION="${TRIDENT_CHART_VERSION:-100.6.0}"
MONITORING_CHART_VERSION="${MONITORING_CHART_VERSION:-65.8.1}"
OCEAN_CONTROLLER_CHART_VERSION="${OCEAN_CONTROLLER_CHART_VERSION:-0.1.75}"
OCEAN_ADMISSION_CHART_VERSION="${OCEAN_ADMISSION_CHART_VERSION:-1.0.3}"
OCEAN_METRICS_CHART_VERSION="${OCEAN_METRICS_CHART_VERSION:-1.1.1}"
WEB_SERVICE_TYPE="${WEB_SERVICE_TYPE:-LoadBalancer}"

command -v kubectl >/dev/null || { printf 'kubectl is required\n' >&2; exit 1; }
command -v helm >/dev/null || { printf 'Helm is required\n' >&2; exit 1; }

az aks get-credentials --resource-group "$RESOURCE_GROUP_NAME" --name "$CLUSTER_NAME" --overwrite-existing

for namespace in "$TRIDENT_NAMESPACE" "$SPOT_NAMESPACE" "$MONITORING_NAMESPACE"; do
  kubectl create namespace "$namespace" --dry-run=client -o yaml | kubectl apply -f -
done

kubectl -n "$TRIDENT_NAMESPACE" create secret generic trident-azure-credentials \
  --from-literal=subscriptionID="$SUBSCRIPTION_ID" --from-literal=tenantID="$TENANT_ID" \
  --from-literal=clientID="$TRIDENT_CLIENT_ID" --from-literal=clientSecret="$TRIDENT_CLIENT_SECRET" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl -n "$SPOT_NAMESPACE" create secret generic spotinst-credentials \
  --from-literal=account="$SPOTINST_ACCOUNT" --from-literal=token="$SPOTINST_TOKEN" \
  --dry-run=client -o yaml | kubectl apply -f -

helm repo add trident https://netapp.github.io/trident-helm-chart
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add spot https://charts.spot.io
helm repo update

helm upgrade --install trident trident/trident-operator --namespace "$TRIDENT_NAMESPACE" \
  --version "$TRIDENT_CHART_VERSION" --set tridentCRDs=true --set namespace="$TRIDENT_NAMESPACE" --wait
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack --namespace "$MONITORING_NAMESPACE" \
  --version "$MONITORING_CHART_VERSION" --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.storageClassName=anf-ultra \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.accessModes[0]=ReadWriteMany \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=100Gi \
  --set grafana.useStatefulSet=true --set grafana.persistence.enabled=true --set grafana.persistence.type=pvc \
  --set grafana.persistence.storageClassName=anf-ultra --set grafana.persistence.accessModes[0]=ReadWriteMany \
  --set grafana.persistence.size=20Gi --wait
helm upgrade --install ocean-controller spot/ocean-kubernetes-controller --namespace "$SPOT_NAMESPACE" \
  --version "$OCEAN_CONTROLLER_CHART_VERSION" --set spotinst.clusterIdentifier="$CLUSTER_NAME" \
  --set secret.create=false --set secret.name=spotinst-credentials --wait
helm upgrade --install ocean-admission spot/ocean-admission-controller --namespace "$SPOT_NAMESPACE" \
  --version "$OCEAN_ADMISSION_CHART_VERSION" --wait
helm upgrade --install ocean-metric-exporter spot/ocean-metric-exporter --namespace "$SPOT_NAMESPACE" \
  --version "$OCEAN_METRICS_CHART_VERSION" --set spotinst.clusterIdentifier="$CLUSTER_NAME" \
  --set secretName=spotinst-credentials --wait

kubectl apply -f - <<YAML
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: anf-ultra
provisioner: csi.trident.netapp.io
reclaimPolicy: Delete
allowVolumeExpansion: true
volumeBindingMode: Immediate
parameters:
  backendType: azure-netapp-files
  serviceLevel: Ultra
  fsType: nfs
---
apiVersion: trident.netapp.io/v1
kind: TridentBackendConfig
metadata:
  name: azure-netapp-files-ultra
  namespace: ${TRIDENT_NAMESPACE}
spec:
  version: 1
  backendName: azure-netapp-files-ultra
  storageDriverName: azure-netapp-files
  credentials:
    name: trident-azure-credentials
  subscriptionID: ${SUBSCRIPTION_ID}
  tenantID: ${TENANT_ID}
  location: ${RESOURCE_GROUP_LOCATION}
  serviceLevel: Ultra
  virtualNetwork: ${VNET_NAME}
  subnet: ${ANF_SUBNET_NAME}
  nfsMountOptions: nfsvers=4.1
YAML

kubectl apply -f - <<YAML
apiVersion: v1
kind: Namespace
metadata:
  name: ${WORKLOAD_NAMESPACE}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: project-page
  namespace: ${WORKLOAD_NAMESPACE}
data:
  index.html: |
    <!doctype html><html lang="en"><head><meta charset="utf-8"><title>AKS Ocean test project</title></head><body><h1>AKS Ocean test project</h1><p>This page validates Azure NetApp Files Ultra, Trident CSI, Prometheus, Grafana, and Spot Ocean on AKS.</p></body></html>
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: web-logs
  namespace: ${WORKLOAD_NAMESPACE}
spec:
  accessModes: [ReadWriteMany]
  storageClassName: anf-ultra
  resources:
    requests:
      storage: 20Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: project-web
  namespace: ${WORKLOAD_NAMESPACE}
spec:
  replicas: 2
  selector:
    matchLabels:
      app: project-web
  template:
    metadata:
      labels:
        app: project-web
    spec:
      initContainers:
      - name: prepare-log-folders
        image: busybox:1.36
        command: [sh, -c, "mkdir -p /var/log/web/retrieved && chmod 0777 /var/log/web /var/log/web/retrieved"]
        volumeMounts:
        - name: web-logs
          mountPath: /var/log/web
      containers:
      - name: web
        image: nginx:1.27-alpine
        ports:
        - name: http
          containerPort: 80
        volumeMounts:
        - name: page
          mountPath: /usr/share/nginx/html/index.html
          subPath: index.html
        - name: web-logs
          mountPath: /var/log/nginx
      - name: log-retriever
        image: busybox:1.36
        command: [sh, -c]
        args: ["touch /var/log/web/access.log /var/log/web/error.log; tail -F /var/log/web/access.log /var/log/web/error.log | while read line; do printf '%s %s\\n' \"\$(date -u +%Y-%m-%dT%H:%M:%SZ)\" \"\$line\" >> /var/log/web/retrieved/web.log; done"]
        volumeMounts:
        - name: web-logs
          mountPath: /var/log/web
      volumes:
      - name: page
        configMap:
          name: project-page
      - name: web-logs
        persistentVolumeClaim:
          claimName: web-logs
---
apiVersion: v1
kind: Service
metadata:
  name: project-web
  namespace: ${WORKLOAD_NAMESPACE}
spec:
  selector:
    app: project-web
  ports:
  - name: http
    port: 80
    targetPort: http
  type: ${WEB_SERVICE_TYPE}
YAML

printf 'Workloads deployed to AKS cluster %s.\n' "$CLUSTER_NAME"