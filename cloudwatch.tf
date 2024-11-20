resource "aws_cloudwatch_log_group" "ecs_demo" {
  name = "ecs/sample-${terraform.workspace}"
}
