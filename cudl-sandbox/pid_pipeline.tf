data "aws_secretsmanager_secret" "pid_pipeline" {
  name = local.pid_pipeline_secret_name
}
