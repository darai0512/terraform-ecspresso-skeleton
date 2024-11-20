##############################################################
# 環境内のecsで共用のリソース
##############################################################

##################################################
# namespace
resource "aws_service_discovery_http_namespace" "sample_app" {
  name = "sample-app"
}

# assume

data "aws_iam_policy_document" "ecs_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

data "aws_iam_policy_document" "ECSExecFargate" {
  statement {
    actions = [
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:CreateControlChannel",
      "logs:DescribeLogGroups",
      "logs:CreateLogStream",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}
resource "aws_iam_policy" "ECSExecFargate" {
  name        = "SampleECSExecFargate"
  policy      = data.aws_iam_policy_document.ECSExecFargate.json
}
# ECSExecするならつける　
# resource "aws_iam_role_policy_attachment" "ecs_exec" {
#   role       = aws_iam_role.app_task.name
#   policy_arn = aws_iam_policy.ECSExecFargate.arn
# }


#######
# task-execution: この例では同じものを使い回す

resource "aws_iam_role" "app_task_execution" {
  name               = "sample-app-task-execution"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json
}

# execution roleはimage pullとlogstreamの操作の権限が必要。
# builtinのAmazonECSTaskExecutionRolePolicyには両方の権限があるが、ecr:GetAuthorizationToken以外の権限はecrのresource policyで付与するので不要。

resource "aws_iam_policy" "minimal_task_execution" {
  name        = "SampleMinimalTaskExecution"
  description = "Minimal policy for task execution role"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "ecr:GetAuthorizationToken"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "app_task_execution_logs" {
  role       = aws_iam_role.app_task_execution.id
  policy_arn = aws_iam_policy.minimal_task_execution.arn
}

#####
# task
#####

resource "aws_iam_role" "app_task" {
  name               = "sample-app-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json
}

resource "aws_iam_role_policy" "app_ses" {
  role = aws_iam_role.app_task.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ],
        Resource = "*",
        Condition = {
          StringEquals = {
            "aws:sourceVpc" = aws_vpc.sample.id
          }
        }
      }
    ]
  })
}
