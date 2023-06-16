resource "aws_sqs_queue" "enhancements-lambda-sqs-queue" {
  count = length(var.enhancements-lambda-information)

  name = "${var.environment}-${var.enhancements-lambda-information[count.index].queue_name}"

  visibility_timeout_seconds = 900
  sqs_managed_sse_enabled    = false

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Action": "sqs:SendMessage",
      "Resource": "arn:aws:sqs:*:*:${substr("${var.environment}-${var.enhancements-lambda-information[count.index].queue_name}", 0, 64)}",
      "Condition": {
        "ArnEquals": { "aws:SourceArn": "${aws_s3_bucket.transkribus-bucket.arn}" }
      }
    }
  ]
}
POLICY

  redrive_policy = jsonencode({
    "deadLetterTargetArn" = aws_sqs_queue.enhancements-lambda-dead-letter-queue[count.index].arn,
    "maxReceiveCount"     = 3
  })
}

resource "aws_sqs_queue" "enhancements-lambda-dead-letter-queue" {
  count = length(var.enhancements-lambda-information)

  visibility_timeout_seconds = 900
  sqs_managed_sse_enabled    = false
  name                       = "${var.environment}-${var.enhancements-lambda-information[count.index].queue_name}_DeadLetterQueue"
}