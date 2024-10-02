{
    "Statement": [
        {
            "Action": [
                "ecr:UploadLayerPart",
                "ecr:PutImage",
                "ecr:ListImages",
                "ecr:InitiateLayerUpload",
                "ecr:GetDownloadUrlForLayer",
                "ecr:DescribeImages",
                "ecr:CompleteLayerUpload",
                "ecr:BatchGetImage",
                "ecr:BatchCheckLayerAvailability",
                "ecr:SetRepositoryPolicy"
            ],
            "Effect": "Allow",
            "Resource": "arn:aws:ecr:${region}:${aws_account_id}:repository/$${aws:PrincipalTag/AppName}*",
            "Sid": "EcrAccessLimitedToRepo"
        },
        {
            "Action": [
                "ecr:GetAuthorizationToken",
                "ecr:CreateRepository",
                "ecr:DescribeRepositories"
            ],
            "Effect": "Allow",
            "Resource": "*",
            "Sid": "ECRAllowAll"
        },

        {
            "Action": "iam:ListRoles",
            "Effect": "Allow",
            "Resource": "*",
            "Sid": "IAMListRoles"
        },
        {
            "Action": [
                "codeartifact:Read*",
                "codeartifact:PutPackageMetadata",
                "codeartifact:PublishPackageVersion",
                "codeartifact:List*",
                "codeartifact:Get*",
                "codeartifact:Describe*"
            ],
            "Effect": "Allow",
            "Resource": [
                "arn:aws:codeartifact:${region}:835811189142:repository/dsi/dsi_repository",
                "arn:aws:codeartifact:${region}:835811189142:package/dsi/dsi_repository/npm/*",
                "arn:aws:codeartifact:${region}:835811189142:package/dsi/dsi_repository/maven/*",
                "arn:aws:codeartifact:${region}:835811189142:domain/dsi"
            ],
            "Sid": "CodeArtifact"
        },
        {
            "Action": [
                "sts:GetServiceBearerToken"
            ],
            "Effect": "Allow",
            "Resource": [
                "*"
            ],
            "Sid": "BearerTokenForCodeartifact"
        },
        {
            "Action": [
                "secretsmanager:DescribeSecret",
                "secretsmanager:GetSecretValue",
                "secretsmanager:ListSecretVersionIds",
                "ssm:Get*",
                "ssm:PutParameter",
                "ssm:DeleteParameter",
                "ssm:RemoveTagsFromResource",
                "ssm:AddTagsToResource",
                "ssm:DeleteParameters"
            ],
            "Condition": {
                "StringNotLike": {
                    "aws:userid": "*-cicd"
                }
            },
            "Effect": "Allow",
            "Resource": [
                "arn:aws:ssm:*:*:parameter/config/$${aws:PrincipalTag/AppName}*",
                "arn:aws:ssm:*:*:parameter/$${aws:PrincipalTag/AppName}/*",
                "arn:aws:ssm:*:*:parameter/config/*_*/$${aws:PrincipalTag/AppName}-client-credentials",
                "arn:aws:secretsmanager:*:*:secret:$${aws:PrincipalTag/AppName}-*"
            ]
        },
        {
            "Action": [
                "ssm:GetConnectionStatus",
                "ec2:DescribeInstances",
                "ssm:Describe*",
                "secretsmanager:List*"
            ],
            "Condition": {
                "StringNotLike": {
                    "aws:userid": "*-cicd"
                }
            },
            "Effect": "Allow",
            "Resource": "*"
        },
        {
            "Action": "ssm:StartSession",
            "Condition": {
                "StringLike": {
                    "ssm:resourceTag/Name": "*-bastion"
                },
                "StringNotLike": {
                    "aws:userid": "*-cicd"
                }
            },
            "Effect": "Allow",
            "Resource": "arn:aws:ec2:${region}:${aws_account_id}:instance/*"
        },
        {
            "Action": [
                "ssm:StartSession"
            ],
            "Condition": {
                "StringNotLike": {
                    "aws:userid": "*-cicd"
                }
            },
            "Effect": "Allow",
            "Resource": "arn:aws:ssm:${region}::document/AWS-StartPortForwardingSessionToRemoteHost"
        },
        {
            "Action": [
                "ssm:ResumeSession",
                "ssm:TerminateSession"
            ],
            "Condition": {
                "StringNotLike": {
                    "aws:userid": "*-cicd"
                }
            },
            "Effect": "Allow",
            "Resource": "arn:aws:ssm:*:*:session/$${aws:username}-*"
        },
        {
            "Action": [
                "rds:DescribeDBInstances"
            ],
            "Condition": {
                "StringNotLike": {
                    "aws:userid": "*-cicd"
                }
            },
            "Effect": "Allow",
            "Resource": "arn:aws:rds:${region}:${aws_account_id}:db:*"
        }
    ],
    "Version": "2012-10-17"
}
