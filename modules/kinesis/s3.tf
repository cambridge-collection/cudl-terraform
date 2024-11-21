resource "aws_s3_bucket" "this" {
  bucket        = "${var.s3_name_prefix}-logs"
  force_destroy = var.s3_bucket_force_destroy
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = var.s3_bucket_versioning_enabled ? "Enabled" : "Disabled"
  }
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.s3_policy.json
}

data "aws_iam_policy_document" "s3_policy" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com"]
    }

    actions = [
      "s3:PutObject",
    ]

    resources = [
      aws_s3_bucket.this.arn,
      format("%s/*", aws_s3_bucket.this.arn)
    ]
  }
}
