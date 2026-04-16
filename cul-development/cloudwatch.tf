# Disabled for development — the central logging account (874581676011) destination policy
# does not grant the dev account permission to put subscription filters.
# To enable, ask the logging account owner to add 206247777824 to the destination policy.
# resource "aws_cloudwatch_log_subscription_filter" "logging_destination" {
#   name            = format("%s-logging-destination", local.base_name_prefix)
#   log_group_name  = module.base_architecture.cloudwatch_log_group_name
#   filter_pattern  = ""
#   destination_arn = var.cloudwatch_log_destination_arn
#   distribution    = "ByLogStream"
# }
