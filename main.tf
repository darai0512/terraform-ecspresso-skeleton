provider "aws" {
  alias   = "staging"
  profile = "staging"
  region  = "ap-northeast-1"
}

provider "aws" {
  alias   = "production"
  profile = "production"
  region  = "ap-northeast-1"
}

provider "aws" {
  alias   = "global"
  profile = "staging"
  region  = "us-east-1"
}


terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.76.0"
    }
  }
  backend "s3" {
    region               = "ap-northeast-1"
    profile              = "staging"
    bucket               = "sample-tfstate"
    key                  = "terraform.tfstate"
    workspace_key_prefix = "infra"
  }

}

module "app" {
  source   = "./app"
  for_each = var.apps

  app_name   = each.key
  app_domain = contains(["staging", "production"], each.key) ? var.root_domain : "${each.key}.${var.root_domain}"
  account_id = data.aws_caller_identity.current.account_id

  # arns
  namespace_arn = aws_service_discovery_http_namespace.sample_app.arn
  deployer_arns = aws_iam_role.app_deployer.arn
  app_task_execution_role_arn = aws_iam_role.app_task_execution.arn
  app_task_role_arn           = aws_iam_role.app_task.arn

  # app network
  regional_certificate_arn = var.lb_certificate_arn
  global_certificate_arn   = var.acm_certificate_arn
  app_alb_dns_name         = aws_lb.app.dns_name
  app_alb_listener_arn     = aws_lb_listener.https.arn

  # cache
  cache_subnet_group_name  = aws_elasticache_subnet_group.app.name
  cache_security_group_ids = [aws_security_group.redis.id]

  # vpc
  vpc_id                   = aws_vpc.sample.id
  dynamodb_vpc_endpoint_id = aws_vpc_endpoint.dynamodb.id

  ## Cloudwatch
  app_services = var.app_services
  alert    = var.alert

  sns_topic_arns = {
    ok_action    = aws_sns_topic.send_alert.arn
    alarm_action = aws_sns_topic.send_alert.arn
  }

  app_log_retention_in_days = var.app_log_retention_in_days
}
