data "aws_cloudfront_cache_policy" "managed_caching_disabled" {
  provider = aws.us-east-1
  name     = "Managed-CachingDisabled"
}

resource "aws_cloudfront_origin_access_control" "this" {
  count = var.create_cloudfront_distribution ? 1 : 0

  name                              = aws_s3_bucket.dest-bucket.id
  description                       = "Access Control for ${aws_s3_bucket.dest-bucket.id}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "this" {
  count = var.create_cloudfront_distribution ? 1 : 0

  provider = aws.us-east-1

  comment             = "${local.cloudfront_distribution_domain_name} CloudFront Distribution"
  price_class         = "PriceClass_100"
  enabled             = true
  http_version        = "http2"
  web_acl_id          = aws_wafv2_web_acl.this.0.arn
  default_root_object = var.cloudfront_default_root_object

  aliases = [
    local.cloudfront_distribution_domain_name
  ]

  origin {
    domain_name              = aws_s3_bucket.dest-bucket.bucket_regional_domain_name
    origin_id                = local.cloudfront_distribution_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.this.0.id
    origin_path              = var.cloudfront_origin_path
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    smooth_streaming       = false
    target_origin_id       = local.cloudfront_distribution_domain_name
    viewer_protocol_policy = "redirect-to-https"
    cache_policy_id        = data.aws_cloudfront_cache_policy.managed_caching_disabled.id

    dynamic "function_association" {
      for_each = var.cloudfront_viewer_request_function_arn != null ? [1] : []
      content {
        event_type   = "viewer-request"
        function_arn = var.cloudfront_viewer_request_function_arn
      }
    }
  }

  dynamic "custom_error_response" {
    for_each = var.cloudfront_error_response_page_path != null ? [1] : []

    content {
      error_code            = var.cloudfront_error_code_to_catch
      response_code         = var.cloudfront_error_response_code
      response_page_path    = var.cloudfront_error_response_page_path
      error_caching_min_ttl = var.cloudfront_error_caching_min_ttl
    }
  }

  viewer_certificate {
    acm_certificate_arn            = var.acm_create_certificate ? aws_acm_certificate.this_us-east-1.0.arn : var.acm_certificate_arn
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
