network = {
  vpc_cidr_block = "10.0.0.0/16"
  subnets = {
    a = {
      "hoge"  = "10.0.100.0/22"
      "vpce" = "10.0.116.0/24"
    }
    c = {
      "hoge"  = "10.0.104.0/22"
      "vpce" = "10.0.117.0/24"
    }
  }
}

root_domain = ""

slack_team_id          = ""
slack_alert_channel_id = ""

app_log_retention_in_days = 365
