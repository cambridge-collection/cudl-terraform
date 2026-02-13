locals {
  destination_bucket_name = trimsuffix(substr(lower("${var.environment}-${var.destination-bucket-name}"), 0, 63), "-")
  enhacements_bucket_name = trimsuffix(substr(lower("${var.environment}-${var.enhancements-bucket-name}"), 0, 63), "-")
  source_bucket_name      = trimsuffix(substr(lower("${var.environment}-${var.source-bucket-name}"), 0, 63), "-")
  transform-lambda-bucket-names = toset([for bucket in [
    local.destination_bucket_name,
    local.enhacements_bucket_name,
    local.source_bucket_name
  ] : replace(bucket, lower(format("%s-", var.environment)), "")])

  transform_sns_subscriptions = flatten([
    for index, notification in var.transform-lambda-bucket-sns-notifications : [
      for subscription in notification.subscriptions : merge(subscription, {
        bucket_name = notification.bucket_name,
        topic_name = replace(lower(join("-", compact([notification.bucket_name,
        notification.filter_prefix, notification.filter_suffix]))), "/[^0-9a-z_-]/", "")
      })
    ]
  ])
  /*
  We're going to use a formatted name specific to the bucket and prefix, suffix used as a topic name.
  There will be multiple topics per bucket, with different prefix / suffixes so this should describe them well.
  There is unlikely possibility of this being a duplicate in the future, but I think it will do as a reference for now.
   */
  transform_bucket_sns_notifications = {
    for index, notification in var.transform-lambda-bucket-sns-notifications : replace(lower(join("-",
      compact([notification.bucket_name, notification.filter_prefix, notification.filter_suffix]))),
      "/[^0-9a-z_-]/", "") => {
      bucket_name   = notification.bucket_name
      filter_prefix = notification.filter_prefix
      filter_suffix = notification.filter_suffix
      queue_names   = [for subscription in notification.subscriptions : subscription.queue_name]
    } if contains(local.transform-lambda-bucket-names, notification.bucket_name)
  }
  transform_bucket_sqs_notifications = {
    for bucket in local.transform-lambda-bucket-names : bucket => [
      for notification in var.transform-lambda-bucket-sqs-notifications : notification if notification.bucket_name == bucket
    ]
  }
  transform_lambda_queues = { for lambda in var.transform-lambda-information : lambda.queue_name => {
    queue_delay_seconds            = lambda.queue_delay_seconds
    sqs_max_tries_before_deadqueue = lambda.sqs_max_tries_before_deadqueue
  } }

  transform-lambda-buckets = {
    for bucket in toset([aws_s3_bucket.source-bucket, aws_s3_bucket.dest-bucket, aws_s3_bucket.enhancements-bucket]) :
    replace(bucket.id, lower("${var.environment}-"), "") => bucket
  }

  cloudfront_distribution_domain_name = var.create_cloudfront_distribution ? var.production_deployment ? join(".", [var.cloudfront_distribution_name, data.aws_route53_zone.domain.0.name]) : join(".", [join("-", [var.environment, var.cloudfront_distribution_name]), data.aws_route53_zone.domain.0.name]) : ""
  cloudfront_access_logging_bucket_provided = try(trim(var.cloudfront_access_logging_bucket), "") != ""
  cloudfront_access_logging_bucket_create   = var.create_cloudfront_distribution && var.cloudfront_access_logging && !local.cloudfront_access_logging_bucket_provided
  cloudfront_access_logging_bucket_name = trimsuffix(substr(lower(
    coalesce(var.cloudfront_access_logging_bucket_name, "${var.environment}-${var.cloudfront_distribution_name}-cloudfront-access-logs")
  ), 0, 63), "-")
  cloudfront_access_logging_bucket_domain_name = local.cloudfront_access_logging_bucket_create ? aws_s3_bucket.cloudfront_access_logging[0].bucket_domain_name : var.cloudfront_access_logging_bucket
}
