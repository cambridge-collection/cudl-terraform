resource "aws_kinesis_stream" "cloudwatch" {
  name             = format("%s-cloudwatch", var.name_prefix)
  retention_period = 24

  stream_mode_details {
    stream_mode = "ON_DEMAND"
  }
}

resource "aws_kinesis_firehose_delivery_stream" "cloudwatch" {
  name        = format("%s-cloudwatch", var.name_prefix)
  destination = "extended_s3"

  kinesis_source_configuration {
    kinesis_stream_arn = aws_kinesis_stream.cloudwatch.arn
    role_arn           = aws_iam_role.firehose.arn
  }

  extended_s3_configuration {
    role_arn            = aws_iam_role.firehose.arn
    bucket_arn          = aws_s3_bucket.this.arn
    error_output_prefix = "errors/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/!{firehose:error-output-type}/"

    processing_configuration {
      enabled = true

      processors {
        type = "Decompression"

        parameters {
          parameter_name  = "CompressionFormat"
          parameter_value = "GZIP"
        }
      }

      processors {
        type = "CloudWatchLogProcessing"

        parameters {
          parameter_name  = "DataMessageExtraction"
          parameter_value = true
        }
      }
    }

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.firehose.name
      log_stream_name = aws_cloudwatch_log_stream.firehose.name
    }
  }
}
