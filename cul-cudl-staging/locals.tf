locals {
  environment      = var.environment
  base_name_prefix = join("-", compact([local.environment, var.cluster_name_suffix]))
  ark_lambda_name  = "AWSLambda_CUDL_ARK_Ingestion"
  tei_processing_notification = {
    bucket_name   = var.source-bucket-name
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
  transform_lambda_bucket_sqs_notifications = [
    for notification in var.transform-lambda-bucket-sqs-notifications : (
      notification.bucket_name == local.tei_processing_notification.bucket_name &&
      notification.filter_prefix == local.tei_processing_notification.filter_prefix &&
      lookup(notification, "filter_suffix", "") == local.tei_processing_notification.filter_suffix
      ) ? merge(notification, {
        queue_name = var.enable_ark_workflow ? var.tei_ark_ingestion_queue_name : var.tei_processing_forward_queue_name
    }) : notification
  ]
  transform_lambda_information = [
    for lambda in var.transform-lambda-information : lambda
    if var.enable_ark_workflow || lambda.name != local.ark_lambda_name
  ]
  smtp_port                = tonumber(data.aws_ssm_parameter.cudl_viewer_smtp_port.value)
  solr_ecs_task_def_memory = data.aws_ec2_instance_type.asg.memory_size - 768
}
