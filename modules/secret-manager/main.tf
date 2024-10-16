data "aws_eks_cluster" "cluster" {
  name  = var.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name  = var.cluster_name
}

resource "helm_release" "ssm" {
  count      = var.deploy ? 1 : 0
  name       = "ssm"
  repository = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
  chart      = "secrets-store-csi-driver"
  version    = "1.4.3"
  namespace  = "kube-system"

  values = [
    file("values/ssm-sandbox.yaml")
  ]
}



#To enable Kubernetes to retrieve secrets from AWS Secrets Manager, you must deploy the Secrets Manager CSI provider for AWS.
resource "helm_release" "ssm_provider" {
  count      = var.deploy ? 1 : 0
  name       = "secrets-store-csi-driver-provider-aws"
  repository = "https://aws.github.io/secrets-store-csi-driver-provider-aws"
  chart      = "secrets-store-csi-driver-provider-aws"
  version    = "0.3.8"
  namespace  = "kube-system"
}

data "aws_iam_openid_connect_provider" "oidc_provider" {
  arn = var.cluster_oidc_provider_arn
}

resource "aws_iam_policy" "secrets_manager_access" {
  name        = "SecretsManagerAccessPolicy"
  description = "Policy for Secrets Manager access for Kubernetes Service Account"
  policy      = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        "Resource": ["arn:aws:secretsmanager:eu-west-1:xxxxxxxxxxxxxxx:secret:staging/admin-pn2rWs"]
      }
    ]
  })
}

module "irsa_role_secrets_manager" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "v5.34.0"

  role_name = "secrets-store-csi-driver-provider-aws"
  create_role = true
  
  force_detach_policies = false

  oidc_providers = {
    one = {
      provider_arn               = data.aws_iam_openid_connect_provider.oidc_provider.arn
      namespace_service_accounts = ["kube-system:secrets-store-csi-driver-provider-aws"]
    }
  }

  role_policy_arns = {
    secrets_manager_access = aws_iam_policy.secrets_manager_access.arn
  }
}