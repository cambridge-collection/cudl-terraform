data "aws_subnet" "cudl_subnet" {
  id = var.subnet-id
}

data "aws_security_group" "default" {
  id = var.security-group-id
}