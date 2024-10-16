module "karpenter" {
  source = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 20.17.2"

  cluster_name = data.aws_eks_cluster.cluster.name
  create_node_iam_role = false
  node_iam_role_arn    = "arn:aws:iam::336796197909:role/self-managed-node-group-complete-example"
  irsa_namespace_service_accounts = ["default:karpenter"]

  # Since the nodegroup role will already have an access entry
  create_access_entry = false
  # Attach additional IAM policies to the Karpenter node IAM role
  enable_pod_identity             = true
  create_pod_identity_association = true

  # Used to attach additional IAM policies to the Karpenter node IAM role
  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore             = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    KarpenterAdditionalPermissions = aws_iam_policy.karpenter_additional.arn
  }
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

# Attach the additional policy to the node IAM role
resource "aws_iam_role_policy_attachment" "karpenter_additional" {
  role       = "self-managed-node-group-complete-example"
  policy_arn = aws_iam_policy.karpenter_additional.arn
}