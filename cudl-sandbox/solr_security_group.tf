resource "aws_security_group" "solr" {
  name        = "${module.solr.name_prefix}-external"
  description = "Allows access to EFS mount targets for ${module.solr.name_prefix}"
  vpc_id      = module.base_architecture.vpc_id

  tags = {
    Name = "${module.solr.name_prefix}-external"
  }
}

resource "aws_security_group_rule" "solr_external_egress_to_asg" {
  type                     = "egress"
  protocol                 = "tcp"
  description              = "Egress on port ${var.solr_target_group_port} for ${module.solr.name_prefix}"
  security_group_id        = aws_security_group.solr.id
  source_security_group_id = module.base_architecture.asg_security_group_id
  from_port                = var.solr_target_group_port
  to_port                  = var.solr_target_group_port
}
