locals {
  api_domain = "api.${data.aws_route53_zone.app.name}"
}

resource "aws_cloudwatch_log_group" "api" {
  name              = "/sample/${var.app_name}/api"
  retention_in_days = var.app_log_retention_in_days
}

resource "aws_route53_record" "api" {
  zone_id = data.aws_route53_zone.app.zone_id
  name    = local.api_domain
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.api.domain_name
    zone_id                = aws_cloudfront_distribution.api.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_lb_listener_rule" "api" {
  listener_arn = var.app_alb_listener_arn
  priority     = 1
  tags = {
    Name = "${var.app_name}-api"
  }
  action {
    order            = 1
    target_group_arn = aws_lb_target_group.api.arn
    type             = "forward"
  }
  condition {
    host_header {
      values = [local.api_domain]
    }
  }
}

resource "aws_lb_target_group" "api" {
  name                 = "${var.app_name}-api"
  port                 = 800
  protocol             = "HTTP"
  target_type          = "ip"
  deregistration_delay = 5
  vpc_id               = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 5
    matcher             = "200"
    path                = "/.hello"
    protocol            = "HTTP"
    timeout             = 2
  }
}

resource "aws_cloudfront_distribution" "api" {
  aliases         = [local.api_domain]
  enabled         = true
  http_version    = "http2"
  is_ipv6_enabled = true
  price_class     = "PriceClass_All"
  web_acl_id      = local.web_acl_id
  default_cache_behavior {
    allowed_methods          = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cache_policy_id          = "" # todo
    cached_methods           = ["GET", "HEAD", "OPTIONS"]
    compress                 = true
    origin_request_policy_id = "" # todo
    target_origin_id         = "api"
    viewer_protocol_policy   = "redirect-to-https"
    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.rate_limit.arn
    }
  }
  logging_config {
    bucket          = "" # todo
    include_cookies = true
    prefix          = null
  }
  origin {
    connection_attempts      = 3
    connection_timeout       = 10
    domain_name              = var.app_alb_dns_name
    origin_access_control_id = null
    origin_id                = "api"
    origin_path              = null
    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_keepalive_timeout = 5
      origin_protocol_policy   = "https-only"
      origin_read_timeout      = 30
      origin_ssl_protocols     = ["TLSv1.2"]
    }
  }
  restrictions {
    geo_restriction {
      locations        = []
      restriction_type = "none"
    }
  }
  viewer_certificate {
    acm_certificate_arn            = var.global_certificate_arn
    cloudfront_default_certificate = false
    iam_certificate_id             = null
    minimum_protocol_version       = "TLSv1.2_2021"
    ssl_support_method             = "sni-only"
  }
}
