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

module "karpenter" {
  source = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 20.17.2"

  cluster_name = data.aws_eks_cluster.cluster.name
  create_node_iam_role = true
  node_iam_role_arn    = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/self-managed-node-group-complete-example"
  irsa_namespace_service_accounts = ["kube-system:karpenter"]
  irsa_oidc_provider_arn          = data.aws_iam_openid_connect_provider.oidc_provider.arn

  enable_irsa = true
  create_access_entry = true
  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    polic2                       =  aws_iam_policy.karpenter_additional.arn,
    policy3                      = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess",
    policy4                      = "arn:aws:iam::aws:policy/AmazonSQSFullAccess",
  }
}


resource "helm_release" "karpenter" {
  name       = "karpenter"
  repository = "oci://public.ecr.aws/karpenter/"
  chart      = "karpenter"
  version    = "1.0.6"
  namespace  = "kube-system"

  set {
    name  = "settings.clusterName"
    value = "k8s-sandbox-sandbox"
  }

  set {
    name  = "replicas"
    value = 1
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.karpenter.iam_role_arn
  }

  set {
    name  = "settings.aws.clusterEndpoint"
    value = data.aws_eks_cluster.cluster.endpoint
  }

  depends_on = [module.karpenter]
}

resource "aws_iam_policy" "karpenter_additional" {
  name        = "KarpenterAdditionalPermissions"
  description = "Additional permissions for Karpenter"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "ssm:GetParameter",
          "iam:PassRole",
          "iam:GetInstanceProfile",
          "iam:CreateInstanceProfile",
          "iam:TagInstanceProfile",
          "iam:AddRoleToInstanceProfile",
          "iam:DeleteInstanceProfile",
          "ec2:RunInstances",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeInstanceTypeOfferings",
          "ec2:DescribeAvailabilityZones",
          "ec2:DeleteLaunchTemplate",
          "ec2:CreateTags",
          "ec2:CreateLaunchTemplate",
          "ec2:CreateFleet",
          "ec2:DescribeSpotPriceHistory",
          "ec2:DescribeImages",
          "pricing:GetProducts",
          "sqs:DeleteMessage",
          "sqs:ReceiveMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
          "eks:DescribeCluster",
          "autoscaling:CompleteLifecycleAction",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeTags",
          "iam:RemoveRoleFromInstanceProfile",
          "ec2:TerminateInstances"
        ]
        Resource = [
          "*"
        ]
      }
    ]
  })
}

# # Attach the additional policy to the node IAM role
resource "aws_iam_role_policy_attachment" "karpenter_additional" {
  role       = module.karpenter.iam_role_name
  policy_arn = aws_iam_policy.karpenter_additional.arn
  depends_on = [ module.karpenter ]
}
