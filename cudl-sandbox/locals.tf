locals {
  environment                       = strcontains(lower(var.environment), "sandbox") ? join("-", [var.owner, var.environment]) : var.environment
  base_name_prefix                  = join("-", compact([local.environment, var.cluster_name_suffix]))
  tei_processing_forward_queue_name = "CUDL_TEIProcessingForwardQueue"
  tei_processing_notification = {
    bucket_name   = "cudl-data-source"
    filter_prefix = "items/data/tei/"
    filter_suffix = ".xml"
  }
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
  transform_lambda_bucket_sqs_notifications = [
    for notification in var.transform-lambda-bucket-sqs-notifications : (
      notification.bucket_name == local.tei_processing_notification.bucket_name &&
      notification.filter_prefix == local.tei_processing_notification.filter_prefix &&
      lookup(notification, "filter_suffix", "") == local.tei_processing_notification.filter_suffix
      ) ? merge(notification, {
        queue_name = var.enable_ark_workflow ? "CUDL_TEIArkIngestionQueue" : local.tei_processing_forward_queue_name
    }) : notification
  ]
}
