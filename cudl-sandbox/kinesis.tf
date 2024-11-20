resource "aws_kinesis_stream" "cloudwatch" {
  name             = format("%s-cloudwatch", module.cudl_viewer.name_prefix)
  retention_period = 24

  stream_mode_details {
    stream_mode = "ON_DEMAND"
  }
}

resource "aws_kinesis_firehose_delivery_stream" "cloudwatch" {
  name        = format("%s-cloudwatch", module.cudl_viewer.name_prefix)
  destination = "extended_s3"

  kinesis_source_configuration {
    kinesis_stream_arn = aws_kinesis_stream.cloudwatch.arn
    role_arn           = aws_iam_role.firehose.arn
  }

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose.arn
    bucket_arn = module.logs.s3_bucket_arn
  }
}
