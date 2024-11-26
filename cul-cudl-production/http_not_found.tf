resource "aws_s3_object" "http_not_found" {
  bucket   = module.cudl-data-processing.destination_bucket
  key      = format("%s.html", var.cloudfront_origin_errors_path)
  content  = templatefile("${path.module}/templates/darwin/not_found.html.ttfpl", {
    link = module.cudl-data-processing.cloudfront_distribution_domain_name
  })
}
