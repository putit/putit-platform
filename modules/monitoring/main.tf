data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = var.cluster_name
}

resource "helm_release" "kube_prometheus_stack" {
  name             = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = var.chart_version
  namespace        = var.namespace
  create_namespace = true

  values = [
    templatefile("${path.module}/values/monitoring.yaml.tpl", {
      environment            = var.environment
      grafana_admin_password = var.grafana_admin_password
      grafana_ingress_enabled = var.grafana_ingress_enabled
      grafana_host           = var.grafana_host
      storage_class          = var.storage_class
      prometheus_retention   = var.prometheus_retention
      prometheus_storage_size = var.prometheus_storage_size
      grafana_storage_size   = var.grafana_storage_size
      loki_url               = var.loki_url
    })
  ]
}
