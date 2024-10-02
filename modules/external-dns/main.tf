locals {
  tags = {
    Terraform    = true
    Environment = var.environment
  }
  serviceAccountName = "external-dns"
  tenant_root_domain = "${var.tenant}.${var.root_domain}"
}

data aws_eks_cluster cluster {
  name  = var.cluster_name
}

data aws_eks_cluster_auth cluster {
  name  = var.cluster_name
}

################################################################################
# IRSA Roles
################################################################################
resource "aws_iam_policy" "external_dns_policy" {
  name        = "external-dns-${var.cluster_name}"
  description = "Policy for external-dns"
  policy =  file("${path.module}/policies/iam_policy_external_dns.json")
}

module "irsa_role_external_dns" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "v5.37.1"

  role_name              = "external-dns-${var.cluster_name}"
  allow_self_assume_role = true

  oidc_providers = {
    one = {
      provider_arn               = var.cluster_oidc_provider_arn
      namespace_service_accounts = ["${var.namespace}:${local.serviceAccountName}"]
    }
  }

  role_policy_arns = {
    policy_1           = aws_iam_policy.external_dns_policy.arn
  }

  tags = local.tags
}

resource "helm_release" "external_dns" {
  count        = var.deploy ? 1 : 0
  name         = "external-dns"
  chart        = "external-dns"
  repository   = "https://charts.bitnami.com/bitnami"
  namespace    = var.namespace
  version      = var.chart_version
  force_update = false

  set {
    name = "aws.region"
    value = var.region
  }

  set {
    name = "domainFilters[0]"
    value = local.tenant_root_domain
  }

  set {
    name = "zoneIdFilters[0]"
    value = var.hosted_zone_id
  }

  # has to match 
  set {
    name  = "serviceAccount.name"
    value = local.serviceAccountName
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.irsa_role_external_dns.iam_role_arn
  }

  set {
    name = "txtPrefix"
    value = var.cluster_name
  }

  depends_on = [ module.irsa_role_external_dns ]
}
