locals {
  source_buckets = toset(["cudl-data-sourcep", "cudl-distp"])
  source_buckets_and_queues = flatten([
    for topic in var.source-bucket-sns-notifications : [
      for notification in topic.subscriptions : {
        bucket_name = topic.bucket_name
        queue_name  = notification.queue_name
        raw         = notification.raw
      }
    ]
  ])
}
