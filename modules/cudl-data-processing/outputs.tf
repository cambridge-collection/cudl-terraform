output "transform_lambda_length" {
  value = length(aws_lambda_function.create-transform-lambda-function)
}

output "transform_lambda_sqs_queue_length" {
  value = length(aws_sqs_queue.transform-lambda-sqs-queue)
}

output "source_item_updated_sns_topic_length" {
  value = length(aws_sns_topic.source_item_updated)
}

output "item_update_topic_subscriptions_length" {
  value = length(aws_sns_topic_subscription.item_update_subscriptions)
}

output "source_bucket_notification_topics_length" {
  value = length(flatten([for notification in aws_s3_bucket_notification.source-bucket-notifications : [for topic in notification.topic : topic.topic_arn]]))
}

output "source_bucket_notification_queues_length" {
  value = length(flatten([for notification in aws_s3_bucket_notification.source-bucket-notifications : [for queue in notification.queue : queue.queue_arn]]))
}
