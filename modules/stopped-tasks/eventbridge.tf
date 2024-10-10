resource "aws_cloudwatch_event_rule" "stopped_tasks" {
  name        = "${var.ecs_service_name}-stopped-tasks"
  description = "Capture stopped tasks for ${var.ecs_service_name}"

  event_pattern = jsonencode({
    source = [
      "aws.cloudwatch"
    ]
    detail-type = [
      "CloudWatch Alarm State Change"
    ]
    resources = [
      aws_cloudwatch_metric_alarm.stopped_tasks.arn
    ]
  })
}

resource "aws_cloudwatch_event_target" "stopped_tasks" {
  target_id = "${var.ecs_service_name}-stopped-tasks"
  rule      = aws_cloudwatch_event_rule.stopped_tasks.name
  arn       = aws_lambda_function.stopped_tasks.arn
}
