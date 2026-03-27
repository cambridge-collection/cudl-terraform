locals {
  environment      = strcontains(lower(var.environment), "sandbox") ? join("-", [var.owner, var.environment]) : var.environment
  base_name_prefix = join("-", compact([local.environment, var.cluster_name_suffix]))
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
    AWS_DATA_ENHANCEMENTS_BUCKET = lower("${local.environment}-${var.enhancements-bucket-name}")
    AWS_DATA_SOURCE_BUCKET       = lower("${local.environment}-${var.source-bucket-name}")
    AWS_OUTPUT_BUCKET            = lower("${local.environment}-${var.destination-bucket-name}")
  }
  enhancements_lambda_variables = {
    AWS_CUDL_DATA_SOURCE_BUCKET = lower("${local.environment}-${var.source-bucket-name}")
    AWS_OUTPUT_BUCKET           = lower("${local.environment}-${var.source-bucket-name}")
  }
  pid_pipeline_secret_name = "${local.environment}/cudl/pid-pipeline"
  pid_pipeline_secret_values = {
    PID_MINTER_AUTH_TOKEN = var.pid_minter_auth_token
    PID_MINTER_URL        = var.pid_minter_url
  }
  pid_pipeline_environment_variables = merge(
    local.pid_pipeline_secret_values,
    {
      PID_FORWARD_QUEUE_URL = format(
        "https://sqs.%s.amazonaws.com/%s/%s",
        var.deployment-aws-region,
        data.aws_caller_identity.current.account_id,
        substr("${local.environment}-CUDL_TEIProcessingForwardQueue", 0, 64)
      )
    }
  )
  transform_lambda_information_effective = [
    for lambda in var.transform-lambda-information : lambda.name == "AWSLambda_CUDL_ARK_Ingestion" ? merge(
      lambda,
      {
        environment_variables = merge(
          try(lambda.environment_variables, {}),
          local.pid_pipeline_environment_variables
        )
      }
    ) : lambda
  ]
}
