resource "aws_cloudwatch_dashboard" "sqs" {
  dashboard_name = "${title(var.environment)}-Data-Processing-SQS"

  dashboard_body = jsonencode({
    widgets = concat(
      [
        for queue in local.transform_lambda_queues :
        {
          type   = "metric"
          x      = index(tolist(local.transform_lambda_queues), queue) > (length(local.transform_lambda_queues) / 2) ? var.dashboard_widget_size : 0
          y      = index(tolist(local.transform_lambda_queues), queue) * var.dashboard_widget_size
          width  = var.dashboard_widget_size
          height = var.dashboard_widget_size

          properties = {
            metrics = [
              ["AWS/SQS", "ApproximateNumberOfMessagesNotVisible", "QueueName", join("-", [var.environment, queue]), { "label" : "MessagesInFlight", "region" : var.deployment-aws-region }],
              [".", "ApproximateNumberOfMessagesVisible", ".", ".", { "label" : "MessagesToBeProcessed", "region" : var.deployment-aws-region }],
              [".", "NumberOfMessagesDeleted", ".", ".", { "label" : "MessagesProcessed", "region" : var.deployment-aws-region }]
            ],
            view    = "timeSeries"
            period  = 60
            stacked = false
            stat    = "Sum"
            region  = var.deployment-aws-region
            title   = queue
          }
        }
      ],
      [
        for queue in local.transform_lambda_queues :
        {
          type   = "metric"
          x      = index(tolist(local.transform_lambda_queues), queue) > (length(local.transform_lambda_queues) / 2) ? var.dashboard_widget_size * 3 : var.dashboard_widget_size * 2
          y      = index(tolist(local.transform_lambda_queues), queue) * var.dashboard_widget_size
          width  = var.dashboard_widget_size
          height = var.dashboard_widget_size

          properties = {
            metrics = [
              ["AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", "${join("-", [var.environment, queue])}_DeadLetterQueue", { "label" : "MessagesToBeProcessed", "region" : var.deployment-aws-region }]
            ],
            view    = "timeSeries"
            period  = 60
            stacked = false
            stat    = "Sum"
            region  = var.deployment-aws-region
            title   = "${queue}_DeadLetterQueue"
          }
        }
      ]
    )
  })
}
