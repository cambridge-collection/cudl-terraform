resource "aws_cloudwatch_log_subscription_filter" "logging_destination" {
  name            = format("%s-logging-destination", local.base_name_prefix)
  log_group_name  = module.base_architecture.cloudwatch_log_group_name
  filter_pattern  = ""
  destination_arn = var.cloudwatch_log_destination_arn
  distribution    = "ByLogStream"
}
