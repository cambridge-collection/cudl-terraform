locals {
  cache_policy_names = toset(concat(
    [var.cloudfront_default_cache_policy],
    [for b in var.cloudfront_ordered_cache_behaviors : b.cache_policy_name if !b.prevent_all_caching],
  ))
  prevent_all_caching_used = anytrue([for b in var.cloudfront_ordered_cache_behaviors : b.prevent_all_caching])
  policy_name_prefix       = replace(local.cloudfront_distribution_domain_name, ".", "-")
}

data "aws_cloudfront_cache_policy" "selected" {
  for_each = local.cache_policy_names
  provider = aws.us-east-1
  name     = each.value
}

# NOTE No managed cache policy combines zero TTLs with compression support, so behaviors that must
# stay uncached would otherwise also be served uncompressed
resource "aws_cloudfront_cache_policy" "no_caching" {
  count    = var.create_cloudfront_distribution && local.prevent_all_caching_used ? 1 : 0
  provider = aws.us-east-1

  name        = "${local.policy_name_prefix}-no-caching"
  comment     = "Zero TTLs with Gzip and Brotli enabled"
  min_ttl     = 0
  default_ttl = 0
  max_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_gzip   = true
    enable_accept_encoding_brotli = true

    cookies_config {
      cookie_behavior = "none"
    }
    headers_config {
      header_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "none"
    }
  }
}

# NOTE A cache policy only stops CloudFront caching; without this header the browser is free to
# cache heuristically. No AWS managed response headers policy sets Cache-Control
resource "aws_cloudfront_response_headers_policy" "no_store" {
  count    = var.create_cloudfront_distribution && local.prevent_all_caching_used ? 1 : 0
  provider = aws.us-east-1

  name    = "${local.policy_name_prefix}-no-store"
  comment = "Prevents browser and proxy caching"

  custom_headers_config {
    items {
      header   = "Cache-Control"
      value    = "no-store"
      override = true
    }
  }
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

  aliases = concat([
    local.cloudfront_distribution_domain_name
  ], var.cloudfront_alternative_domain_names)

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
    cache_policy_id        = data.aws_cloudfront_cache_policy.selected[var.cloudfront_default_cache_policy].id

    dynamic "function_association" {
      for_each = var.cloudfront_viewer_request_function_arn != null ? [1] : []
      content {
        event_type   = "viewer-request"
        function_arn = var.cloudfront_viewer_request_function_arn
      }
    }
  }

  dynamic "ordered_cache_behavior" {
    for_each = var.cloudfront_ordered_cache_behaviors
    content {
      path_pattern               = ordered_cache_behavior.value.path_pattern
      allowed_methods            = ordered_cache_behavior.value.allowed_methods
      cached_methods             = ordered_cache_behavior.value.cached_methods
      compress                   = ordered_cache_behavior.value.compress
      target_origin_id           = local.cloudfront_distribution_domain_name
      viewer_protocol_policy     = "redirect-to-https"
      cache_policy_id            = ordered_cache_behavior.value.prevent_all_caching ? one(aws_cloudfront_cache_policy.no_caching[*].id) : data.aws_cloudfront_cache_policy.selected[ordered_cache_behavior.value.cache_policy_name].id
      response_headers_policy_id = ordered_cache_behavior.value.prevent_all_caching ? one(aws_cloudfront_response_headers_policy.no_store[*].id) : ordered_cache_behavior.value.response_headers_policy_id

      dynamic "function_association" {
        for_each = ordered_cache_behavior.value.attach_viewer_request_function && var.cloudfront_viewer_request_function_arn != null ? [1] : []
        content {
          event_type   = "viewer-request"
          function_arn = var.cloudfront_viewer_request_function_arn
        }
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

  dynamic "logging_config" {
    for_each = var.cloudfront_access_logging ? [1] : []
    content {
      include_cookies = false
      bucket          = var.cloudfront_access_logging_bucket
      prefix          = local.cloudfront_distribution_domain_name
    }
  }
}
