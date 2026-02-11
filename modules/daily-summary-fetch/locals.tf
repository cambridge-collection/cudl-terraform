locals {
  lambda_function_name = "${var.name_prefix}-daily-summary-fetch"
  log_group_name       = "/aws/lambda/${local.lambda_function_name}"
  event_rule_name      = "${var.name_prefix}-daily-summary-schedule"
}

