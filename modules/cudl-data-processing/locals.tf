locals {
  source_sns_buckets = [
    for notification in var.source-bucket-sns-notifications : notification.bucket_name
  ]
  source_sns_subscriptions = flatten([
    for notification in var.source-bucket-sns-notifications : [
      for subscription in notification.subscriptions : merge(subscription, { bucket_name = notification.bucket_name })
    ]
  ])
}
