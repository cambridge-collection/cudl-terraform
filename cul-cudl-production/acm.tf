resource "aws_acm_certificate" "web_frontend" {

  domain_name       = var.web_frontend_domain_name
  validation_method = "DNS"
  subject_alternative_names = [
    var.web_frontend_domain_name
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "web_frontend" {

  certificate_arn         = aws_acm_certificate.web_frontend.arn
  validation_record_fqdns = [for record in aws_route53_record.web_frontend_acm_validation_cname : record.fqdn]

  timeouts {
    create = "10m"
  }
}

resource "aws_acm_certificate" "web_frontend_us-east-1" {

  provider          = aws.us-east-1
  domain_name       = var.web_frontend_domain_name
  validation_method = "DNS"
  subject_alternative_names = [
    var.web_frontend_domain_name
  ]

  lifecycle {
    create_before_destroy = true
  }
}
