data "aws_caller_identity" "current" {}

data "aws_ec2_instance_type" "asg" {
  instance_type = var.ec2_instance_type
}

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

data "aws_ssm_parameter" "cudl_services_apikey" {
  name = "/Environments/${title(var.environment)}/CUDL/Services/APIKey/Viewer"
}

data "aws_ssm_parameter" "cudl_viewer_smtp_username" {
  name = "/Environments/${title(var.environment)}/CUDL/Viewer/SMTP/Username"
}

data "aws_ssm_parameter" "cudl_viewer_smtp_password" {
  name = "/Environments/${title(var.environment)}/CUDL/Viewer/SMTP/Password"
}

data "aws_ssm_parameter" "cudl_viewer_smtp_port" {
  name = "/Environments/${title(var.environment)}/CUDL/Viewer/SMTP/Port"
}

data "aws_ssm_parameter" "cudl_viewer_cloudfront_username" {
  name = "/Environments/${title(var.environment)}/CUDL/Viewer/CloudFront/Username"
}

data "aws_ssm_parameter" "cudl_viewer_cloudfront_password" {
  name = "/Environments/${title(var.environment)}/CUDL/Viewer/CloudFront/Password"
}

data "aws_ssm_parameter" "cudl_viewer_recaptcha_sitekey" {
  name = "/Environments/${title(var.environment)}/CUDL/Viewer/Recaptcha/Sitekey"
}

data "aws_ssm_parameter" "cudl_viewer_recaptcha_secretkey" {
  name = "/Environments/${title(var.environment)}/CUDL/Viewer/Recaptcha/Secretkey"
}

data "aws_ssm_parameter" "cudl_viewer_google_analytics_id" {
  name = "/Environments/${title(var.environment)}/CUDL/Viewer/Google/AnalyticsId"
}

data "aws_ssm_parameter" "cudl_viewer_ga4_google_analytics_id" {
  name = "/Environments/${title(var.environment)}/CUDL/Viewer/Google/GA4AnalyticsId"
}
