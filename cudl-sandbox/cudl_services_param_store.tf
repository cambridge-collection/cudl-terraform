data "aws_ssm_parameter" "database_password" {
  name = "/Environments/Sandbox/CUDL/Services/DB/Password"
}

data "aws_ssm_parameter" "apikey_darwin" {
  name = "/Environments/Sandbox/CUDL/Services/APIKey/Darwin"
}

data "aws_ssm_parameter" "basicauth_credentials" {
  name = "/Environments/Sandbox/CUDL/Services/BasicAuth/Credentials"
}
