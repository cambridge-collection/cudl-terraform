resource "aws_cloudwatch_log_group" "stopped_tasks" {
  name = local.log_group_name
}

resource "aws_cloudwatch_metric_alarm" "stopped_tasks" {
  alarm_name          = "${var.ecs_service_name}-stopped-tasks"
  namespace           = "ECS/ContainerInsights"
  metric_name         = "RunningTaskCount"
  comparison_operator = "LessThanThreshold"
  threshold           = 1
  period              = 120
  evaluation_periods  = 2
  statistic           = "Minimum"
  alarm_description   = "Monitor running tasks for ${var.ecs_service_name}"
  alarm_actions       = [aws_lambda_function.stopped_tasks.arn]
  treat_missing_data  = "breaching" # NOTE this is needed as if the host is unreachable data will be missing

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }
}
