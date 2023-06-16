resource "aws_s3_bucket" "transkribus-bucket" {
  bucket = lower("${var.environment}-${var.transkribus-bucket-name}")
}

resource "aws_s3_bucket_versioning" "transkribus-bucket-versioning" {
  bucket = aws_s3_bucket.transkribus-bucket.id
  versioning_configuration {
    status = "Suspended"
  }
}

resource "aws_s3_bucket_notification" "transkribus-bucket-notification" {
  bucket = aws_s3_bucket.transkribus-bucket.id

  queue {
    queue_arn     = aws_sqs_queue.enhancements-lambda-sqs-queue[0].arn
    events        = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
    filter_prefix       = "transkribus/"
    filter_suffix       = ".xml"
  }

  depends_on = [aws_sqs_queue.enhancements-lambda-sqs-queue, aws_lambda_function.create-transkribus-lambda-function]
}