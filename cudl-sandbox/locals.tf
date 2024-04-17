locals {
  default_tags = {
    Environment  = title(var.environment)
    Project      = var.project
    Component    = var.component
    Subcomponent = var.subcomponent
    Deployment   = title(var.environment)
    Source       = "https://github.com/cambridge-collection/cudl-terraform"
    Owner        = var.owner
    terraform    = true
  }
  additional_lambda_variables = {
    AWS_DATA_SOURCE_BUCKET   = "${var.environment}-cudl-data-source"
    AWS_TRANSCRIPTION_BUCKET = "${var.environment}-cudl-transcriptions" # NOTE to be removed
    AWS_DIST_BUCKET          = "${var.environment}-cudl-dist"
  }
}
