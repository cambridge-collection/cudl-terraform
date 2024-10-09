data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/stopped_tasks.py"
  output_path = "lambda_function_payload.zip"
}

resource "aws_lambda_function" "stopped_tasks" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename      = "lambda_function_payload.zip"
  function_name = local.lambda_function_name
  role          = aws_iam_role.stopped_tasks.arn
  handler       = "lambda_handler"

  source_code_hash = data.archive_file.lambda.output_base64sha256

  runtime = "python3.12"

  environment {
    variables = {
      ECS_CLUSTER_NAME = var.ecs_cluster_name
      ECS_SERVICE_NAME = var.ecs_service_name
    }
  }
}

resource "aws_lambda_permission" "trigger" {
  function_name = aws_lambda_function.stopped_tasks.function_name
  action        = "lambda:InvokeFunction"
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.stopped_tasks.arn
}
