# Wildcard ACM certificate in eu-west-1 for the ALB HTTPS listener.
resource "aws_acm_certificate" "wildcard_eu_west_1" {
  domain_name               = "*.cul-development.net"
  validation_method         = "DNS"
  subject_alternative_names = ["cul-development.net"]
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "wildcard_eu_west_1" {
  certificate_arn         = aws_acm_certificate.wildcard_eu_west_1.arn
  validation_record_fqdns = [for record in aws_route53_record.wildcard_cert_validation : record.fqdn]
}

# Wildcard ACM certificate in us-east-1 for CloudFront distributions.
# CloudFront requires certs to be in us-east-1.
resource "aws_acm_certificate" "wildcard_us_east_1" {
  provider          = aws.us-east-1
  domain_name       = "*.cul-development.net"
  validation_method = "DNS"

  subject_alternative_names = ["cul-development.net"]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "wildcard_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.wildcard_us_east_1.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id         = var.cloudfront_route53_zone_id
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  ttl             = 60
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "wildcard_us_east_1" {
  provider                = aws.us-east-1
  certificate_arn         = aws_acm_certificate.wildcard_us_east_1.arn
  validation_record_fqdns = [for record in aws_route53_record.wildcard_cert_validation : record.fqdn]
}
