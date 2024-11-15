data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/log_batcher.py"
  output_path = format("%s.zip", var.name_prefix)
}

resource "aws_lambda_function" "this" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename      = format("%s.zip", var.name_prefix)
  function_name = "${var.name_prefix}-logs"
  role          = aws_iam_role.lambda.arn
  handler       = "log_batcher.lambda_handler"

  source_code_hash = data.archive_file.lambda.output_base64sha256

  runtime = "python3.12"

  environment {
    variables = {
      S3_BUCKET = aws_s3_bucket.this.id
    }
  }
}

resource "aws_lambda_permission" "trigger" {
  function_name       = aws_lambda_function.this.function_name
  action              = "lambda:InvokeFunction"
  principal           = "logs.amazonaws.com"
  source_account      = data.aws_caller_identity.current.account_id
  statement_id_prefix = format("%s-", var.name_prefix)
}
