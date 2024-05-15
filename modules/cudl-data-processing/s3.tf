resource "aws_s3_bucket" "dest-bucket" {
  bucket = lower("${var.environment}-${var.destination-bucket-name}")
}

resource "aws_s3_bucket" "transcriptions-bucket" {
  bucket = lower("${var.environment}-${var.transcriptions-bucket-name}")
}

resource "aws_s3_bucket" "transform-lambda-source-bucket" {
  for_each = toset(var.source-bucket-names)
  bucket   = lower("${var.environment}-${each.key}")
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

resource "aws_s3_bucket_versioning" "transform-lambda-source-bucket-versioning" {
  for_each = aws_s3_bucket.transform-lambda-source-bucket
  bucket   = aws_s3_bucket.transform-lambda-source-bucket[each.key].id
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
  for_each = toset(var.source-bucket-names)

  bucket = aws_s3_bucket.transform-lambda-source-bucket[each.key].id

  # Add a topic if there is an SNS topic relating to the bucket (the keys of
  # local.source_bucket_s3_notifications)
  dynamic "topic" {
    for_each = contains(keys(local.source_bucket_sns_notifications), each.key) ? [1] : []
    content {
      topic_arn     = aws_sns_topic.source_item_updated[each.key].arn
      events        = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
      filter_prefix = local.source_bucket_sns_notifications[each.key].filter_prefix
      filter_suffix = local.source_bucket_sns_notifications[each.key].filter_suffix
    }
  }

  dynamic "queue" {
    for_each = local.source_bucket_sqs_notifications[each.key]
    content {
      queue_arn     = aws_sqs_queue.transform-lambda-sqs-queue[queue.value.queue_name].arn
      events        = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
      filter_prefix = try(queue.value.filter_prefix, null)
      filter_suffix = try(queue.value.filter_suffix, null)
    }
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
