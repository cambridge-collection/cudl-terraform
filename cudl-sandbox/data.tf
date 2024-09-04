data "aws_caller_identity" "current" {}

data "aws_ecr_image" "solr" {
  for_each        = toset(var.solr_ecr_repository_names)
  repository_name = each.key
  image_tag       = "latest"
}

data "aws_ecr_image" "cudl_viewer" {
  for_each        = toset(var.cudl_viewer_ecr_repository_names)
  repository_name = each.key
  image_tag       = "bf08a89"
}
