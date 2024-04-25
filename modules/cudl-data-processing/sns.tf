resource "aws_sns_topic" "source_item_updated" {

  # count = var.db-only-processing ? 0 : length(var.source-bucket-sns-notifications)
  for_each = var.db-only-processing ? toset([]) : local.source_buckets
  name  = "${var.environment}-${each.key}-event-notification-topic"

  policy = <<POLICY
{
    "Version":"2012-10-17",
    "Statement":[{
        "Effect": "Allow",
        "Principal": { "Service": "s3.amazonaws.com" },
        "Action": "SNS:Publish",
        "Resource": "arn:aws:sns:*:*:${var.environment}-${each.key}-event-notification-topic",
        "Condition": {
            "ArnLike": {
                "aws:SourceArn": "${aws_s3_bucket.transform-lambda-source-bucket[each.key].arn}"
            }
        }
    }]
}
POLICY
}

resource "aws_sns_topic_subscription" "item_update_subscriptions" {
  #count = length(var.source-bucket-sns-notifications) > 0 ? length(var.source-bucket-sns-notifications[0].subscriptions) : 0
  count = length(local.source_buckets_and_queues)

  topic_arn            = aws_sns_topic.source_item_updated[local.source_buckets_and_queues[count.index].bucket_name].arn
  protocol             = "sqs"
  raw_message_delivery = local.source_buckets_and_queues[count.index].raw
  endpoint             = "arn:aws:sqs:${var.deployment-aws-region}:${var.aws-account-number}:${var.environment}-${local.source_buckets_and_queues[count.index].queue_name}"
}