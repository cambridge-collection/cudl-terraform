data "aws_iam_policy_document" "web_frontend" {

  statement {
    sid       = "AllowCloudFrontServicePrincipalReadOnly"
    actions   = ["s3:GetObject"]
    resources = [format("%s/*", module.cudl-data-processing.destination_bucket_arn)]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.web_frontend.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "web_frontend" {

  bucket = module.cudl-data-processing.destination_bucket
  policy = data.aws_iam_policy_document.web_frontend.json
}
