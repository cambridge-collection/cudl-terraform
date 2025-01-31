locals {
  environment      = var.environment
  base_name_prefix = join("-", compact([local.environment, var.cluster_name_suffix]))
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
    AWS_DATA_ENHANCEMENTS_BUCKET = lower("${var.environment}-${var.enhancements-bucket-name}")
    AWS_DATA_SOURCE_BUCKET       = lower("${var.environment}-${var.source-bucket-name}")
    AWS_OUTPUT_BUCKET            = lower("${var.environment}-${var.destination-bucket-name}")
  }
  enhancements_lambda_variables = {
    AWS_CUDL_DATA_SOURCE_BUCKET = lower("${var.environment}-${var.source-bucket-name}")
    AWS_OUTPUT_BUCKET           = lower("${var.environment}-${var.source-bucket-name}")
  }
  smtp_port = tonumber(data.aws_ssm_parameter.cudl_viewer_smtp_port.value)
}
