resource "aws_s3_bucket" "transkribus-bucket" {
  bucket = lower("${var.environment}-${var.transkribus-bucket-name}")
}

resource "aws_s3_bucket_versioning" "transkribus-bucket-versioning" {
  bucket = aws_s3_bucket.transkribus-bucket.id
  versioning_configuration {
    status = "Suspended"
  }
}