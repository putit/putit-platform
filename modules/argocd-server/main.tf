locals {
  tenant_root_domain = "${var.tenant}.${var.root_domain}"
  int_alb_name = "traefik-${var.cluster_name}"
  argocd_grpc_domain = "argocd-grpc.${var.environment}.${local.tenant_root_domain}"

  # it's going to be exposed on public ALB
  web_domain = "argocd.${var.environment}.${local.tenant_root_domain}"
}

data "aws_eks_cluster" "cluster" {
  name  = var.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name  = var.cluster_name
}

resource "kubernetes_namespace" "argocd" {
  count    = var.deploy ? 1 : 0
  metadata {
    name = var.namespace
  }
}

resource "helm_release" "argocd" {
  count        = var.deploy ? 1 : 0
  name         = "argo-cd"
  chart        = "argo-cd"
  repository   = "https://argoproj.github.io/argo-helm"
  namespace    = var.namespace
  version      = var.chart_version
  force_update = false

  values = [
    file("values/argocd-${var.environment}.yaml")
  ]

  # disable creating secret - we mange it to not lose tokens during upgrade etc
  # disable it after first run
  set {
    name  = "configs.secret.createSecret"
    value = true
  }

  set {
    name  = "server.ingress.annotations.external-dns\\.alpha\\.kubernetes\\.io/hostname"
    value = local.web_domain
  }

  set {
    name  = "server.ingress.annotations.external-dns\\.alpha\\.kubernetes\\.io/target"
    value = var.pub_ingress_hostname
  }

  set {
    name  = "server.ingress.hostname"
    value = local.web_domain
  }

  set {
    name  = "server.ingressGrpc.annotations.external-dns\\.alpha\\.kubernetes\\.io/hostname"
    value = local.argocd_grpc_domain
  }

  set {
    name  = "server.ingressGrpc.annotations.external-dns\\.alpha\\.kubernetes\\.io/target"
    value = var.pub_ingress_hostname
  }

  set {
    name  = "server.ingressGrpc.hostname"
    value = local.argocd_grpc_domain
  }

  # set create-only policy for entire ApplicationSet Controller. 
  # based on: https://github.com/argoproj/argo-cd/issues/9101
  # later when tf provider will support, we can switch to per ApplicationSet policy
  # https://github.com/oboukili/terraform-provider-argocd/issues/333
  # it's needed to allow argocd set override application paramas like image.version
  # 
  set {
    name  = "configs.params.applicationsetcontroller\\.policy"
    value = "create-only"
  }

  depends_on = [kubernetes_namespace.argocd]
}

# GitHub App credentials for ArgoCD repo access
data "aws_secretsmanager_secret_version" "github_app_key" {
  count     = var.deploy && var.github_app_private_key_secret_name != "" ? 1 : 0
  secret_id = var.github_app_private_key_secret_name
}

resource "kubernetes_secret" "argocd_github_app_creds" {
  count = var.deploy && var.github_app_private_key_secret_name != "" ? 1 : 0

  metadata {
    name      = "argocd-github-app-creds"
    namespace = var.namespace
    labels = {
      "argocd.argoproj.io/secret-type" = "repo-creds"
    }
  }

  data = {
    type                    = "git"
    url                     = "https://github.com/${var.github_org}"
    githubAppID             = var.github_app_id
    githubAppInstallationID = var.github_app_installation_id
    githubAppPrivateKey     = data.aws_secretsmanager_secret_version.github_app_key[0].secret_string
  }

  depends_on = [kubernetes_namespace.argocd]
}

# Store ArgoCD admin password in AWS Secrets Manager for retrieval without kubectl
data "kubernetes_secret" "argocd_admin" {
  count = var.deploy ? 1 : 0
  metadata {
    name      = "argocd-initial-admin-secret"
    namespace = var.namespace
  }
  depends_on = [helm_release.argocd]
}

resource "aws_secretsmanager_secret" "argocd_admin" {
  count = var.deploy ? 1 : 0
  name  = "${var.environment}/argocd-admin-password"
}

resource "aws_secretsmanager_secret_version" "argocd_admin" {
  count         = var.deploy ? 1 : 0
  secret_id     = aws_secretsmanager_secret.argocd_admin[0].id
  secret_string = data.kubernetes_secret.argocd_admin[0].data["password"]
}
