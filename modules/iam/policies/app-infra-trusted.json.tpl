{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${aws_account_id}:root"
            },
            "Action": [
                "sts:AssumeRole",
                "sts:TagSession"
            ],
            "Condition": {
                "ArnLike": {
                    "aws:PrincipalArn": [
                    %{ for item in trusted_roles ~}
                    "${item}"%{ if item != trusted_roles[length(trusted_roles) - 1] },%{ endif ~}
                    %{ endfor ~}
                    ]
                }
            }
        },
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::${aws_account_id}:oidc-provider/token.actions.githubusercontent.com"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
                },
                "StringLike": {
                    "sts:RoleSessionName": "*-cicd"
                },
                "ForAllValues:StringLike": {
                    "token.actions.githubusercontent.com:sub": [
                        "repo:tfmcdigital/${service}:*"
                    ]
                }
            }
        }
    ]
}
