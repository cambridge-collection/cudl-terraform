resource "aws_lambda_function" "create-transform-lambda-function" {
  count = length(var.transform-lambda-information)

  function_name = substr("${var.environment}-${var.transform-lambda-information[count.index].name}", 0, 64)
  description   = var.transform-lambda-information[count.index].description
  package_type  = var.transform-lambda-information[count.index].jar_path != null ? "Zip" : "Image"
  s3_bucket     = var.transform-lambda-information[count.index].jar_path != null ? var.lambda-jar-bucket : null
  s3_key        = var.transform-lambda-information[count.index].jar_path
  image_uri     = var.transform-lambda-information[count.index].image_uri
  runtime       = var.transform-lambda-information[count.index].runtime
  timeout       = var.transform-lambda-information[count.index].timeout
  memory_size   = var.transform-lambda-information[count.index].memory
  role          = aws_iam_role.assume-lambda-role.arn
  layers        = var.transform-lambda-information[count.index].image_uri != null ? null : concat([aws_lambda_layer_version.xslt-layer.arn], [aws_lambda_layer_version.transform-properties-layer.arn], [var.datadog-layer-1-arn, var.datadog-layer-2-arn])
  handler       = var.transform-lambda-information[count.index].handler
  publish       = true

  dynamic "image_config" {
    for_each = var.transform-lambda-information[count.index].image_uri != null ? [1] : []
    content {
      command           = try(var.transform-lambda-information[count.index].command, null)
      entry_point       = try(var.transform-lambda-information[count.index].entry_point, null)
      working_directory = try(var.transform-lambda-information[count.index].working_directory, null)
    }
  }

  dynamic "vpc_config" {
    for_each = coalesce(var.transform-lambda-information[count.index].transcription, false) ? [] : [1]
    content {
      subnet_ids         = [data.aws_subnet.cudl_subnet.id]
      security_group_ids = [data.aws_security_group.default.id]
    }
  }

  dynamic "file_system_config" {
    for_each = coalesce(var.transform-lambda-information[count.index].transcription, false) ? [] : [1]
    content {
      arn = aws_efs_access_point.efs-access-point.arn

      # Local mount path inside the lambda function. Must start with '/mnt/', and must not end with /
      local_mount_path = var.dst-efs-prefix
    }
  }

  environment {
    variables = merge(
      var.transform-lambda-information[count.index].use_datadog_variables ? var.lambda_environment_datadog_variables : null,
      var.transform-lambda-information[count.index].use_additional_variables ? var.additional_lambda_environment_variables : null,
      var.transform-lambda-information[count.index].environment_variables,
    )
  }

  depends_on = [aws_efs_mount_target.efs-mount-point]
}

# Upgrade provider to change batch size

resource "aws_lambda_alias" "create-transform-lambda-alias" {
  count = length(var.transform-lambda-information)

  name          = var.lambda-alias-name
  function_name = aws_lambda_function.create-transform-lambda-function[count.index].arn
  #function_version = var.transform-lambda-information[count.index].live_version
  function_version = aws_lambda_function.create-transform-lambda-function[count.index].version

  depends_on = [aws_lambda_function.create-transform-lambda-function]
}

resource "aws_lambda_function" "create-db-lambda-function" {
  count = length(var.db-lambda-information)

  function_name = substr("${var.environment}-${var.db-lambda-information[count.index].name}", 0, 64)
  description   = var.db-lambda-information[count.index].description
  s3_bucket     = var.lambda-jar-bucket
  s3_key        = var.db-lambda-information[count.index].jar_path
  runtime       = var.db-lambda-information[count.index].runtime
  timeout       = var.db-lambda-information[count.index].timeout
  memory_size   = var.db-lambda-information[count.index].memory
  role          = aws_iam_role.assume-lambda-role.arn
  layers        = [aws_lambda_layer_version.db-properties-layer.arn, var.datadog-layer-1-arn, var.datadog-layer-2-arn]
  handler       = var.db-lambda-information[count.index].handler
  publish       = true

  vpc_config {
    subnet_ids         = [data.aws_subnet.cudl_subnet.id]
    security_group_ids = [data.aws_security_group.default.id]
  }

  file_system_config {
    arn = aws_efs_access_point.efs-access-point.arn

    # Local mount path inside the lambda function. Must start with '/mnt/', and must not end with /
    local_mount_path = var.dst-efs-prefix
  }

  environment {
    variables = var.lambda_environment_datadog_variables
  }

  depends_on = [aws_efs_mount_target.efs-mount-point]
}

resource "aws_lambda_alias" "create-db-lambda-alias" {
  count = length(var.db-lambda-information)

  name          = var.lambda-alias-name
  function_name = aws_lambda_function.create-db-lambda-function[count.index].arn
  #function_version = var.db-lambda-information[count.index].live_version
  function_version = aws_lambda_function.create-db-lambda-function[count.index].version
}

resource "local_file" "create-local-lambda-properties-file" {

  content = <<-EOT
    # This file is generated by Terraform, and shouldn't need to be modified manually.

    # NOTE: transcriptions are written to cudl-transcriptions-staging bucket and only copied to
    # cudl-transcriptions (LIVE) bucket by bitbucket pipeline when data is published (so a commit is made
    # to cudl-data 'live' branch).

    VERSION=${upper(var.environment)}
    DST_BUCKET=${aws_s3_bucket.dest-bucket.id}
    DST_PREFIX=${var.dst-prefix}
    DST_EFS_PREFIX=${var.dst-efs-prefix}
    DST_EFS_ENABLED=true
    DST_S3_PREFIX=${var.dst-s3-prefix}
    DST_XSLT_OUTPUT_FOLDER=json/
    DST_XSLT_OUTPUT_SUFFIX=.json
    TMP_DIR=${var.tmp-dir}
    LARGE_FILE_LIMIT=${var.large-file-limit}
    CHUNKS=${var.chunks}
    XSLT=/opt/xslt/msTeiPreFilter.xsl,/opt/xslt/jsonDocFormatter.xsl
    XSLT_1_PARAMS=
    XSLT_2_PARAMS=
    XSLT_S3_ITEM_RESOURCES=
    REGION=${var.deployment-aws-region}

    # Database details for editing/inserting collection data into CUDL
    DB_JDBC_DRIVER=${var.lambda-db-jdbc-driver}
    DB_URL=${var.lambda-db-url}
    DB_SECRET_KEY=${var.lambda-db-secret-key}

    TRANSCRIPTION_DST_BUCKET=${aws_s3_bucket.transcriptions-bucket.id}
    TRANSCRIPTION_DST_PREFIX=${var.dst-prefix}
    TRANSCRIPTION_LARGE_FILE_LIMIT=${var.large-file-limit}
    TRANSCRIPTION_CHUNKS=${var.chunks}
    TRANSCRIPTION_FUNCTION_NAME=${var.environment}-${var.transcription-function-name}
    TRANSCRIPTION_PAGIFY_XSLT=${var.transcription-pagify-xslt}
    TRANSCRIPTION_MSTEI_XSLT=${var.transcription-mstei-xslt}
  EOT

  filename = "${path.module}/properties_files/${var.environment}/java/lib/cudl-loader-lambda.properties"
}

data "archive_file" "zip_transform_properties_lambda_layer" {
  type        = "zip"
  output_path = "${path.module}/zipped_properties_files/${var.environment}.properties.zip"
  source_dir  = "${path.module}/properties_files/${var.environment}"

  # Without the `depends_on` argument, the zip file creation fails because the file to zip
  # doesn't exist on the local filesystem yet
  depends_on = [local_file.create-local-lambda-properties-file]
}

resource "aws_lambda_layer_version" "transform-properties-layer" {
  filename         = "${path.module}/zipped_properties_files/${var.environment}.properties.zip"
  layer_name       = "${var.environment}-properties"
  source_code_hash = data.archive_file.zip_transform_properties_lambda_layer.output_base64sha256

  compatible_runtimes = compact(distinct([for lambda in concat(var.transform-lambda-information, var.db-lambda-information) : lambda.runtime]))
  depends_on          = [data.archive_file.zip_transform_properties_lambda_layer]
}

resource "aws_lambda_layer_version" "db-properties-layer" {

  filename         = "${path.module}/zipped_properties_files/${var.environment}.properties.zip"
  layer_name       = "${var.environment}-properties"
  source_code_hash = data.archive_file.zip_transform_properties_lambda_layer.output_base64sha256

  compatible_runtimes = compact(distinct([for lambda in concat(var.transform-lambda-information, var.db-lambda-information) : lambda.runtime]))
  depends_on          = [data.archive_file.zip_transform_properties_lambda_layer]
}

resource "aws_lambda_layer_version" "xslt-layer" {
  s3_bucket  = var.lambda-layer-bucket
  s3_key     = var.lambda-layer-filepath
  layer_name = "${var.environment}-${var.lambda-layer-name}"

  compatible_runtimes = compact(distinct([for lambda in concat(var.transform-lambda-information, var.db-lambda-information) : lambda.runtime]))
}

# Trigger lambda from the SQS queues
resource "aws_lambda_event_source_mapping" "sqs-trigger-lambda-transforms" {
  count = length(var.transform-lambda-information)

  event_source_arn                   = aws_sqs_queue.transform-lambda-sqs-queue[count.index].arn
  function_name                      = aws_lambda_function.create-transform-lambda-function[count.index].arn
  batch_size                         = coalesce(var.transform-lambda-information[count.index].batch_size, 10)
  maximum_batching_window_in_seconds = var.transform-lambda-information[count.index].batch_window

  # NOTE not available in aws provider 4.24.0
  dynamic "scaling_config" {
    for_each = var.transform-lambda-information[count.index].maximum_concurrency != null ? [1] : []
    content {
      maximum_concurrency = var.transform-lambda-information[count.index].maximum_concurrency
    }
  }
}

resource "aws_lambda_event_source_mapping" "sqs-trigger-lambda-db" {
  count = length(var.db-lambda-information)

  event_source_arn = aws_sqs_queue.db-lambda-sqs-queue[count.index].arn
  function_name    = aws_lambda_function.create-db-lambda-function[count.index].arn
}
