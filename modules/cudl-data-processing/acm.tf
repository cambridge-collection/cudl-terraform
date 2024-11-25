resource "aws_acm_certificate" "this" {
  count = var.acm_create_certificate && var.create_cloudfront_distribution ? 1 : 0

  domain_name       = local.cloudfront_distribution_domain_name
  validation_method = "DNS"
  subject_alternative_names = [
    local.cloudfront_distribution_domain_name
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "this" {
  count = var.acm_create_certificate && var.create_cloudfront_distribution ? 1 : 0

  certificate_arn         = aws_acm_certificate.this.0.arn
  validation_record_fqdns = [for record in aws_route53_record.acm_validation_cname : record.fqdn]

  timeouts {
    create = "10m"
  }
}

resource "aws_acm_certificate" "this_us-east-1" {
  count = var.acm_create_certificate && var.create_cloudfront_distribution ? 1 : 0

  provider          = aws.us-east-1
  domain_name       = local.cloudfront_distribution_domain_name
  validation_method = "DNS"
  subject_alternative_names = [
    local.cloudfront_distribution_domain_name
  ]

  lifecycle {
    create_before_destroy = true
  }
}
