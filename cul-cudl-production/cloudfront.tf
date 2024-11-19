data "aws_cloudfront_cache_policy" "managed_caching_disabled" {
  provider = aws.us-east-1
  # CHange to Managed-CachingOptimized to enable changing
  name = "Managed-CachingDisabled"
}

resource "aws_cloudfront_origin_access_control" "web_frontend" {

  name                              = format("%s-darwin", module.cudl-data-processing.destination_bucket)
  description                       = "Access Control for ${module.cudl-data-processing.destination_bucket}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "web_frontend" {

  provider = aws.us-east-1

  comment             = "${var.web_frontend_domain_name} CloudFront Distribution"
  price_class         = "PriceClass_100"
  enabled             = true
  http_version        = "http2"
  web_acl_id          = aws_wafv2_web_acl.web_frontend.arn
  default_root_object = "index.html"

  aliases = [
    var.web_frontend_domain_name
  ]

  origin {
    domain_name              = module.cudl-data-processing.destination_regional_domain_name
    origin_id                = var.web_frontend_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.web_frontend.id
    origin_path              = "/www"
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    smooth_streaming       = false
    target_origin_id       = var.web_frontend_domain_name
    viewer_protocol_policy = "redirect-to-https"
    cache_policy_id        = data.aws_cloudfront_cache_policy.managed_caching_disabled.id

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.darwin.arn
    }
  }

  viewer_certificate {
    acm_certificate_arn            = aws_acm_certificate.web_frontend_us-east-1.arn
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

resource "aws_cloudfront_function" "darwin" {
  name    = "clean_urls"
  runtime = "cloudfront-js-2.0"
  comment = "clean-and-redirect"
  publish = true
  code    = file("${path.module}/templates/darwin/cloudfront-function.js.ttfpl")
}
