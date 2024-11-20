resource "aws_ecs_cluster" "gateway" {
  name = "gateway"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  configuration {
    execute_command_configuration {
      logging = "OVERRIDE"

      log_configuration {
        cloud_watch_encryption_enabled = false
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.ecs_demo.name
      }
    }
  }

  service_connect_defaults {
    namespace = aws_service_discovery_http_namespace.sample_app.arn
  }
}

resource "aws_ecs_cluster_capacity_providers" "gateway" {
  cluster_name       = aws_ecs_cluster.gateway.name
  capacity_providers = ["FARGATE"]
  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}
