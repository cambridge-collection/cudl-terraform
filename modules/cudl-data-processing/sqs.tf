resource "aws_sqs_queue" "transform-lambda-sqs-queue" {
  for_each = local.transform_lambda_queues

  name = substr("${var.environment}-${each.key}", 0, 64)

  visibility_timeout_seconds = 900
  delay_seconds              = each.value.queue_delay_seconds

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = "arn:aws:sqs:*:*:${substr("${var.environment}-${each.key}", 0, 64)}"
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = [for bucket in values(local.transform-lambda-buckets) : bucket.arn]
          }
        }
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action = [
          "sqs:SendMessage",
          "sqs:SendMessageBatch"
        ]
        Resource = "arn:aws:sqs:*:*:${substr("${var.environment}-${each.key}", 0, 64)}"
      }
    ]
  })
  redrive_policy = jsonencode({
    "deadLetterTargetArn" = aws_sqs_queue.transform-lambda-dead-letter-queue[each.key].arn,
    "maxReceiveCount"     = each.value.sqs_max_tries_before_deadqueue
  })
}

resource "aws_sqs_queue" "transform-lambda-dead-letter-queue" {
  for_each                   = local.transform_lambda_queues
  visibility_timeout_seconds = 900
  name                       = substr("${var.environment}-${each.key}_DeadLetterQueue", 0, 80)
}

