resource "github_repository" "gitops" {
  name        = var.gitops_repository_name
  description = var.gitops_repository_description
  visibility  = "private"
  auto_init   = true
}

resource "github_branch_default" "gitops" {
  repository = github_repository.gitops.name
  branch     = "main"
}

resource "github_repository_file" "application_root" {
  repository          = github_repository.gitops.name
  branch              = "main"
  file                = "applications/root-workloads.yaml"
  commit_message      = "Add AKS Ocean workload application"
  overwrite_on_create = true
  content             = <<-YAML
    apiVersion: argoproj.io/v1alpha1
    kind: Application
    metadata:
      name: aks-ocean-workloads
      namespace: ${var.argocd_namespace}
    spec:
      project: default
      source:
        repoURL: ${github_repository.gitops.http_clone_url}
        targetRevision: main
        path: manifests
      destination:
        server: https://kubernetes.default.svc
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
          - CreateNamespace=true
  YAML
}

resource "github_repository_file" "trident_application" {
  repository          = github_repository.gitops.name
  branch              = "main"
  file                = "applications/trident.yaml"
  commit_message      = "Install NetApp Trident with Argo CD"
  overwrite_on_create = true
  content             = <<-YAML
    apiVersion: argoproj.io/v1alpha1
    kind: Application
    metadata:
      name: trident
      namespace: ${var.argocd_namespace}
    spec:
      project: default
      source:
        repoURL: https://netapp.github.io/trident-helm-chart
        chart: trident-operator
        targetRevision: ${var.trident_chart_version}
        helm:
          values: |
            tridentCRDs: true
            namespace: ${var.trident_namespace}
      destination:
        server: https://kubernetes.default.svc
        namespace: ${var.trident_namespace}
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
          - CreateNamespace=true
  YAML

  depends_on = [github_repository_file.application_root]
}

resource "github_repository_file" "monitoring_application" {
  repository          = github_repository.gitops.name
  branch              = "main"
  file                = "applications/monitoring.yaml"
  commit_message      = "Install Prometheus and Grafana through Argo CD"
  overwrite_on_create = true
  content             = <<-YAML
    apiVersion: argoproj.io/v1alpha1
    kind: Application
    metadata:
      name: monitoring
      namespace: ${var.argocd_namespace}
    spec:
      project: default
      source:
        repoURL: https://prometheus-community.github.io/helm-charts
        chart: kube-prometheus-stack
        targetRevision: ${var.monitoring_chart_version}
        helm:
          values: |
            prometheus:
              prometheusSpec:
                storageSpec:
                  volumeClaimTemplate:
                    spec:
                      storageClassName: anf-ultra
                      accessModes: [ReadWriteMany]
                      resources:
                        requests:
                          storage: 100Gi
            grafana:
              useStatefulSet: true
              persistence:
                enabled: true
                type: pvc
                storageClassName: anf-ultra
                accessModes: [ReadWriteMany]
                size: 20Gi
      destination:
        server: https://kubernetes.default.svc
        namespace: monitoring
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
          - CreateNamespace=true
  YAML
  depends_on          = [github_repository_file.trident_application]
}

resource "github_repository_file" "spot_application" {
  repository          = github_repository.gitops.name
  branch              = "main"
  file                = "applications/spot-ocean.yaml"
  commit_message      = "Install Spot Ocean admission and metrics charts"
  overwrite_on_create = true
  content             = <<-YAML
    apiVersion: argoproj.io/v1alpha1
    kind: Application
    metadata:
      name: spot-ocean
      namespace: ${var.argocd_namespace}
    spec:
      project: default
      sources:
        - repoURL: https://charts.spot.io
          chart: ocean-kubernetes-controller
          targetRevision: ${var.ocean_controller_chart_version}
          helm:
            values: |
              spotinst:
                clusterIdentifier: ${var.cluster_name}
              secret:
                create: false
                name: spotinst-credentials
        - repoURL: https://charts.spot.io
          chart: ocean-admission-controller
          targetRevision: ${var.ocean_admission_controller_chart_version}
        - repoURL: https://charts.spot.io
          chart: ocean-metric-exporter
          targetRevision: ${var.ocean_metrics_exporter_chart_version}
          helm:
            values: |
              spotinst:
                clusterIdentifier: ${var.cluster_name}
              secretName: spotinst-credentials
      destination:
        server: https://kubernetes.default.svc
        namespace: spot-system
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
          - CreateNamespace=true
  YAML

  depends_on = [github_repository_file.monitoring_application]
}

resource "github_repository_file" "storage" {
  repository          = github_repository.gitops.name
  branch              = "main"
  file                = "manifests/storage.yaml"
  commit_message      = "Add Trident Azure NetApp Files Ultra storage"
  overwrite_on_create = true
  content             = <<-YAML
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
      namespace: ${var.trident_namespace}
    spec:
      version: 1
      backendName: azure-netapp-files-ultra
      storageDriverName: azure-netapp-files
      credentials:
        name: trident-azure-credentials
      subscriptionID: ${var.subscription_id}
      tenantID: ${var.tenant_id}
      location: ${var.resource_group_location}
      serviceLevel: Ultra
      virtualNetwork: ${var.vnet_name}
      subnet: ${var.anf_subnet_name}
      nfsMountOptions: nfsvers=4.1
  YAML
  depends_on          = [github_repository_file.monitoring_application]
}

resource "github_repository_file" "workload" {
  repository          = github_repository.gitops.name
  branch              = "main"
  file                = "manifests/web-workload.yaml"
  commit_message      = "Add timestamped web log test workload"
  overwrite_on_create = true
  content             = <<-YAML
    apiVersion: v1
    kind: Namespace
    metadata:
      name: test-workloads
    ---
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: project-page
      namespace: test-workloads
    data:
      index.html: |
        <!doctype html>
        <html lang="en">
        <head><meta charset="utf-8"><title>AKS Ocean test project</title></head>
        <body><h1>AKS Ocean test project</h1><p>This page validates GitOps, Azure NetApp Files Ultra, Trident CSI, Prometheus, Grafana, and Spot Ocean on AKS.</p></body>
        </html>
    ---
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: web-logs
      namespace: test-workloads
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
      namespace: test-workloads
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
              args:
                - |
                  touch /var/log/web/access.log /var/log/web/error.log
                  tail -F /var/log/web/access.log /var/log/web/error.log | while read line; do printf '%s %s\\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$line" >> /var/log/web/retrieved/web.log; done
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
      namespace: test-workloads
    spec:
      selector:
        app: project-web
      ports:
        - name: http
          port: 80
          targetPort: http
      type: ${var.web_service_type}
  YAML
  depends_on          = [github_repository_file.storage]
}
