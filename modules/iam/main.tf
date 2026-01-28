locals {
  trusted_roles = concat(
    [
      "arn:aws:iam::${var.aws_account_id}:role/aws-reserved/sso.amazonaws.com/*/AWSReservedSSO_edap_platform_devs_*",
    ],
    var.aws_account_id == "975050217262" ? ["arn:aws:iam::${var.aws_account_id}:role/aws-reserved/sso.amazonaws.com/*/AWSReservedSSO_platform_devs_onboarding_*"] : [],
  )
}

################################################################################
# GitHub Actions OIDC Provider and Role
################################################################################

# GitHub OIDC provider - create if it doesn't exist
# If it already exists, import it: terraform import aws_iam_openid_connect_provider.github arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1", "1c58a3a8518e8759bf075b76b750d4f2df264fcd"]

  lifecycle {
    ignore_changes = [thumbprint_list]
  }
}

resource "aws_iam_role" "github_actions" {
  name = "github-actions-${var.github_repo}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:*"
          }
        }
      }
    ]
  })

  tags = {
    Purpose = "GitHub Actions CI/CD"
  }
}

resource "aws_iam_role_policy" "github_actions_ecr" {
  name = "ecr-push"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage",
          "ecr:CreateRepository",
          "ecr:PutImageScanningConfiguration",
          "ecr:PutImageTagMutability"
        ]
        Resource = "arn:aws:ecr:${var.region}:${var.aws_account_id}:repository/*"
      }
    ]
  })
}

output "github_actions_role_arn" {
  value       = aws_iam_role.github_actions.arn
  description = "ARN of the IAM role for GitHub Actions. Add this as AWS_ROLE_ARN secret in GitHub repo settings."
}

resource "aws_iam_role_policy" "infra" {
  for_each = toset(var.services)
  name   = "${each.value}-infra"
  role   = aws_iam_role.infra[each.key].id
  policy = templatefile("policies/app-infra.json.tpl", { region = var.region, aws_account_id = var.aws_account_id, service = each.value })
}

resource "aws_iam_role" "infra" {
  for_each = toset(var.services)
  name               = "${each.value}-infra"
  assume_role_policy = templatefile("policies/app-infra-trusted.json.tpl", {
    aws_account_id = var.aws_account_id,
    service        = each.value
    trusted_roles  = local.trusted_roles
  })


  tags = {
    AppName : each.value
  }

  lifecycle {
    ignore_changes = [inline_policy]
  }
}
