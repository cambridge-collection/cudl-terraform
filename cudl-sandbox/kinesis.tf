resource "aws_kinesis_stream" "cloudwatch" {
  name             = format("%s-cloudwatch", module.cudl_viewer.name_prefix)
  retention_period = 24

  stream_mode_details {
    stream_mode = "ON_DEMAND"
  }
}

data "aws_iam_policy_document" "kinesis" {
  statement {
    effect = "Allow"

    principals {
      type = "AWS"

      identifiers = [
        data.aws_caller_identity.current.account_id,
      ]
    }

    actions = [
      "kinesis:DescribeStreamSummary",
      "kinesis:ListShards",
      "kinesis:PutRecord",
      "kinesis:PutRecords"
    ]

    resources = [
      aws_kinesis_stream.cloudwatch.arn,
    ]
  }
}

resource "aws_kinesis_resource_policy" "cross_account" {
  resource_arn = aws_kinesis_stream.cloudwatch.arn
  policy       = data.aws_iam_policy_document.kinesis.json
}

resource "aws_kinesis_firehose_delivery_stream" "cloudwatch" {
  name        = format("%s-cloudwatch", module.cudl_viewer.name_prefix)
  destination = "extended_s3"

  kinesis_source_configuration {
    kinesis_stream_arn = aws_kinesis_stream.cloudwatch.arn
    role_arn           = aws_iam_role.firehose.arn
  }

  extended_s3_configuration {
    role_arn            = aws_iam_role.firehose.arn
    bucket_arn          = module.logs.s3_bucket_arn
    error_output_prefix = "errors/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/!{firehose:error-output-type}/"

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.firehose.name
      log_stream_name = "firehose"
    }
  }
}
