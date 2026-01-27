locals {
  serviceAccountName = "aws-load-balancer-controller"
}

data aws_eks_cluster cluster {
  name  = var.cluster_name
}

data aws_eks_cluster_auth cluster {
  name  = var.cluster_name
}

resource "aws_iam_policy" "aws_loadbalancer_controller" {
  name        = "aws-loadbalancer-controller-${var.cluster_name}"
  description = "AWS LoadBalancer Controller policy for version ${var.app_version}"
  policy =  file("${path.module}/policies/${var.app_version}/iam_policy.json")
}

module "irsa_role_alb_controller" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "v5.39.1"

  role_name              = "aws-load-balancer-controller-${var.cluster_name}"
  allow_self_assume_role = true

  oidc_providers = {
    one = {
      provider_arn               = var.cluster_oidc_provider_arn
      namespace_service_accounts = ["${var.namespace}:${local.serviceAccountName}"]
    }
  }

  role_policy_arns = {
    policy_1           = aws_iam_policy.aws_loadbalancer_controller.arn
  }
}

resource "helm_release" "aws_lb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = var.chart_version
  namespace  = var.namespace
  create_namespace = true

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  wait = true
}
