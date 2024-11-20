resource "aws_ecr_repository" "app" {
  name                 = "sample/app"
  image_tag_mutability = "IMMUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "app_testing" {
  name                 = "sample/app-testing"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}

data "aws_iam_policy_document" "app" {

  version = "2008-10-17"
  statement {
    sid    = "AllowPushFromDeployer"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.app_deployer.arn]
    }
    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload"
    ]
  }

  statement {
    sid    = "AllowPullFromApp"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.app_task_execution.arn]
    }
    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
    ]
  }

}

resource "aws_ecr_repository_policy" "app" {
  repository = aws_ecr_repository.app_testing.name
  policy     = data.aws_iam_policy_document.app.json
}

resource "aws_ecr_repository_policy" "app_testing" {
  repository = aws_ecr_repository.app_testing.name
  policy     = data.aws_iam_policy_document.app.json
}

resource "aws_ecr_repository" "squid" {
  name                 = "${terraform.workspace}/sample/squid"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository_policy" "squid" {
  repository = aws_ecr_repository.squid.name
  policy = jsonencode({
    Version = "2008-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = [aws_iam_role.app_task.arn]
        },
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
        ],
      }
    ]
  })
}
