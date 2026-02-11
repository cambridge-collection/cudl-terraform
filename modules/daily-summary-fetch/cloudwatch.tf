resource "aws_cloudwatch_log_group" "lambda" {
  name = local.log_group_name
}

