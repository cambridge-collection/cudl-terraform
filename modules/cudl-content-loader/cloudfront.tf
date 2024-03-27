resource "aws_cloudfront_distribution" "cudl-content-loader-cloudfront-distribution" {
  provider = aws.us-east-1

  origin {
    custom_origin_config {
      http_port = 80
      https_port = 443
      origin_keepalive_timeout = 5
      origin_protocol_policy = "https-only"
      origin_read_timeout = 30
      origin_ssl_protocols = [
        "TLSv1.2"
      ]
    }
    domain_name = aws_lb.cudl-content-elastic-load-balancer.dns_name
    origin_id = aws_lb.cudl-content-elastic-load-balancer.dns_name
    origin_path = ""
  }

  //TODO create and link waf
  //web_acl_id = "arn:aws:wafv2:us-east-1:563181399728:global/webacl/CreatedByCloudFront-43355072-4897-4c63-930f-7d4bb73453a2/be5d015f-f0e9-47ab-911e-5fecc8ca5414"
  http_version = "http2"
  is_ipv6_enabled = true
  aliases = [
    var.content-loader-domain
  ]

  default_cache_behavior {
    allowed_methods = [
      "HEAD",
      "GET",
      "OPTIONS"
    ]
    cached_methods = ["HEAD", "GET"] //TODO
    compress = true
    smooth_streaming  = false
    target_origin_id = aws_lb.cudl-content-elastic-load-balancer.dns_name
    viewer_protocol_policy = "redirect-to-https"
    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  comment = "cudl content loader"
  price_class = "PriceClass_100"
  enabled = true

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.cudl-certificate-us-east-1.arn
    cloudfront_default_certificate = false
    minimum_protocol_version = "TLSv1.2_2021"
    ssl_support_method = "sni-only"
  }
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  depends_on = [
    aws_acm_certificate.cudl-certificate-default,
    aws_lb.cudl-content-elastic-load-balancer
  ]
}