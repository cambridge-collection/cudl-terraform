resource "aws_acm_certificate" "transcriptions" {
  count = local.create_cloudfront_distribution ? 1 : 0

  domain_name       = local.transcriptions_domain_name
  validation_method = "DNS"
  subject_alternative_names = [
    local.transcriptions_domain_name
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "transcriptions" {
  count = local.create_cloudfront_distribution ? 1 : 0

  certificate_arn         = aws_acm_certificate.transcriptions.0.arn
  validation_record_fqdns = [for record in aws_route53_record.transcriptions_acm_validation_cname : record.fqdn]

  timeouts {
    create = "10m"
  }
}

resource "aws_acm_certificate" "transcriptions_us-east-1" {
  count = local.create_cloudfront_distribution ? 1 : 0

  provider          = aws.us-east-1
  domain_name       = local.transcriptions_domain_name
  validation_method = "DNS"
  subject_alternative_names = [
    local.transcriptions_domain_name
  ]

  lifecycle {
    create_before_destroy = true
  }
}
