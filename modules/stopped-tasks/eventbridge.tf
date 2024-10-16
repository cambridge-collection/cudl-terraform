resource "aws_cloudwatch_event_rule" "unhealthy_hosts" {
  name        = "${var.ecs_service_name}-unhealthy-hosts"
  description = "Capture unhealthy hosts for ${var.ecs_service_name}"

  event_pattern = jsonencode({
    source = [
      "aws.cloudwatch"
    ]
    detail-type = [
      "CloudWatch Alarm State Change"
    ]
    resources = [
      aws_cloudwatch_metric_alarm.unhealthy_hosts.arn
    ]
  })
}

resource "aws_cloudwatch_event_target" "unhealthy_hosts" {
  target_id = "${var.ecs_service_name}-unhealthy-hosts"
  rule      = aws_cloudwatch_event_rule.unhealthy_hosts.name
  arn       = aws_lambda_function.unhealthy_hosts.arn
}
