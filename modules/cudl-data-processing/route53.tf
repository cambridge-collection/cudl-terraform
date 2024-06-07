resource "aws_route53_record" "transcriptions_cloudfront_alias" {
  name = aws_acm_certificate.transcriptions_us-east-1.domain_name # NOTE match CloudFront Distribution alias
  type = "A"
  alias {
    name                   = aws_cloudfront_distribution.transcriptions.domain_name
    zone_id                = aws_cloudfront_distribution.transcriptions.hosted_zone_id
    evaluate_target_health = false
  }
  zone_id = var.route53_zone_id
}

resource "aws_route53_record" "transcriptions_acm_validation_cname" {
  for_each = {
    for dvo in aws_acm_certificate.transcriptions.domain_validation_options : dvo.domain_name => {
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
  zone_id         = var.route53_zone_id
}
