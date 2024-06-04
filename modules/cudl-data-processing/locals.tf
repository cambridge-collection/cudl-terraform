locals {

  transform-lambda-bucket-names = toset([var.source-bucket-name, var.destination-bucket-name])

  transform_sns_subscriptions = flatten([
    for notification in var.transform-lambda-bucket-sns-notifications : [
      for subscription in notification.subscriptions : merge(subscription, { bucket_name = notification.bucket_name })
    ]
  ])
  transform_bucket_sns_notifications = {
    for notification in var.transform-lambda-bucket-sns-notifications : notification.bucket_name => {
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
  transform_lambda_queues = toset([for lambda in var.transform-lambda-information : lambda.queue_name])

  transform-lambda-buckets = {
    for bucket in toset([aws_s3_bucket.source-bucket, aws_s3_bucket.dest-bucket]) :
      replace(bucket.id, lower("${var.environment}-"), "") => bucket
  }

}
