output "source_log_group_arn" {
  value = aws_cloudwatch_log_group.source.arn
}

output "source_log_group_name" {
  value = aws_cloudwatch_log_group.source.name
}
