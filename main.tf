terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.2.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.1.0"
    }
  }

  backend "s3" {
    bucket         = "terraform-state-kie4di"
    key            = "cudl-infra.tfstate"
    dynamodb_table = "terraform-state-lock-kie4di"
    region         = "eu-west-1"
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  region  = var.deployment-aws-region
  profile = "default"

  default_tags {
    tags = {
      Environment = title(var.environment)
      Project     = "CUDL"
    }
  }
}

data "aws_iam_policy_document" "assume-role-lambda-policy" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "allow-get-and-list-policy" {
  statement {
    actions = [
      "s3:Get*",
      "s3:List*",
      "s3:Put*"
    ]

    resources = [
      "arn:aws:s3:::${aws_s3_bucket.source-bucket.arn}",
      "arn:aws:s3:::${aws_s3_bucket.source-bucket.arn}/*",
      "arn:aws:s3:::${aws_s3_bucket.dest-bucket.arn}",
      "arn:aws:s3:::${aws_s3_bucket.dest-bucket.arn}/*"
    ]
  }
}

resource "aws_s3_bucket" "source-bucket" {
  bucket = lower("${var.environment}-${var.source-bucket-name}")
}

resource "aws_s3_bucket" "dest-bucket" {
  bucket = lower("${var.environment}-${var.destination-bucket-name}")
}

resource "aws_s3_bucket" "transcriptions-bucket" {
  bucket = lower("${var.environment}-${var.transcriptions-bucket-name}")
}

resource "aws_iam_role" "assume-lambda-role" {
  name = "${var.environment}-assume-lambda-role"

  assume_role_policy = data.aws_iam_policy_document.assume-role-lambda-policy.json
}

resource "aws_iam_policy" "run-lambda-policy" {
  name = "${var.environment}-cudl-lambda-test-policy"

  policy = data.aws_iam_policy_document.allow-get-and-list-policy.json
}

resource "aws_iam_role_policy_attachment" "cudl-policy-and-role-attachment" {
  role       = aws_iam_role.assume-lambda-role.name
  policy_arn = aws_iam_policy.run-lambda-policy.arn
}

resource "aws_lambda_layer_version" "xslt-layer" {
  s3_bucket  = var.lambda-layer-bucket
  s3_key     = var.lambda-layer-filepath
  layer_name = "${var.environment}-${var.lambda-layer-name}"

  compatible_runtimes = distinct([for lambda in concat(var.transform-lambda-information, var.db-lambda-information) : lambda.runtime])
}

resource "aws_sqs_queue" "transform-lambda-sqs-queue" {
  count = length(var.transform-lambda-information)

  name = substr("${var.environment}-${var.transform-lambda-information[count.index].queue_name}", 0, 64)

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Action": "sqs:SendMessage",
      "Resource": "arn:aws:sqs:*:*:${substr("${var.environment}-${var.transform-lambda-information[count.index].queue_name}", 0, 64)}",
      "Condition": {
        "ArnEquals": { "aws:SourceArn": "${aws_s3_bucket.source-bucket.arn}" }
      }
    }
  ]
}
POLICY

  redrive_policy = jsonencode({
    "deadLetterTargetArn" = aws_sqs_queue.transform-lambda-dead-letter-queue[count.index].arn,
    "maxReceiveCount"     = 3
  })
}

resource "aws_sqs_queue" "db-lambda-sqs-queue" {
  count = length(var.db-lambda-information)

  name = substr("${var.environment}-${var.db-lambda-information[count.index].queue_name}", 0, 64)

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Action": "sqs:SendMessage",
      "Resource": "arn:aws:sqs:*:*:${substr("${var.environment}-${var.db-lambda-information[count.index].queue_name}", 0, 64)}",
      "Condition": {
        "ArnEquals": { "aws:SourceArn": "${aws_s3_bucket.dest-bucket.arn}" }
      }
    }
  ]
}
POLICY

  redrive_policy = jsonencode({
    "deadLetterTargetArn" = aws_sqs_queue.db-lambda-dead-letter-queue[count.index].arn,
    "maxReceiveCount"     = 3
  })
}

resource "aws_s3_bucket_notification" "source-bucket-notifications" {
  count  = length(var.transform-lambda-information)
  bucket = aws_s3_bucket.source-bucket.id

  queue {
    queue_arn     = aws_sqs_queue.transform-lambda-sqs-queue[count.index].arn
    events        = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
    filter_prefix = try(var.transform-lambda-information[count.index].filter_prefix, "") != "" ? var.transform-lambda-information[count.index].filter_prefix : null
    filter_suffix = try(var.transform-lambda-information[count.index].filter_suffix, "") != "" ? var.transform-lambda-information[count.index].filter_suffix : null
  }

  # without the `depends_on` argument, the bucket notification creation fails because the
  # lambda function doesn't exist yet
  depends_on = [aws_lambda_function.create-transform-lambda-function]
}

locals {
  # Some of the buckets have multiple filters that should trigger notifications
  # So we sort out the filters and create them as additional notifications
  other_filter_map = distinct(flatten([
    for lambda in var.transform-lambda-information : [
      for filter in split("|", lambda.other_filters) : {
        queue_index   = index(var.transform-lambda-information, lambda)
        filter_suffix = filter
    }] if try(lambda.other_filters, "") != ""
  ]))

  other-cidr-blocks = length(var.cidr-blocks) > 1 ? toset(slice(var.cidr-blocks, 1, length(var.cidr-blocks))) : toset([])
}

resource "aws_s3_bucket_notification" "additional-source-bucket-notifications" {
  for_each = {
    for filter in local.other_filter_map : filter.filter_suffix => filter.queue_index
  }

  bucket = aws_s3_bucket.source-bucket.id

  queue {
    queue_arn     = aws_sqs_queue.transform-lambda-sqs-queue[each.value].arn
    events        = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
    filter_suffix = each.key
  }

  # without the `depends_on` argument, the bucket notification creation fails because the
  # lambda function doesn't exist yet
  depends_on = [aws_lambda_function.create-transform-lambda-function]
}

resource "aws_s3_bucket_notification" "dest-bucket-notifications" {
  count  = length(var.db-lambda-information)
  bucket = aws_s3_bucket.dest-bucket.id

  queue {
    queue_arn     = aws_sqs_queue.db-lambda-sqs-queue[count.index].arn
    events        = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
    filter_prefix = try(var.db-lambda-information[count.index].filter_prefix, "") != "" ? var.db-lambda-information[count.index].filter_prefix : null
    filter_suffix = try(var.db-lambda-information[count.index].filter_suffix, "") != "" ? var.db-lambda-information[count.index].filter_suffix : null
  }

  # without the `depends_on` argument, the bucket notification creation fails because the
  # lambda function doesn't exist yet
  depends_on = [aws_lambda_function.create-db-lambda-function]
}

resource "aws_sqs_queue" "transform-lambda-dead-letter-queue" {
  count = length(var.transform-lambda-information)

  name = substr("${var.environment}-${var.transform-lambda-information[count.index].queue_name}_DeadLetterQueue", 0, 80)
}

resource "aws_sqs_queue" "db-lambda-dead-letter-queue" {
  count = length(var.db-lambda-information)

  name = substr("${var.environment}-${var.db-lambda-information[count.index].queue_name}_DeadLetterQueue", 0, 80)
}

resource "aws_lambda_function" "create-transform-lambda-function" {
  count = length(var.transform-lambda-information)

  s3_bucket     = var.lambda-jar-bucket
  s3_key        = var.transform-lambda-information[count.index].jar_path
  runtime       = var.transform-lambda-information[count.index].runtime
  timeout       = 900
  role          = aws_iam_role.assume-lambda-role.arn
  layers        = concat(var.transform-lambda-information[count.index].transcription ? [] : [aws_lambda_layer_version.xslt-layer.arn], [aws_lambda_layer_version.transform-properties-layer[count.index].arn])
  function_name = substr("${var.environment}-${var.transform-lambda-information[count.index].name}", 0, 64)
  handler       = var.transform-lambda-information[count.index].handler
  publish       = true
}

resource "aws_lambda_alias" "create-transform-lambda-alias" {
  count = length(var.transform-lambda-information)

  name             = var.lambda-alias-name
  function_name    = aws_lambda_function.create-transform-lambda-function[count.index].arn
  function_version = var.transform-lambda-information[count.index].live_version
}

resource "aws_lambda_function" "create-db-lambda-function" {
  count = length(var.db-lambda-information)

  s3_bucket     = var.lambda-jar-bucket
  s3_key        = var.db-lambda-information[count.index].jar_path
  runtime       = var.db-lambda-information[count.index].runtime
  timeout       = 900
  role          = aws_iam_role.assume-lambda-role.arn
  layers        = [aws_lambda_layer_version.db-properties-layer[count.index].arn]
  function_name = substr("${var.environment}-${var.db-lambda-information[count.index].name}", 0, 64)
  handler       = var.db-lambda-information[count.index].handler
  publish       = true
}

resource "aws_lambda_alias" "create-db-lambda-alias" {
  count = length(var.db-lambda-information)

  name             = var.lambda-alias-name
  function_name    = aws_lambda_function.create-db-lambda-function[count.index].arn
  function_version = var.db-lambda-information[count.index].live_version
}

# TODO: finish parametising the contents of this file - not sure it all needs hard-coding...
resource "local_file" "create-local-transform-lambda-properties-file" {
  count = length(var.transform-lambda-information)

  content = <<-EOT
    # This file is generated by Terraform, and shouldn't need to be modified manually.

    # NOTE: transcriptions are written to cudl-transcriptions-staging bucket and only copied to
    # cudl-transcriptions (LIVE) bucket by bitbucket pipeline when data is published (so a commit is made
    # to cudl-data 'live' branch).

    VERSION=${upper(var.environment)}
    DST_BUCKET=${var.transform-lambda-information[count.index].transcription ? "${var.environment}-${var.transcriptions-bucket-name}" : "${var.environment}-${var.destination-bucket-name}"}
    DST_PREFIX=${var.dst-prefix}
    DST_EFS_PREFIX=${var.dst-efs-prefix}
    DST_S3_PREFIX=${var.dst-s3-prefix}
    TMP_DIR=${var.tmp-dir}
    LARGE_FILE_LIMIT=${var.large-file-limit}
    CHUNKS=${var.chunks}
    FUNCTION_NAME=${var.transform-lambda-information[count.index].transcription ? "${var.transcription-function-name}" : "${var.data-function-name}"}
    XSLT=/opt/xslt/msTeiPreFilter.xsl,/opt/xslt/jsonDocFormatter.xsl

    # Refresh URL settings
    # This is used when refreshing the cudl-viewer cache after new data is loaded.
    REFRESH_URL_ENABLE=true
    REFRESH_URL=https://cudl-dev.lib.cam.ac.uk/refresh
    REFRESH_URL_ENABLE_AUTH=true
    REFRESH_URL_USERNAME=qa
    REFRESH_URL_PASSWORD=qauser

    # Database details for editing/inserting collection data into CUDL
    DB_JDBC_DRIVER=
    DB_URL=
    DB_USERNAME=
    DB_PASSWORD=
  EOT

  filename = "${path.module}/properties_files/${var.environment}-${var.transform-lambda-information[count.index].name}/java/lib/${var.environment}-${var.transform-lambda-information[count.index].name}.properties"
}

data "archive_file" "zip_transform_properties_lambda_layer" {
  count = length(var.transform-lambda-information)

  type        = "zip"
  output_path = "${path.module}/zipped_properties_files/${var.environment}-${var.transform-lambda-information[count.index].name}.properties.zip"
  source_dir  = "${path.module}/properties_files/${var.environment}-${var.transform-lambda-information[count.index].name}"

  # Without the `depends_on` argument, the zip file creation fails because the file to zip
  # doesn't exist on the local filesystem yet
  depends_on = [local_file.create-local-transform-lambda-properties-file]
}

resource "aws_lambda_layer_version" "transform-properties-layer" {
  count = length(var.transform-lambda-information)

  filename   = "${path.module}/zipped_properties_files/${var.environment}-${var.transform-lambda-information[count.index].name}.properties.zip"
  layer_name = "${var.environment}-${var.transform-lambda-information[count.index].name}-properties"

  compatible_runtimes = [var.transform-lambda-information[count.index].runtime]
}

# TODO: finish parametising the contents of this file - not sure it all needs hard-coding...
resource "local_file" "create-local-db-lambda-properties-file" {
  count = length(var.db-lambda-information)

  content = <<-EOT
    # This file is generated by Terraform, and shouldn't need to be modified manually.

    # NOTE: transcriptions are written to cudl-transcriptions-staging bucket and only copied to
    # cudl-transcriptions (LIVE) bucket by bitbucket pipeline when data is published (so a commit is made
    # to cudl-data 'live' branch).

    VERSION=${upper(var.environment)}
    DST_BUCKET=
    DST_PREFIX=${var.dst-prefix}
    DST_EFS_PREFIX=${var.dst-efs-prefix}
    DST_S3_PREFIX=${var.dst-s3-prefix}
    TMP_DIR=${var.tmp-dir}
    LARGE_FILE_LIMIT=${var.large-file-limit}
    CHUNKS=${var.chunks}
    FUNCTION_NAME=${var.data-function-name}
    XSLT=/opt/xslt/msTeiPreFilter.xsl,/opt/xslt/jsonDocFormatter.xsl

    # Refresh URL settings
    # This is used when refreshing the cudl-viewer cache after new data is loaded.
    REFRESH_URL_ENABLE=true
    REFRESH_URL=https://cudl-dev.lib.cam.ac.uk/refresh
    REFRESH_URL_ENABLE_AUTH=true
    REFRESH_URL_USERNAME=qa
    REFRESH_URL_PASSWORD=qauser

    # Database details for editing/inserting collection data into CUDL
    DB_JDBC_DRIVER=
    DB_URL=
    DB_USERNAME=
    DB_PASSWORD=
  EOT

  filename = "${path.module}/properties_files/${var.environment}-${var.db-lambda-information[count.index].name}/java/lib/${var.environment}-${var.db-lambda-information[count.index].name}.properties"
}

data "archive_file" "zip_properties_lambda_layer" {
  count = length(var.db-lambda-information)

  type        = "zip"
  output_path = "${path.module}/zipped_properties_files/${var.environment}-${var.db-lambda-information[count.index].name}.properties.zip"
  source_dir  = "${path.module}/properties_files/${var.environment}-${var.db-lambda-information[count.index].name}"

  # Without the `depends_on` argument, the zip file creation fails because the file to zip
  # doesn't exist on the local filesystem yet
  depends_on = [local_file.create-local-db-lambda-properties-file]
}

resource "aws_lambda_layer_version" "db-properties-layer" {
  count = length(var.db-lambda-information)

  filename   = "${path.module}/zipped_properties_files/${var.environment}-${var.db-lambda-information[count.index].name}.properties.zip"
  layer_name = "${var.environment}-${var.db-lambda-information[count.index].name}-properties"

  compatible_runtimes = [var.db-lambda-information[count.index].runtime]
}

resource "aws_vpc" "cudl_vpc" {
  cidr_block = var.cidr-blocks[0]

  tags = {
    Name = "${var.environment}-${var.vpc-name}"
  }
}

resource "aws_vpc_ipv4_cidr_block_association" "additional_cidr_blocks" {
  for_each = local.other-cidr-blocks

  vpc_id     = aws_vpc.cudl_vpc.id
  cidr_block = each.value
}

resource "aws_vpc_dhcp_options" "dhcp_options_set" {
  domain_name         = var.domain-name
  domain_name_servers = ["AmazonProvidedDNS"]

  tags = {
    Name = "${var.environment}-${var.dchp-options-name}"
  }
}

resource "aws_vpc_dhcp_options_association" "association" {
  vpc_id          = aws_vpc.cudl_vpc.id
  dhcp_options_id = aws_vpc_dhcp_options.dhcp_options_set.id
}

resource "aws_efs_file_system" "efs-volume" {
  availability_zone_name = "${var.deployment-aws-region}a"
  encrypted              = true

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  lifecycle_policy {
    transition_to_primary_storage_class = "AFTER_1_ACCESS"
  }

  tags = {
    Name = "${var.environment}-${var.efs-name}"
  }
}

resource "aws_efs_access_point" "efs-access-point" {
  file_system_id = aws_efs_file_system.efs-volume.id

  posix_user {
    gid = 1000
    uid = 1000
  }

  root_directory {
    path = var.releases-root-directory-path

    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = 777
    }
  }
}
