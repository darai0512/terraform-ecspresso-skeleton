locals {
  org_id     = ""
}

resource "aws_iam_openid_connect_provider" "circleci" {
  url = "https://oidc.circleci.com/org/${local.org_id}"
  client_id_list = [
    local.org_id
  ]

  thumbprint_list = [""]
}

resource "aws_iam_role" "app_deployer" {
  name = "app-deployer"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = aws_iam_openid_connect_provider.circleci.arn
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringLike = {
            "${aws_iam_openid_connect_provider.circleci.url}:sub" = "org/${local.org_id}/project/__project_id__/user/*"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "ecspresso" {
  role = aws_iam_role.app_deployer.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "ecspresso",
        "Effect" : "Allow",
        "Action" : [
          # https://zenn.dev/fujiwara/books/ecspresso-handbook-v2/viewer/reference
          "ecs:*",
          "servicediscovery:GetNamespace",
          "iam:PassRole",
          "application-autoscaling:Describe*",
          "application-autoscaling:Register*",
        ],
        "Resource" : "*"
        }, {
        "Sid" : "ecschedule",
        "Effect" : "Allow",
        "Action" : [
          # ecspressoの権限で足りない分
          "events:ListRules",
          "events:ListTargetsByRule",
        ],
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "ecr_authentication" {
  name = "SampleECRAuthentication"
  role = aws_iam_role.app_deployer.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ecr:GetAuthorizationToken"
        ],
        Resource = "*",
      },
    ],
  })

}