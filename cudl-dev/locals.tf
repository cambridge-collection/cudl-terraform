locals {
  environment = var.environment # NOTE use of local variable allows for owner-specific naming in sandbox environment
  default_tags = {
    Environment  = title(var.environment)
    Project      = var.project
    Component    = var.component
    Subcomponent = var.subcomponent
    Deployment   = title(local.environment)
    Source       = "https://github.com/cambridge-collection/cudl-terraform"
    terraform    = true
  }
  additional_lambda_variables = {
    AWS_DATA_ENHANCEMENTS_BUCKET = "${local.environment}-cudl-data-enhancements"
    AWS_DATA_SOURCE_BUCKET       = "${local.environment}-cudl-data-source"
    AWS_OUTPUT_BUCKET            = "${local.environment}-cudl-data-releases"
  }
  enhancements_lambda_variables = {
    AWS_CUDL_DATA_SOURCE_BUCKET = "${local.environment}-cudl-data-enhancements"
    AWS_OUTPUT_BUCKET           = "${local.environment}-cudl-data-source"
  }
}
