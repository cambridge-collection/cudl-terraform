resource "aws_s3_bucket" "cloudfront_access_logging" {
  bucket = join("-", [local.base_name_prefix, "cloudfront-access-logs"])
}

# ACLs need to be enabled by changing the ownership controls to allow access logging
resource "aws_s3_bucket_ownership_controls" "cloudfront_access_logging" {
  bucket = aws_s3_bucket.cloudfront_access_logging.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}
