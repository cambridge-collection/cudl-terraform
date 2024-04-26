locals {
  environment = strcontains(lower(var.environment), "sandbox") ? join("-", [var.owner, var.environment]) : var.environment
  default_tags = {
    Environment  = title(var.environment)
    Project      = var.project
    Component    = var.component
    Subcomponent = var.subcomponent
    Deployment   = title(local.environment)
    Source       = "https://github.com/cambridge-collection/cudl-terraform"
    Owner        = var.owner
    terraform    = true
  }
  additional_lambda_variables = {
    AWS_DATA_SOURCE_BUCKET   = "${local.environment}-cudl-data-source"
    AWS_TRANSCRIPTION_BUCKET = "${local.environment}-cudl-transcriptions" # NOTE to be removed
    AWS_DIST_BUCKET          = "${local.environment}-cudl-dist"
  }
}
