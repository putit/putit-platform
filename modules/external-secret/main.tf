data "aws_eks_cluster" "cluster" {
  name  = var.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name  = var.cluster_name
}

data "aws_iam_openid_connect_provider" "oidc_provider" {
  arn = var.cluster_oidc_provider_arn
}

data "aws_caller_identity" "current" {}

resource "helm_release" "external_secret" {
  count      = var.deploy ? 1 : 0
  name       = "external-secret"
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  version    = "0.10.3"
  namespace  = "default"

  set {
      name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = aws_iam_role.external_secret.arn
  }

  set {
      name  = "serviceAccount.name"
      value = "external-secret"
  }
}


resource "aws_iam_policy" "secrets_manager_access" {
  name        = "SecretsManagerAccessPolicyExternalSecret"
  description = "Policy for Secrets Manager access for Kubernetes Service Account"
  policy      = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:GetResourcePolicy",
          "secretsmanager:ListSecretVersionIds"
        ],
        "Resource": ["arn:aws:secretsmanager:eu-west-1:${data.aws_caller_identity.current.account_id}:secret:*"]
      }
    ]
  })
}

resource "aws_iam_role" "external_secret" {
  name = "external-secret"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Federated": data.aws_iam_openid_connect_provider.oidc_provider.arn
        },
        "Action": "sts:AssumeRoleWithWebIdentity",
        "Condition": {
          "StringEquals": {
            "${data.aws_iam_openid_connect_provider.oidc_provider.url}:sub": "system:serviceaccount:default:external-secret"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "external_secret_policy_attachment" {
  name       = "external-secret-policy-attachment"
  roles      = [aws_iam_role.external_secret.name]
  policy_arn  = aws_iam_policy.secrets_manager_access.arn
}

module "irsa_role_secrets_manager" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "v5.34.0"

  role_name = "external-secret"
  create_role = false

  oidc_providers = {
    one = {
      provider_arn               = data.aws_iam_openid_connect_provider.oidc_provider.arn
      namespace_service_accounts = ["default:external-secret"]
    }
  }

  role_policy_arns = {
    secrets_manager_access = aws_iam_policy.secrets_manager_access.arn
  }
}