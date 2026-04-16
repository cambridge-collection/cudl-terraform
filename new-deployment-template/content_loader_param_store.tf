data "aws_ssm_parameter" "content_loader_db_password" {
  name = "/Environments/${title(var.environment)}/CUDL/ContentLoader/DB/Password"
}
