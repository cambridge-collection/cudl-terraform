resource "aws_cloudwatch_event_rule" "daily_summary" {
  name                = local.event_rule_name
  description         = "Scheduled trigger for daily summary fetch"
  schedule_expression = var.schedule_expression
}

resource "aws_cloudwatch_event_target" "daily_summary" {
  rule      = aws_cloudwatch_event_rule.daily_summary.name
  target_id = "${local.lambda_function_name}-target"
  arn       = aws_lambda_function.daily_summary.arn
}

