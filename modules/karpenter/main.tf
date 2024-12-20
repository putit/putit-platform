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

data "kubernetes_service" "karpenter" {
  metadata {
    name      = "karpenter"
    namespace = "kube-system"
  }
}


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

provider "time" {}

resource "time_sleep" "wait_for_karpenter" {
  depends_on = [helm_release.karpenter]
  create_duration = "45s"
}

resource "kubectl_manifest" "karpenter_nodepool" {
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1beta1
    kind: NodePool
    metadata:
      name: ${helm_release.karpenter.name}
    spec:
      template:
        metadata:
          labels:
            type: karpenter
        spec:
          requirements:
            - key: karpenter.sh/capacity-type
              operator: In
              values: ["on-demand"]
            - key: "node.kubernetes.io/instance-type"
              operator: In
              values: ["t3.large","t3.xlarge"]
          nodeClassRef:
            name: ${helm_release.karpenter.name}
      limits:
        cpu: "120"
        memory: 120Gi
      disruption:
        consolidationPolicy: WhenUnderutilized
        expireAfter: 720h # 30 * 24h = 720h
  YAML

  depends_on = [
    time_sleep.wait_for_karpenter   # This will wait for the specified time before applying the manifest
  ]
}

resource "kubectl_manifest" "karpenter_ec2nodeclass" {
  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1beta1
    kind: EC2NodeClass
    metadata:
      name: ${helm_release.karpenter.name}
    spec:
      amiFamily: AL2 # Amazon Linux 2
      role: self-managed-node-group-complete-example
      subnetSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${data.aws_eks_cluster.cluster.name}
      securityGroupSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${data.aws_eks_cluster.cluster.name}
  YAML

  depends_on = [
    time_sleep.wait_for_karpenter   # Delay manifest creation until Karpenter service is ready
  ]
}
