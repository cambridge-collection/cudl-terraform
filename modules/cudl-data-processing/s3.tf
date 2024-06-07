resource "aws_s3_bucket" "dest-bucket" {
  bucket = lower("${var.environment}-${var.destination-bucket-name}")
}

resource "aws_s3_bucket" "source-bucket" {
  bucket = lower("${var.environment}-${var.source-bucket-name}")
}

resource "aws_s3_bucket" "enhancements-bucket" {
  bucket = lower("${var.environment}-${var.enhancements-bucket-name}")
}

#
# resource "aws_s3_bucket_website_configuration" "example" {
#   bucket = aws_s3_bucket.transcriptions-bucket.id
#
#   index_document {
#     suffix = "index.html"
#   }
#
#   error_document {
#     key = "error.html"
#   }
# }

data "aws_iam_policy_document" "dest-bucket" {
  count = local.create_cloudfront_distribution ? 1 : 0

  statement {
    sid       = "AllowCloudFrontServicePrincipalReadOnly"
    actions   = ["s3:GetObject"]
    resources = [format("%s/*", aws_s3_bucket.dest-bucket.arn)]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.transcriptions.0.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "dest-bucket" {
  count = local.create_cloudfront_distribution ? 1 : 0

  bucket = aws_s3_bucket.dest-bucket.id
  policy = data.aws_iam_policy_document.dest-bucket.0.json
}

resource "aws_s3_bucket_versioning" "transform-lambda-source-bucket-versioning" {
  for_each = local.transform-lambda-bucket-names
  bucket   = local.transform-lambda-buckets[each.key].id

  versioning_configuration {
    status = "Suspended"
  }
}

# resource "aws_s3_bucket_versioning" "transcriptions-bucket-versioning" {
#   bucket = aws_s3_bucket.transcriptions-bucket.id
#   versioning_configuration {
#     status = "Suspended"
#   }
# }

resource "aws_s3_bucket_notification" "transform-lambda-bucket-notifications" {
  for_each = local.transform-lambda-bucket-names
  bucket   = local.transform-lambda-buckets[each.key].id

  # Add a topic if there is an SNS topic relating to the bucket (the keys of
  # local.source_bucket_s3_notifications)
  dynamic "topic" {
    for_each = contains(keys(local.transform_bucket_sns_notifications), each.key) ? [1] : []
    content {
      topic_arn     = aws_sns_topic.transform_sns_topics[each.key].arn
      events        = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
      filter_prefix = local.transform_bucket_sns_notifications[each.key].filter_prefix
      filter_suffix = local.transform_bucket_sns_notifications[each.key].filter_suffix
    }
  }

  dynamic "queue" {
    for_each = local.transform_bucket_sqs_notifications[each.key]
    content {
      queue_arn     = aws_sqs_queue.transform-lambda-sqs-queue[queue.value.queue_name].arn
      events        = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
      filter_prefix = try(queue.value.filter_prefix, null)
      filter_suffix = try(queue.value.filter_suffix, null)
    }
  }

  # without the `depends_on` argument, the bucket notification creation fails because the
  # lambda function doesn't exist yet
  depends_on = [aws_sqs_queue.transform-lambda-sqs-queue, aws_lambda_function.create-transform-lambda-function, aws_sns_topic.transform_sns_topics]
}
