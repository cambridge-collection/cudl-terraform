data "aws_route53_zone" "domain" {

  zone_id = var.cloudfront_route53_zone_id
}

resource "aws_route53_record" "web_frontend_cloudfront_alias" {

  name = var.web_frontend_domain_name # NOTE match CloudFront Distribution alias
  type = "A"
  alias {
    name                   = aws_cloudfront_distribution.web_frontend.domain_name
    zone_id                = aws_cloudfront_distribution.web_frontend.hosted_zone_id
    evaluate_target_health = false
  }
  zone_id = data.aws_route53_zone.domain.zone_id
}

resource "aws_route53_record" "web_frontend_acm_validation_cname" {
  for_each = {
    for dvo in aws_acm_certificate.web_frontend.domain_validation_options : dvo.domain_name => {
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
  zone_id         = data.aws_route53_zone.domain.zone_id
}
