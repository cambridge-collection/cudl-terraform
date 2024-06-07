locals {
  transcriptions_domain_name = "${var.environment}-transcriptions.${data.aws_route53_zone.domain.name}"
}

data "aws_route53_zone" "domain" {
  zone_id = var.route53_zone_id
}

resource "aws_acm_certificate" "transcriptions" {
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
  certificate_arn         = aws_acm_certificate.transcriptions.arn
  validation_record_fqdns = [for record in aws_route53_record.transcriptions_acm_validation_cname : record.fqdn]

  timeouts {
    create = "10m"
  }
}

resource "aws_acm_certificate" "transcriptions_us-east-1" {
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
