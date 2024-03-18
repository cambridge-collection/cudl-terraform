# We need to define the route53 records in both eu-west-1 and us-east-1 for the CloudFront

resource "aws_route53_zone" "cudl-route53-zone" {
  name = "cudl-sandbox.net."
}

//TODO name servers should match the registered domain name servers
// TODO at the moment we need to use console to generate these
#resource "aws_route53_record" "cudl-route53-record-ns" {
#  name = "cudl-sandbox.net."
#  type = "NS"
#  ttl = 172800
#  records = [
#    "ns-1092.awsdns-08.org.",
#    "ns-683.awsdns-21.net.",
#    "ns-1.awsdns-00.com.",
#    "ns-1729.awsdns-24.co.uk."
#  ]
#  zone_id = aws_route53_zone.cudl-route53-zone.id
#  depends_on = [
#    aws_route53_zone.cudl-route53-zone
#  ]
#}

#resource "aws_route53_record" "cudl-route53-record-soa" {
#  name = "cudl-sandbox.net."
#  type = "SOA"
#  ttl = 900
#  records = [
#    "ns-1092.awsdns-08.org. awsdns-hostmaster.amazon.com. 1 7200 900 1209600 86400"
#  ]
#  zone_id = aws_route53_zone.cudl-route53-zone.id
#  depends_on = [
#    aws_route53_zone.cudl-route53-zone
#  ]
#}

#resource "aws_route53_record" "cudl-route53-record-a" {
#  name = "${var.content-loader-domain}."
#  type = "A"
#  alias {
#    name = aws_cloudfront_distribution.cudl-content-loader-cloudfront-distribution.domain_name
#    zone_id = aws_route53_zone.cudl-route53-zone.id
#    evaluate_target_health = false
#  }
#  zone_id = aws_route53_zone.cudl-route53-zone.id
#  depends_on = [
#    aws_route53_zone.cudl-route53-zone
#  ]
#}

#resource "aws_route53_record" "cudl-route53-record-cname" {
#  name = "_14aac2bae05df7345b53650af6e2db84.${var.content-loader-domain}."
#  type = "CNAME"
#  ttl = 300
#  records = [
#    "_89b59d536159199c36bbf486389d54e7.mhbtsbpdnt.acm-validations.aws."
#  ]
#  zone_id = aws_route53_zone.cudl-route53-zone.id
#  depends_on = [
#    aws_route53_zone.cudl-route53-zone
#  ]
#}

resource "aws_acm_certificate" "cudl-certificate-default" {
  domain_name = var.content-loader-domain
  subject_alternative_names = [
    var.content-loader-domain
  ]
  validation_method = "DNS"
}

resource "aws_acm_certificate" "cudl-certificate-us-east-1" {
  provider = aws.us-east-1
  domain_name = var.content-loader-domain
  subject_alternative_names = [
    var.content-loader-domain
  ]
  validation_method = "DNS"
}

resource "aws_ssm_parameter" "cudl-content-loader-ssm-dl-loader-ui-s3-access-key-id" {
  name = "/${var.environment}/cudl/dl-loader-ui/AWS_S3_ACCESS_KEY_ID"
  type = "SecureString"
  value = aws_iam_access_key.cudl-content-loader-iam-access-key.id
  depends_on = [
    aws_iam_access_key.cudl-content-loader-iam-access-key
  ]
}

resource "aws_ssm_parameter" "cudl-content-loader-ssm-dl-loader-ui-s3-access-key" {
  name = "/${var.environment}/cudl/dl-loader-ui/AWS_S3_SECRET_ACCESS_KEY"
  type = "SecureString"
  value = aws_iam_access_key.cudl-content-loader-iam-access-key.secret
  depends_on = [
    aws_iam_access_key.cudl-content-loader-iam-access-key
  ]
}
