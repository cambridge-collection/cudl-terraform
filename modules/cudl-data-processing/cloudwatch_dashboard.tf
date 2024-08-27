resource "aws_cloudwatch_dashboard" "lambda" {
  dashboard_name = "${title(var.environment)}-Data-Processing-Lambda"

  dashboard_body = jsonencode({
    widgets = concat(
      [
        for lambda in var.transform-lambda-information :
        {
          type   = "metric"
          x      = index(var.transform-lambda-information, lambda) > (length(var.transform-lambda-information ) / 2) ? var.dashboard_widget_size : 0
          y      = index(var.transform-lambda-information, lambda) * var.dashboard_widget_size
          width  = var.dashboard_widget_size
          height = var.dashboard_widget_size

          properties = {
            metrics = [
               [ "AWS/Lambda", "ConcurrentExecutions", "FunctionName", join("-", [var.environment, lambda.name]), { region = "eu-west-1" } ]
            ],
            view    = "timeSeries"
            period  = 180
            stacked = false
            stat    = "Maximum"
            region  = var.deployment-aws-region
            title   = lambda.name
          }
        }
      ],
      [
        for lambda in var.transform-lambda-information :
        {
          type   = "metric"
          x      = index(var.transform-lambda-information, lambda) > (length(var.transform-lambda-information ) / 2) ? var.dashboard_widget_size * 3 : var.dashboard_widget_size * 2
          y      = index(var.transform-lambda-information, lambda) * var.dashboard_widget_size
          width  = var.dashboard_widget_size
          height = var.dashboard_widget_size

          properties = {
            metrics = [
               [ "AWS/Lambda", "Errors", "FunctionName", join("-", [var.environment, lambda.name]), { color = "#d62728", region = "eu-west-1" } ]
            ],
            view    = "timeSeries"
            period  = 60
            stacked = false
            stat    = "Sum"
            region  = var.deployment-aws-region
            title   = lambda.name
          }
        }
      ]
    )
  })
}

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
              ["AWS/SQS", "ApproximateNumberOfMessagesNotVisible", "QueueName", join("-", [var.environment, queue]), { label = "MessagesInFlight", region = var.deployment-aws-region }],
              [".", "NumberOfMessagesDeleted", ".", ".", { label = "MessagesProcessed", region = var.deployment-aws-region }]
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
