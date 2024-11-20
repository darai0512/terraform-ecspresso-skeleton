resource "aws_sns_topic" "send_alert" {
  name = "send_alert"
}

resource "aws_chatbot_slack_channel_configuration" "send_alert" {
  configuration_name = "send_alert"
  slack_team_id      = var.slack_team_id
  slack_channel_id   = var.slack_alert_channel_id
  iam_role_arn       = aws_iam_role.AWSChatBotRole.arn
  sns_topic_arns     = [aws_sns_topic.send_alert.arn]
}
