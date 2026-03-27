resource "aws_secretsmanager_secret" "pid_pipeline" {
  name = local.pid_pipeline_secret_name
}

resource "aws_secretsmanager_secret_version" "pid_pipeline" {
  secret_id     = aws_secretsmanager_secret.pid_pipeline.id
  secret_string = jsonencode(local.pid_pipeline_secret_values)
}
