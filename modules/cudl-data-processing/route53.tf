data "aws_route53_zone" "domain" {
  count = local.create_cloudfront_distribution ? 1 : 0

  zone_id = var.route53_zone_id
}

resource "aws_route53_record" "transcriptions_cloudfront_alias" {
  count = local.create_cloudfront_distribution ? 1 : 0

  name = aws_acm_certificate.transcriptions_us-east-1.0.domain_name # NOTE match CloudFront Distribution alias
  type = "A"
  alias {
    name                   = aws_cloudfront_distribution.transcriptions.0.domain_name
    zone_id                = aws_cloudfront_distribution.transcriptions.0.hosted_zone_id
    evaluate_target_health = false
  }
  zone_id = data.aws_route53_zone.domain.0.zone_id
}

resource "aws_route53_record" "transcriptions_acm_validation_cname" {
  for_each = {
    for dvo in aws_acm_certificate.transcriptions.0.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 300
  type            = each.value.type
  zone_id         = data.aws_route53_zone.domain.0.zone_id
}
