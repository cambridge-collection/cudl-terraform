moved {
  from = aws_cloudfront_origin_access_control.transcriptions
  to   = aws_cloudfront_origin_access_control.this
}

moved {
  from = aws_cloudfront_distribution.transcriptions
  to   = aws_cloudfront_distribution.this
}

moved {
  from = aws_route53_record.transcriptions_cloudfront_alias
  to   = aws_route53_record.cloudfront_alias
}

moved {
  from = aws_wafv2_web_acl.transcriptions
  to   = aws_wafv2_web_acl.this
}
