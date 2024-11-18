data "aws_caller_identity" "current" {}

data "aws_ec2_instance_type" "asg" {
  instance_type = var.ec2_instance_type
}

data "aws_ecr_image" "solr" {
  for_each        = var.solr_ecr_repositories
  repository_name = each.key
  image_digest    = each.value
}

