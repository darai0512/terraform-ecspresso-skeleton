resource "aws_lb" "app" {
  access_logs {
    bucket  = "alb-log"
    enabled = true
  }
  name                       = "app"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.loadbalancer.id]
  subnets                    = values(aws_subnet.if)[*].id
  enable_deletion_protection = false
  idle_timeout               = 60

  tags = {
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.app.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.lb_certificate_arn
  default_action {
    order            = 1
    target_group_arn = null
    type             = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = "404"
    }
  }
}
