data "aws_caller_identity" "current" {}

data "aws_ecr_image" "solr" {
  for_each        = var.solr_ecr_repositories
  repository_name = each.key
  image_digest    = each.value
}

data "aws_ecr_image" "cudl_services" {
  for_each        = var.cudl_services_ecr_repositories
  repository_name = each.key
  image_digest    = each.value
}

data "aws_ecr_image" "cudl_viewer" {
  for_each        = var.cudl_viewer_ecr_repositories
  repository_name = each.key
  image_digest    = each.value
}

data "aws_ssm_parameter" "cudl_viewer_smtp_username" {
  name = "/Environments/${title(var.environment)}/CUDL/Viewer/SMTP/Username"
}

data "aws_ssm_parameter" "cudl_viewer_smtp_password" {
  name = "/Environments/${title(var.environment)}/CUDL/Viewer/SMTP/Password"
}