data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/summary_fetch.py"
  output_path = "${path.module}/daily_summary_lambda_payload.zip"
}

resource "aws_lambda_function" "daily_summary" {
  filename      = data.archive_file.lambda.output_path
  function_name = local.lambda_function_name
  role          = aws_iam_role.lambda.arn
  handler       = "summary_fetch.lambda_handler"

  source_code_hash = data.archive_file.lambda.output_base64sha256

  runtime = "python3.12"
  timeout = 10

  environment {
    variables = {
      TARGET_URL = var.target_url
      S3_BUCKET  = var.results_bucket_name
      S3_PREFIX  = var.results_key_prefix
    }
  }
}

resource "aws_lambda_permission" "event_invoke" {
  function_name = aws_lambda_function.daily_summary.function_name
  action        = "lambda:InvokeFunction"
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_summary.arn
}
