resource "aws_kinesis_stream" "cloudwatch" {
  name             = format("%s-cloudwatch", module.cudl_viewer.name_prefix)
  retention_period = 24

  stream_mode_details {
    stream_mode = "ON_DEMAND"
  }
}