resource "aws_route53_zone" "app" {
  name = var.root_domain
}

resource "aws_route53_record" "ns" {
}
