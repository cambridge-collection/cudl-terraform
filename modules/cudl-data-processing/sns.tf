resource "aws_sns_topic" "source_item_updated" {
  for_each = toset(var.source-bucket-names)

  name   = "${var.environment}-${each.key}-event-notification-topic"
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

# NOTE need a separate local variable for the loop here as Terraform can't do resources with nested for_each blocks
resource "aws_sns_topic_subscription" "item_update_subscriptions" {
  count = length(local.source_sns_subscriptions)

  topic_arn            = aws_sns_topic.source_item_updated[local.source_sns_subscriptions[count.index].bucket_name].arn
  protocol             = "sqs"
  raw_message_delivery = local.source_sns_subscriptions[count.index].raw
  endpoint             = aws_sqs_queue.transform-lambda-sqs-queue[local.source_sns_subscriptions[count.index].queue_name].arn
}