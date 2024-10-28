data "aws_caller_identity" "current" {}

data "aws_ecr_image" "content_loader" {
  for_each        = toset(var.content_loader_ecr_repository_names)
  repository_name = each.key
  image_tag       = "latest"
}

data "aws_ecr_image" "solr" {
  for_each        = toset(var.solr_ecr_repository_names)
  repository_name = each.key
  image_tag       = "latest"
}

data "aws_ecr_image" "cudl_services" {
  for_each        = toset(var.cudl_services_ecr_repository_names)
  repository_name = each.key
  image_tag       = "ae4e"
}

data "aws_ecr_image" "cudl_viewer" {
  for_each        = toset(var.cudl_viewer_ecr_repository_names)
  repository_name = each.key
  image_tag       = "3cc1224"
}

data "aws_ssm_parameter" "cudl_viewer_cloudfront_username" {
  name = "/Environments/${title(var.environment)}/CUDL/Viewer/CloudFront/Username"
}

data "aws_ssm_parameter" "cudl_viewer_cloudfront_password" {
  name = "/Environments/${title(var.environment)}/CUDL/Viewer/CloudFront/Password"
}
