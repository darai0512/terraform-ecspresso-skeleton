network = {
  vpc_cidr_block = "10.0.0.0/16"
  subnets = {
    a = {
      "hoge"  = "10.0.100.0/22"
      "vpce"   = "10.0.108.0/24"
    }
    c = {
      "d"  = "10.0.104.0/22"
      "vpce" = "10.0.117.0/24"
    }
  }
}

root_domain = "example.com"

slack_team_id          = ""
slack_alert_channel_id = ""

## Cloudwatch
gateway_services = [
  {
    name             = "a"
    metric_id_number = 0
    task_count       = 1
  },
  {
    name             = "b"
    metric_id_number = 1
    task_count       = 1
  }
]

alert = [
  {
    level   = "Warning"
    percent = 85
  },
  {
    level   = "Critical"
    percent = 90
  }
]

app_services = [
  {
    name             = "api"
    metric_id_number = 0
    task_count       = 2
  }
]

app_log_retention_in_days = 7
