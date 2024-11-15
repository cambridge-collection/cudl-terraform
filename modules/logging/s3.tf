resource "aws_s3_bucket" "this" {
  bucket        = "${var.name_prefix}-logs"
  force_destroy = var.s3_bucket_force_destroy
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = var.s3_bucket_versioning_enabled ? "Enabled" : "Disabled"
  }
}
