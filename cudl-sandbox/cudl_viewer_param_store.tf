data "aws_ssm_parameter" "cudl_viewer_jdbc_user" {
  name = "/Environments/Sandbox/CUDL/Viewer/JDBC/User"
}

data "aws_ssm_parameter" "cudl_viewer_jdbc_password" {
  name = "/Environments/Sandbox/CUDL/Viewer/JDBC/Password"
}
