resource "aws_s3_bucket" "source-bucket" {
  bucket = lower("${var.environment}-${var.source-bucket-name}")
}

resource "aws_s3_bucket" "dest-bucket" {
  bucket = lower("${var.environment}-${var.destination-bucket-name}")
}

resource "aws_s3_bucket" "transcriptions-bucket" {
  bucket = lower("${var.environment}-${var.transcriptions-bucket-name}")
}

resource "aws_s3_bucket_notification" "source-bucket-notifications" {

  count  = length(var.transform-lambda-information)
  bucket = aws_s3_bucket.source-bucket.id

  queue {
    queue_arn     = aws_sqs_queue.transform-lambda-sqs-queue[count.index].arn
    events        = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
    filter_prefix = try(var.transform-lambda-information[count.index].filter_prefix, "") != "" ? var.transform-lambda-information[count.index].filter_prefix : null
    filter_suffix = try(var.transform-lambda-information[count.index].filter_suffix, "") != "" ? var.transform-lambda-information[count.index].filter_suffix : null
  }

  # without the `depends_on` argument, the bucket notification creation fails because the
  # lambda function doesn't exist yet
  depends_on = [aws_lambda_function.create-transform-lambda-function]
}

locals {
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
}

resource "aws_s3_bucket_notification" "additional-source-bucket-notifications" {
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
}

resource "aws_s3_bucket_notification" "dest-bucket-notifications" {
  count  = length(var.db-lambda-information)
  bucket = aws_s3_bucket.dest-bucket.id

  queue {
    queue_arn     = aws_sqs_queue.db-lambda-sqs-queue[count.index].arn
    events        = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
    filter_prefix = try(var.db-lambda-information[count.index].filter_prefix, "") != "" ? var.db-lambda-information[count.index].filter_prefix : null
    filter_suffix = try(var.db-lambda-information[count.index].filter_suffix, "") != "" ? var.db-lambda-information[count.index].filter_suffix : null
  }

  # without the `depends_on` argument, the bucket notification creation fails because the
  # lambda function doesn't exist yet
  depends_on = [aws_lambda_function.create-db-lambda-function]
}