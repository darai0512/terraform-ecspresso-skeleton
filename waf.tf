# 以下はglobal(us-east-1)リソース

resource "aws_wafv2_rule_group" "access_whitelist" {
  capacity    = 2
  name        = "access_whitelist"
  name_prefix = null
  scope       = "CLOUDFRONT"
  tags        = {}
  tags_all    = {}
  rule {
    name     = "allow_office"
    priority = 1
    action {
      allow {
      }
    }
    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.allow_office.arn
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "allow_office"
      sampled_requests_enabled   = true
    }
  }
  rule {
    name     = "allow_tailscale"
    priority = 0
    action {
      allow {
      }
    }
    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.allow_tailscale.arn
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "allow_tailscale"
      sampled_requests_enabled   = true
    }
  }
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "access_whitelist"
    sampled_requests_enabled   = true
  }
}

resource "aws_wafv2_ip_set" "allow_tailscale" {
  addresses          = ["/32"]
  description        = "via tailscale"
  ip_address_version = "IPV4"
  name               = "tailscale_ip"
  scope              = "CLOUDFRONT"
}

resource "aws_wafv2_ip_set" "allow_office" {
  addresses          = ["/32"]
  description        = "office static IP"
  ip_address_version = "IPV4"
  name               = "office"
  scope              = "CLOUDFRONT"
}