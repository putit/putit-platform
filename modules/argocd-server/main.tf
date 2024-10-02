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
    name  = "server.ingress.annotations.hosts[0]"
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
    name  = "server.ingressGrpc.annotations.hosts[0]"
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

# please then register the cluster. 
# ArgoCD creats SA, token and role for its self
#  argocd cluster add --yes <CLUSTER_NAME>
