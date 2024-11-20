data "aws_ssm_parameter" "database_password" {
  name = "/Environments/${title(local.environment)}/CUDL/Services/DB/Password"
}

data "aws_ssm_parameter" "apikey_darwin" {
  name = "/Environments/${title(local.environment)}/CUDL/Services/APIKey/Darwin"
}