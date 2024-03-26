locals {
  additional_lambda_variables = {
    AWS_DATA_RELEASES_BUCKET = "${var.environment}-cudl-data-releases"
    AWS_DATA_SOURCE_BUCKET   = "${var.environment}-cudl-data-source"
    AWS_TRANSCRIPTION_BUCKET = "${var.environment}-cudl-transcriptions"
  }
}