locals {
  services = flatten([
    for services in var.gateway_services : [
      for alert in var.alert : {
        name             = services.name
        metric_id_number = services.metric_id_number
        level            = alert.level
        percent          = alert.percent
      }
    ]
  ])
}

## RunningTaskCountは0になった場合にアラートを発生させる
resource "aws_cloudwatch_metric_alarm" "running_task_count" {
  for_each = { for i in local.services : "${i.name}-${i.level}" => i
    if i.level == "${element(var.alert, 1).level}" # `Critical`レベルのみを対象とする条件
  }
  alarm_name = "${each.value.level}-gateway-${each.value.name}-RunningTaskCount"
  namespace  = "ECS/ContainerInsights"
  dimensions = {
    "ClusterName" = "gateway"
    "ServiceName" = each.value.name
  }
  metric_name         = "RunningTaskCount"
  comparison_operator = "LessThanOrEqualToThreshold"
  threshold           = 0
  statistic           = "Average"
  evaluation_periods  = 1
  period              = 60
  datapoints_to_alarm = 1
  alarm_actions = [
    aws_sns_topic.send_alert.arn,
  ]
  ok_actions = [
    aws_sns_topic.send_alert.arn,
  ]
}

resource "aws_cloudwatch_metric_alarm" "cpu_utilization" {
  for_each            = { for i in local.services : "${i.name}-${i.level}" => i }
  alarm_name          = "${each.value.level}-gateway-${each.value.name}-CpuUtilization"
  comparison_operator = "GreaterThanThreshold"
  threshold           = each.value.percent
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  treat_missing_data  = "notBreaching"
  alarm_actions = [
    aws_sns_topic.send_alert.arn,
  ]
  ok_actions = [
    aws_sns_topic.send_alert.arn,
  ]

  metric_query {
    account_id  = null
    expression  = "mm1m${each.value.metric_id_number} * 100 / mm0m${each.value.metric_id_number}"
    id          = "expr1m${each.value.metric_id_number}"
    label       = each.value.name
    period      = 0
    return_data = true
  }
  metric_query {
    account_id  = data.aws_caller_identity.current.account_id
    expression  = null
    id          = "mm0m${each.value.metric_id_number}"
    label       = null
    period      = 0
    return_data = false
    metric {
      dimensions = {
        "ClusterName" = "gateway"
        "ServiceName" = each.value.name
      }
      metric_name = "CpuReserved"
      namespace   = "ECS/ContainerInsights"
      period      = 60
      stat        = "Sum"
      unit        = null
    }
  }
  metric_query {
    account_id  = data.aws_caller_identity.current.account_id
    expression  = null
    id          = "mm1m${each.value.metric_id_number}"
    label       = null
    period      = 0
    return_data = false
    metric {
      dimensions = {
        "ClusterName" = "gateway"
        "ServiceName" = each.value.name
      }
      metric_name = "CpuUtilized"
      namespace   = "ECS/ContainerInsights"
      period      = 60
      stat        = "Sum"
      unit        = null
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "memory_utilization" {
  for_each            = { for i in local.services : "${i.name}-${i.level}" => i }
  alarm_name          = "${each.value.level}-gateway-${each.value.name}-MemoryUtilization"
  comparison_operator = "GreaterThanThreshold"
  threshold           = each.value.percent
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  treat_missing_data  = "notBreaching"
  alarm_actions = [
    aws_sns_topic.send_alert.arn,
  ]
  ok_actions = [
    aws_sns_topic.send_alert.arn,
  ]

  metric_query {
    account_id  = null
    expression  = "mm1m${each.value.metric_id_number} * 100 / mm0m${each.value.metric_id_number}"
    id          = "expr1m${each.value.metric_id_number}"
    label       = each.value.name
    period      = 0
    return_data = true
  }
  metric_query {
    account_id  = data.aws_caller_identity.current.account_id
    expression  = null
    id          = "mm0m${each.value.metric_id_number}"
    label       = null
    period      = 0
    return_data = false
    metric {
      dimensions = {
        "ClusterName" = "gateway"
        "ServiceName" = each.value.name
      }
      metric_name = "MemoryReserved"
      namespace   = "ECS/ContainerInsights"
      period      = 60
      stat        = "Sum"
      unit        = null
    }
  }
  metric_query {
    account_id  = data.aws_caller_identity.current.account_id
    expression  = null
    id          = "mm1m${each.value.metric_id_number}"
    label       = null
    period      = 0
    return_data = false
    metric {
      dimensions = {
        "ClusterName" = "gateway"
        "ServiceName" = each.value.name
      }
      metric_name = "MemoryUtilized"
      namespace   = "ECS/ContainerInsights"
      period      = 60
      stat        = "Sum"
      unit        = null
    }
  }
}
