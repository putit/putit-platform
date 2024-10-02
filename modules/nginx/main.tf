locals {
  tenant_root_domain = "${var.tenant}.${var.root_domain}"
  int_alb_name = "traefik-int-${var.cluster_name}"

  // Using replace to dynamically remove the '-${environment}' part from cluster_name.
  cluster_base_name = replace(var.cluster_name, "-${var.environment}", "")

  // Constructing int_ingress_hostname by appending environment and root domain to cluster_base_name.
  int_ingress_hostname = "traefik-int-${local.cluster_base_name}.${var.environment}.${local.tenant_root_domain}"
  # we would have to make a new cert to allow: <service>.<k8s-cluster>.<environment>.<tenant>.<root_domain>
  # current one is valid up to *.<environment>.<tenant>.<root_domain>
  web_domain = "nginx-${local.cluster_base_name}.${var.environment}.${local.tenant_root_domain}"

}

data "aws_eks_cluster" "cluster" {
  name  = var.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name  = var.cluster_name
}

resource "helm_release" "nginx-example" {
  count        = var.deploy ? 1 : 0
  name         = "nginx"
  repository = "https://charts.bitnami.com/bitnami"
  chart        = "${var.chart_directory}"
  namespace    = var.namespace
  version      = var.chart_version
  force_update = true


#  set {
#    name  = "nginx.ingress.annotations.external-dns\\.alpha\\.kubernetes\\.io/hostname"
#    value = local.web_domain
#  }
#
#  set {
#    name  = "nginx.ingress.annotations.external-dns\\.alpha\\.kubernetes\\.io/target"
#    value = local.int_ingress_hostname
#  }
#
#  set {
#    name  = "nginx.ingress.hostname"
#    value = local.web_domain
#  }

  values = [
    file("values/nginx-${var.environment}.yaml")
  ]

}
