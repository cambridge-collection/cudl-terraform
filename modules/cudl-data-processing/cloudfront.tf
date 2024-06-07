data "aws_cloudfront_cache_policy" "managed_caching_disabled" {
  provider = aws.us-east-1
  name     = "Managed-CachingDisabled"
}

data "aws_cloudfront_origin_request_policy" "managed_all_viewer" {
  provider = aws.us-east-1
  name     = "Managed-AllViewer"
}

resource "aws_cloudfront_origin_access_control" "transcriptions" {
  name                              = aws_s3_bucket.dest-bucket.id
  description                       = "Access Control for ${aws_s3_bucket.dest-bucket.id}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "transcriptions" {
  provider = aws.us-east-1

  comment      = "${aws_acm_certificate.transcriptions_us-east-1.domain_name} CloudFront Distribution"
  price_class  = "PriceClass_100"
  enabled      = true
  http_version = "http2"
  web_acl_id   = aws_wafv2_web_acl.transcriptions.arn
  # is_ipv6_enabled = true
  # default_root_object = "index.html"

  aliases = [
    aws_acm_certificate.transcriptions_us-east-1.domain_name
  ]

  origin {
    domain_name              = aws_s3_bucket.dest-bucket.bucket_regional_domain_name
    origin_id                = aws_acm_certificate.transcriptions_us-east-1.domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.transcriptions.id
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    smooth_streaming       = false
    target_origin_id       = aws_acm_certificate.transcriptions_us-east-1.domain_name
    viewer_protocol_policy = "redirect-to-https"
    cache_policy_id        = data.aws_cloudfront_cache_policy.managed_caching_disabled.id
    # origin_request_policy_id = data.aws_cloudfront_origin_request_policy.managed_all_viewer.id
  }

  viewer_certificate {
    acm_certificate_arn            = aws_acm_certificate.transcriptions_us-east-1.arn
    cloudfront_default_certificate = false
    minimum_protocol_version       = "TLSv1.2_2021"
    ssl_support_method             = "sni-only"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}
