resource "aws_cloudwatch_log_group" "stopped_tasks" {
  name = local.log_group_name
}

resource "aws_cloudwatch_metric_alarm" "unhealthy_hosts" {
  alarm_name          = "${var.ecs_service_name}-unhealthy-hosts"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HealthyHostCount"
  comparison_operator = "LessThanThreshold"
  threshold           = 1
  period              = 120
  evaluation_periods  = 2
  statistic           = "Minimum"
  alarm_description   = "Monitor unhealthy hosts for ${var.ecs_service_name}"
  alarm_actions       = [aws_lambda_function.unhealthy_hosts.arn]
  treat_missing_data  = "breaching" # NOTE this is needed as if the host is unreachable data will be missing

  dimensions = {
    LoadBalancer = data.aws_lb.this.arn_suffix
    TargetGroup  = data.aws_lb_target_group.this.arn_suffix
  }
}
