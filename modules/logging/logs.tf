resource "aws_cloudwatch_log_group" "lambda" {
  name = format("/aws/lambda/%s-logs", var.name_prefix)
}

# resource "aws_cloudwatch_log_subscription_filter" "this" {
#   name            = "${var.name_prefix}-logs"
#   log_group_name  = data.aws_cloudwatch_log_group.logs.name
#   filter_pattern  = var.cloudwatch_log_subscription_filter_pattern
#   destination_arn = aws_lambda_function.this.arn
#   distribution    = "ByLogStream"
# }
