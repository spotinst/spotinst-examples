#!/usr/bin/env bash
set -euo pipefail

NAMESPACE_WORKLOADS="${NAMESPACE_WORKLOADS:-test-workloads}"
NAMESPACE_MONITORING="${NAMESPACE_MONITORING:-monitoring}"
NAMESPACE_SPOT="${NAMESPACE_SPOT:-spot-system}"
NAMESPACE_TRIDENT="${NAMESPACE_TRIDENT:-trident}"
TIMEOUT="${TIMEOUT:-180s}"
EXPECTED_CLUSTER_NAME="${EXPECTED_CLUSTER_NAME:-wes-test-aks-tf}"

failures=0
check() {
  local description="$1"
  shift
  printf 'CHECK %-52s' "$description"
  if "$@" >/tmp/aks-ocean-check.out 2>/tmp/aks-ocean-check.err; then
    printf 'PASS\n'
  else
    printf 'FAIL\n'
    cat /tmp/aks-ocean-check.err /tmp/aks-ocean-check.out
    failures=$((failures + 1))
  fi
}

require_kubectl_context() {
  local context
  context="$(kubectl config current-context)"
  case "$context" in
    *"$EXPECTED_CLUSTER_NAME"*) ;;
    *)
      printf 'kubectl context %s does not match expected AKS cluster %s\n' "$context" "$EXPECTED_CLUSTER_NAME" >&2
      return 1
      ;;
  esac
  kubectl cluster-info >/dev/null
}

if ! require_kubectl_context; then
  printf 'Validation aborted: select the AKS context for %s before running workload checks.\n' "$EXPECTED_CLUSTER_NAME" >&2
  exit 2
fi

printf 'kubectl context validated for %s\n' "$EXPECTED_CLUSTER_NAME"
check "AKS nodes ready" kubectl wait --for=condition=Ready node --all --timeout="$TIMEOUT"
check "Trident namespace" kubectl get namespace "$NAMESPACE_TRIDENT"
check "Spot namespace" kubectl get namespace "$NAMESPACE_SPOT"
check "Trident pods ready" kubectl wait --for=condition=Ready pod --all -n "$NAMESPACE_TRIDENT" --timeout="$TIMEOUT"
check "Spot pods ready" kubectl wait --for=condition=Ready pod --all -n "$NAMESPACE_SPOT" --timeout="$TIMEOUT"
check "Monitoring pods ready" kubectl wait --for=condition=Ready pod --all -n "$NAMESPACE_MONITORING" --timeout="$TIMEOUT"
check "Web deployment ready" kubectl rollout status deployment/project-web -n "$NAMESPACE_WORKLOADS" --timeout="$TIMEOUT"
check "ANF Ultra StorageClass" kubectl get storageclass anf-ultra
check "Web logs PVC bound" kubectl wait --for=jsonpath='{.status.phase}'=Bound pvc/web-logs -n "$NAMESPACE_WORKLOADS" --timeout="$TIMEOUT"
check "Web service exists" kubectl get service project-web -n "$NAMESPACE_WORKLOADS"

printf '\nResource summary\n'
kubectl get pods -A -o wide
kubectl get storageclass,pvc -A
kubectl get svc -n "$NAMESPACE_WORKLOADS"

printf '\nHTTP and timestamped log checks\n'
service_ip="$(kubectl get service project-web -n "$NAMESPACE_WORKLOADS" -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)"
service_hostname="$(kubectl get service project-web -n "$NAMESPACE_WORKLOADS" -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)"
if [[ -n "$service_ip" || -n "$service_hostname" ]]; then
  service_address="${service_ip:-$service_hostname}"
  check "Project page HTTP response" curl --fail --silent --show-error --max-time 15 "http://${service_address}/"
  check "Project page describes AKS Ocean" sh -c "curl --fail --silent --show-error --max-time 15 'http://${service_address}/' | grep -F 'AKS Ocean test project'"
else
  printf 'SKIP Project page HTTP response: LoadBalancer address is not assigned yet\n'
  failures=$((failures + 1))
fi

web_pod="$(kubectl get pods -n "$NAMESPACE_WORKLOADS" -l app=project-web -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)"
if [[ -n "$web_pod" ]]; then
  check "Timestamped retrieved log exists" kubectl exec -n "$NAMESPACE_WORKLOADS" "$web_pod" -c log-retriever -- test -s /var/log/web/retrieved/web.log
  check "Retrieved log has UTC timestamp" kubectl exec -n "$NAMESPACE_WORKLOADS" "$web_pod" -c log-retriever -- sh -c "grep -Eq '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z ' /var/log/web/retrieved/web.log"
else
  printf 'SKIP Timestamped log checks: no project-web pod exists\n'
  failures=$((failures + 1))
fi

printf '\n'
if [[ "$failures" -gt 0 ]]; then
  printf 'Validation completed with %s failure(s).\n' "$failures"
  exit 1
fi
printf 'All AKS Ocean workload checks passed.\n'
