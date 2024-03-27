resource "aws_s3_bucket" "cudl-env-file-bucket" {
  bucket = "${var.environment}-cudl-env-files"
}

//TODO stop hardcoding content of env file. Add variables required.
resource "aws_s3_object" "cudl-loader-env-file" {
  bucket = aws_s3_bucket.cudl-env-file-bucket.bucket
  key    = "${var.environment}-cudl-loader-ui.env"
  content = templatefile("${path.module}/cudl-loader-ui.tftpl.env", {

  })
  depends_on = [
    aws_s3_bucket.cudl-env-file-bucket
  ]
}