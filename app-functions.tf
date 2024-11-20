resource "aws_cloudfront_function" "rate_limit" {
  comment                      = null
  key_value_store_associations = []
  name                         = "rate_limit"
  publish                      = true
  runtime                      = "cloudfront-js-2.0"
  code                         = file("${path.module}/functions/rateLimit.js")
}
