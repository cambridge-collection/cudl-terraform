resource "aws_sqs_queue" "transform-lambda-sqs-queue" {
  count = length(var.transform-lambda-information)

  name = substr("${var.environment}-${var.transform-lambda-information[count.index].queue_name}", 0, 64)

  visibility_timeout_seconds = 900

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
      "Resource": "arn:aws:sqs:*:*:${substr("${var.environment}-${var.transform-lambda-information[count.index].queue_name}", 0, 64)}",
      "Condition": {
        "ArnEquals": { "aws:SourceArn": "${aws_s3_bucket.source-bucket.arn}" }
      }
    },
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "sns.amazonaws.com"
      },
      "Action": [
        "sqs:SendMessage",
        "sqs:SendMessageBatch"
      ],
      "Resource": "arn:aws:sqs:*:*:${substr("${var.environment}-${var.transform-lambda-information[count.index].queue_name}", 0, 64)}"
    }
  ]
}
POLICY

  redrive_policy = jsonencode({
    "deadLetterTargetArn" = aws_sqs_queue.transform-lambda-dead-letter-queue[count.index].arn,
    "maxReceiveCount"     = 3
  })
}

resource "aws_sqs_queue" "db-lambda-sqs-queue" {
  count = length(var.db-lambda-information)

  name = substr("${var.environment}-${var.db-lambda-information[count.index].queue_name}", 0, 64)

  visibility_timeout_seconds = 900

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
      "Resource": "arn:aws:sqs:*:*:${substr("${var.environment}-${var.db-lambda-information[count.index].queue_name}", 0, 64)}",
      "Condition": {
        "ArnEquals": { "aws:SourceArn": "${aws_s3_bucket.dest-bucket.arn}" }
      }
    }
  ]
}
POLICY

  redrive_policy = jsonencode({
    "deadLetterTargetArn" = aws_sqs_queue.db-lambda-dead-letter-queue[count.index].arn,
    "maxReceiveCount"     = 3
  })
}



resource "aws_sqs_queue" "transform-lambda-dead-letter-queue" {
  count = length(var.transform-lambda-information)

  name = substr("${var.environment}-${var.transform-lambda-information[count.index].queue_name}_DeadLetterQueue", 0, 80)
}

resource "aws_sqs_queue" "db-lambda-dead-letter-queue" {
  count = length(var.db-lambda-information)

  name = substr("${var.environment}-${var.db-lambda-information[count.index].queue_name}_DeadLetterQueue", 0, 80)
}