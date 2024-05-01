locals {
  source_sns_subscriptions = flatten([
    for notification in var.source-bucket-sns-notifications : [
      for subscription in notification.subscriptions : merge(subscription, { bucket_name = notification.bucket_name })
    ]
  ])
  source_bucket_sqs_notifications = {
    for bucket in toset(var.source-bucket-names) : bucket => [
      for notification in var.source-bucket-sqs-notifications : notification if notification.bucket_name == bucket
    ]
  }
  transform_lambda_queues = toset([for lambda in var.transform-lambda-information : lambda.queue_name])
}
