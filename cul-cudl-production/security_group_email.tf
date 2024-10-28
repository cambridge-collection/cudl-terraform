resource "aws_security_group" "email" {
  name        = "${local.base_name_prefix}-email"
  description = "Allows access to EFS mount targets for ${local.base_name_prefix}"
  vpc_id      = module.base_architecture.vpc_id

  tags = {
    Name = "${local.base_name_prefix}-email"
  }
}

resource "aws_security_group_rule" "email_egress_smtp" {
  type              = "egress"
  protocol          = "tcp"
  description       = "Egress on port ${local.smtp_port} for ${local.base_name_prefix}"
  security_group_id = aws_security_group.email.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = local.smtp_port
  to_port           = local.smtp_port
}
