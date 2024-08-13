output "transform_lambda_length" {
  value = length(aws_lambda_function.create-transform-lambda-function)
}

output "transform_lambda_sqs_queue_length" {
  value = length(aws_sqs_queue.transform-lambda-sqs-queue)
}

output "transform_sns_topic_length" {
  value = length(aws_sns_topic.transform_sns_topics)
}

output "transform_sns_topic_subscriptions_length" {
  value = length(aws_sns_topic_subscription.transform_sns_event_subscriptions)
}

output "transform_bucket_notification_topics_length" {
  value = length(flatten([for notification in aws_s3_bucket_notification.transform-lambda-bucket-notifications : [for topic in notification.topic : topic.topic_arn]]))
}

output "transform_bucket_notification_queues_length" {
  value = length(flatten([for notification in aws_s3_bucket_notification.transform-lambda-bucket-notifications : [for queue in notification.queue : queue.queue_arn]]))
}

output "source_bucket" {
  value = aws_s3_bucket.source-bucket.id
}

output "destination_bucket" {
  value = aws_s3_bucket.dest-bucket.id
}

output "efs_file_system_id" {
  value = aws_efs_file_system.efs-volume.id
}
