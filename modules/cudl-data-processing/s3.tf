resource "aws_s3_bucket" "source-bucket" {
  count  = var.db-only-processing ? 0 : 1
  bucket = lower("${var.environment}-${var.source-bucket-name}")
}

resource "aws_s3_bucket" "dest-bucket" {
  bucket = lower("${var.environment}-${var.destination-bucket-name}")
}

resource "aws_s3_bucket" "transcriptions-bucket" {
  bucket = lower("${var.environment}-${var.transcriptions-bucket-name}")
}

resource "aws_s3_bucket_website_configuration" "example" {
  bucket = aws_s3_bucket.transcriptions-bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_versioning" "source-bucket-versioning" {
  count  = var.db-only-processing ? 0 : 1
  bucket = aws_s3_bucket.source-bucket[0].id
  versioning_configuration {
    status = "Suspended"
  }
}
resource "aws_s3_bucket_versioning" "dest-bucket-versioning" {
  bucket = aws_s3_bucket.dest-bucket.id
  versioning_configuration {
    status = "Suspended"
  }
}

resource "aws_s3_bucket_versioning" "transcriptions-bucket-versioning" {
  bucket = aws_s3_bucket.transcriptions-bucket.id
  versioning_configuration {
    status = "Suspended"
  }
}

resource "aws_s3_bucket_notification" "source-bucket-notifications" {

  #count  = length(var.transform-lambda-information)
  count = length(var.source-bucket-sns-notifications) > 0 || length(var.source-bucket-sqs-notifications) > 0 ? 1 : 0

  bucket = aws_s3_bucket.source-bucket[0].id

  // TODO This is a hack for now, to get multiple notifications working for a bucket
  // If any more lambdas / sqs / sns is added an extra block will need adding.
  topic {
    topic_arn     = aws_sns_topic.source_item_updated[0].arn
    events        = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
    filter_prefix = try(var.source-bucket-sns-notifications[0].filter_prefix, "") != "" ? var.source-bucket-sns-notifications[0].filter_prefix : null
    filter_suffix = try(var.source-bucket-sns-notifications[0].filter_suffix, "") != "" ? var.source-bucket-sns-notifications[0].filter_suffix : null
  }

  queue {
    queue_arn     = "arn:aws:sqs:${var.deployment-aws-region}:${var.aws-account-number}:${var.environment}-${var.source-bucket-sqs-notifications[0].queue_name}"
    events        = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
    filter_prefix = try(var.source-bucket-sqs-notifications[0].filter_prefix, "") != "" ? var.source-bucket-sqs-notifications[0].filter_prefix : null
    filter_suffix = try(var.source-bucket-sqs-notifications[0].filter_suffix, "") != "" ? var.source-bucket-sqs-notifications[0].filter_suffix : null
  }

  queue {
    queue_arn     = "arn:aws:sqs:${var.deployment-aws-region}:${var.aws-account-number}:${var.environment}-${var.source-bucket-sqs-notifications[1].queue_name}"
    events        = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
    filter_prefix = try(var.source-bucket-sqs-notifications[1].filter_prefix, "") != "" ? var.source-bucket-sqs-notifications[1].filter_prefix : null
    filter_suffix = try(var.source-bucket-sqs-notifications[1].filter_suffix, "") != "" ? var.source-bucket-sqs-notifications[1].filter_suffix : null
  }

  queue {
    queue_arn     = "arn:aws:sqs:${var.deployment-aws-region}:${var.aws-account-number}:${var.environment}-${var.source-bucket-sqs-notifications[2].queue_name}"
    events        = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
    filter_prefix = try(var.source-bucket-sqs-notifications[2].filter_prefix, "") != "" ? var.source-bucket-sqs-notifications[2].filter_prefix : null
    filter_suffix = try(var.source-bucket-sqs-notifications[2].filter_suffix, "") != "" ? var.source-bucket-sqs-notifications[2].filter_suffix : null
  }

  queue {
    queue_arn     = "arn:aws:sqs:${var.deployment-aws-region}:${var.aws-account-number}:${var.environment}-${var.source-bucket-sqs-notifications[3].queue_name}"
    events        = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
    filter_prefix = try(var.source-bucket-sqs-notifications[3].filter_prefix, "") != "" ? var.source-bucket-sqs-notifications[3].filter_prefix : null
    filter_suffix = try(var.source-bucket-sqs-notifications[3].filter_suffix, "") != "" ? var.source-bucket-sqs-notifications[3].filter_suffix : null
  }

  queue {
    queue_arn     = "arn:aws:sqs:${var.deployment-aws-region}:${var.aws-account-number}:${var.environment}-${var.source-bucket-sqs-notifications[4].queue_name}"
    events        = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
    filter_prefix = try(var.source-bucket-sqs-notifications[4].filter_prefix, "") != "" ? var.source-bucket-sqs-notifications[4].filter_prefix : null
    filter_suffix = try(var.source-bucket-sqs-notifications[4].filter_suffix, "") != "" ? var.source-bucket-sqs-notifications[4].filter_suffix : null
  }

  queue {
    queue_arn     = "arn:aws:sqs:${var.deployment-aws-region}:${var.aws-account-number}:${var.environment}-${var.source-bucket-sqs-notifications[5].queue_name}"
    events        = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
    filter_prefix = try(var.source-bucket-sqs-notifications[5].filter_prefix, "") != "" ? var.source-bucket-sqs-notifications[5].filter_prefix : null
    filter_suffix = try(var.source-bucket-sqs-notifications[5].filter_suffix, "") != "" ? var.source-bucket-sqs-notifications[5].filter_suffix : null
  }
  # without the `depends_on` argument, the bucket notification creation fails because the
  # lambda function doesn't exist yet
  depends_on = [aws_sqs_queue.transform-lambda-sqs-queue, aws_lambda_function.create-transform-lambda-function, aws_sns_topic.source_item_updated]
}

/*locals {
  # Some of the buckets have multiple filters that should trigger notifications
  # So we sort out the filters and create them as additional notifications
  other_filter_map = distinct(flatten([
  for lambda in var.transform-lambda-information : [
  for filter in split("|", lambda.other_filters) : {
    queue_index   = index(var.transform-lambda-information, lambda)
    filter_suffix = filter
  }] if try(lambda.other_filters, "") != ""
  ]))

 # other-cidr-blocks = length(var.cidr-blocks) > 1 ? toset(slice(var.cidr-blocks, 1, length(var.cidr-blocks))) : toset([])
}*/

/*resource "aws_s3_bucket_notification" "additional-source-bucket-notifications" {
  for_each = {
  for filter in local.other_filter_map : filter.filter_suffix => filter.queue_index
  }

  bucket = aws_s3_bucket.source-bucket.id

  queue {
    queue_arn     = aws_sqs_queue.transform-lambda-sqs-queue[each.value].arn
    events        = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
    filter_suffix = each.key
  }

  # without the `depends_on` argument, the bucket notification creation fails because the
  # lambda function doesn't exist yet
  depends_on = [aws_lambda_function.create-transform-lambda-function, aws_sqs_queue.transform-lambda-sqs-queue]
}*/

// TODO also temp. hack to get multiple triggers working on a single bucket.
resource "aws_s3_bucket_notification" "dest-bucket-notifications" {
  #count  = length(var.db-lambda-information)
  bucket = aws_s3_bucket.dest-bucket.id

  queue {
    queue_arn     = aws_sqs_queue.db-lambda-sqs-queue[0].arn
    events        = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
    filter_prefix = try(var.db-lambda-information[0].filter_prefix, "") != "" ? var.db-lambda-information[0].filter_prefix : null
    filter_suffix = try(var.db-lambda-information[0].filter_suffix, "") != "" ? var.db-lambda-information[0].filter_suffix : null
  }

  queue {
    queue_arn     = aws_sqs_queue.db-lambda-sqs-queue[1].arn
    events        = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
    filter_prefix = try(var.db-lambda-information[1].filter_prefix, "") != "" ? var.db-lambda-information[1].filter_prefix : null
    filter_suffix = try(var.db-lambda-information[1].filter_suffix, "") != "" ? var.db-lambda-information[1].filter_suffix : null
  }

  queue {
    queue_arn     = aws_sqs_queue.db-lambda-sqs-queue[2].arn
    events        = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
    filter_prefix = try(var.db-lambda-information[2].filter_prefix, "") != "" ? var.db-lambda-information[2].filter_prefix : null
    filter_suffix = try(var.db-lambda-information[2].filter_suffix, "") != "" ? var.db-lambda-information[2].filter_suffix : null
  }
  # without the `depends_on` argument, the bucket notification creation fails because the
  # lambda function doesn't exist yet
  depends_on = [aws_lambda_function.create-db-lambda-function]
}
