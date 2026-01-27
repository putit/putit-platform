data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = var.cluster_name
}

# --- Loki ---

resource "helm_release" "loki" {
  name             = "loki"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "loki"
  version          = var.loki_chart_version
  namespace        = var.namespace
  create_namespace = true

  values = [
    templatefile("${path.module}/values/loki.yaml.tpl", {
      storage_backend = var.loki_storage_backend
      s3_bucket       = var.loki_s3_bucket
      s3_region       = var.loki_s3_region
      retention       = var.loki_retention
      storage_size    = var.loki_storage_size
      storage_class   = var.storage_class
    })
  ]
}

# --- Grafana Alloy ---

resource "helm_release" "alloy" {
  name             = "alloy"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "alloy"
  version          = var.alloy_chart_version
  namespace        = var.namespace
  create_namespace = true

  values = [
    templatefile("${path.module}/values/alloy.yaml.tpl", {
      loki_endpoint = "http://loki.${var.namespace}.svc:3100/loki/api/v1/push"
      cluster_name  = var.cluster_name
    })
  ]

  depends_on = [helm_release.loki]
}

# --- IRSA for Loki S3 access (optional) ---

data "aws_iam_openid_connect_provider" "oidc_provider" {
  count = var.loki_storage_backend == "s3" && var.cluster_oidc_provider_arn != "" ? 1 : 0
  arn   = var.cluster_oidc_provider_arn
}

resource "aws_iam_policy" "loki_s3" {
  count       = var.loki_storage_backend == "s3" ? 1 : 0
  name        = "loki-s3-${var.cluster_name}"
  description = "Loki S3 storage access for ${var.cluster_name}"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.loki_s3_bucket}",
          "arn:aws:s3:::${var.loki_s3_bucket}/*"
        ]
      }
    ]
  })
}

module "irsa_role_loki" {
  count   = var.loki_storage_backend == "s3" && var.cluster_oidc_provider_arn != "" ? 1 : 0
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "v5.39.1"

  role_name = "loki-s3-${var.cluster_name}"
  role_policy_arns = {
    policy = aws_iam_policy.loki_s3[0].arn
  }
  oidc_providers = {
    one = {
      provider_arn               = data.aws_iam_openid_connect_provider.oidc_provider[0].arn
      namespace_service_accounts = ["${var.namespace}:loki"]
    }
  }
}
