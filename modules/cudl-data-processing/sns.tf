resource "aws_sns_topic" "source_item_updated" {

  name = "${var.environment}-s3-source-item-event-notification-topic"

  policy = <<POLICY
{
    "Version":"2012-10-17",
    "Statement":[{
        "Effect": "Allow",
        "Principal": { "Service": "s3.amazonaws.com" },
        "Action": "SNS:Publish",
        "Resource": "arn:aws:sns:*:*:${var.environment}-s3-source-item-event-notification-topic",
        "Condition":{
            "ArnLike":{"aws:SourceArn":"${aws_s3_bucket.source-bucket.arn}"}
        }
    }]
}
POLICY
}

resource "aws_sns_topic_subscription" "item_update_subscriptions" {
  count  = length(var.source-bucket-sns-notifications[0].subscriptions)

  topic_arn = aws_sns_topic.source_item_updated.arn
  protocol  = "sqs"
  raw_message_delivery = var.source-bucket-sns-notifications[0].subscriptions[count.index].raw
  endpoint  = "arn:aws:sqs:${var.deployment-aws-region}:${var.aws-account-number}:${var.environment}-${var.source-bucket-sns-notifications[0].subscriptions[count.index].queue_name}"
}