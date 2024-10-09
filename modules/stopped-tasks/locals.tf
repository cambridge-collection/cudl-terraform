locals {
  lambda_function_name = format("%s-stopped-tasks", var.ecs_service_name)
  log_group_name       = format("/aws/lambda/%s", local.lambda_function_name)
}
