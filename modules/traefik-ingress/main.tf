locals {
  # int will be prefixed by AWS with internal-
  int_alb_name = "traefik-${var.cluster_name}"
  pub_alb_name = "pub-traefik-${var.cluster_name}"
  tenant_root_domain = "${var.tenant}.${var.root_domain}"

  // Using replace to dynamically remove the '-${environment}' part from cluster_name.
  cluster_base_name = replace(var.cluster_name, "-${var.environment}", "")

  // Constructing int_ingress_hostname by appending environment and root domain to cluster_base_name.
  int_ingress_hostname = "traefik-int-${local.cluster_base_name}.${var.environment}.${local.tenant_root_domain}"
  pub_ingress_hostname = "traefik-pub-${local.cluster_base_name}.${var.environment}.${local.tenant_root_domain}"

  # due to the bug https://github.com/hashicorp/terraform-provider-helm/issues/821
  templates_directory = "${var.chart_directory}/templates"
  template_hashes = {
    for path in sort(fileset(local.templates_directory, "**")) :
    path => filebase64sha512("${local.templates_directory}/${path}")
  }
  hash = base64sha512(jsonencode(local.template_hashes))
}

data aws_eks_cluster cluster {
  name  = var.cluster_name
}

data aws_eks_cluster_auth cluster {
  name  = var.cluster_name
}

# iam account which allows to discover targets from ECS clusters.
# https://doc.traefik.io/traefik/providers/ecs/
resource "aws_iam_policy" "traefik_ecs" {
  name        = "traefik-ecs-policy-${var.cluster_name}"
  description = "Policy for traefik on ${var.cluster_name} to create services from ECS."
  policy = file("${path.module}/policies/ecs.json")
}

module "irsa_role_traefik_ecs" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "v5.37.1"
  role_name             = "traefik-ecs-${var.cluster_name}"
  role_policy_arns = {
    policy_1 = aws_iam_policy.traefik_ecs.arn
  }
  allow_self_assume_role = true
  oidc_providers = {
    one = {
      provider_arn               = var.cluster_oidc_provider_arn
      namespace_service_accounts = ["${var.traefik_namespace}:traefik"]
    }
  }
}

resource "helm_release" "traefik" {
  count            = var.deploy_traefik ? 1 : 0
  name             = "traefik"
  chart            = "${var.chart_directory}"
  dependency_update = true
  version          = var.traefik_chart_version
  namespace        = var.traefik_namespace
  create_namespace = true
  force_update      = true

  set {
    name = "traefik.ingress.certificate_arns"
    value = var.all_cert_arns_string
    type  = "string"
  }

  set {
    name = "traefik.ingress.pub_alb_name"
    value = local.pub_alb_name
  }

  set {
    name = "traefik.ingress.pub_hostname"
    value = local.pub_ingress_hostname
  }

  set {
    name = "traefik.ingress.int_alb_name"
    value = local.int_alb_name
  }

  set {
    name = "traefik.ingress.int_hostname"
    value = local.int_ingress_hostname
  }

  # due to the bug https://github.com/hashicorp/terraform-provider-helm/issues/821
  set {
    name = "templatesHash"
    value = local.hash
  }

  # assign ecs role to traefik sa
  set {
    name = "traefik.serviceAccountAnnotations.eks\\.amazonaws\\.com/role-arn"
    value = module.irsa_role_traefik_ecs.iam_role_arn
  }

  values = [
    file("values/traefik-${var.environment}.yaml")
  ]
}
