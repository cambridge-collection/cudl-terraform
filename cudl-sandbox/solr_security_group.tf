resource "aws_security_group" "solr" {
  name        = "${module.solr.name_prefix}-external"
  description = "Allows access to EFS mount targets for ${module.solr.name_prefix}"
  vpc_id      = module.base_architecture.vpc_id

  tags = {
    Name = "${module.solr.name_prefix}-external"
  }
}
