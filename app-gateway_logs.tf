resource "aws_cloudwatch_log_group" "forwarder" {
  name              = "/forwarder"
  retention_in_days = var.app_log_retention_in_days
}

resource "aws_cloudwatch_log_group" "forwarder_service_connect" {
  name              = "/forwarder-service-connect"
  retention_in_days = var.app_log_retention_in_days
}
