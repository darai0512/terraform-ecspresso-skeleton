#region openid connect provider
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
  client_id_list = [
    "sts.amazonaws.com",
  ]
  thumbprint_list = [""] # 固定値。最新verなどで不要？不要化の動きが活発
}
#endregion

# Chatbot IAM role
data "aws_iam_policy_document" "chatbot_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["chatbot.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}
resource "aws_iam_role" "AWSChatBotRole" {
  name               = "AWSChatBotRole"
  path               = "/service-role/"
  assume_role_policy = data.aws_iam_policy_document.chatbot_assume_role.json
}

同時通訳
電話通訳
