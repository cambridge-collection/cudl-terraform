locals {
  additional_lambda_variables = {
    AWS_DATA_SOURCE_BUCKET   = "${var.environment}-cudl-data-source"
    AWS_TRANSCRIPTION_BUCKET = "${var.environment}-cudl-transcriptions" # NOTE to be removed
    AWS_DIST_BUCKET          = "${var.environment}-cudl-dist"
  }
}