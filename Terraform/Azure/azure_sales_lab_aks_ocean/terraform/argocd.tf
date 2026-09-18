resource "helm_release" "argocd" {
  name             = "argocd"
  namespace        = var.argocd_namespace
  create_namespace = true
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.argocd_chart_version
  wait             = true
}

resource "kubernetes_secret_v1" "argocd_gitops_repository" {
  metadata {
    name      = "gitops-repository"
    namespace = var.argocd_namespace
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }

  type = "Opaque"

  data = {
    type     = "git"
    url      = github_repository.gitops.http_clone_url
    username = var.github_owner
    password = var.argocd_github_token
    project  = "default"
  }

  depends_on = [helm_release.argocd]
}

resource "kubernetes_manifest" "argocd_root_application" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "aks-ocean-platform"
      namespace = var.argocd_namespace
    }
    spec = {
      project = "default"
      source = {
        repoURL        = github_repository.gitops.http_clone_url
        targetRevision = "main"
        path           = "applications"
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = var.argocd_namespace
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
      }
    }
  }

  depends_on = [
    kubernetes_secret_v1.argocd_gitops_repository,
    github_repository_file.application_root,
    github_repository_file.trident_application,
    github_repository_file.monitoring_application,
    github_repository_file.spot_application,
    github_repository_file.storage,
    github_repository_file.workload,
  ]
}
