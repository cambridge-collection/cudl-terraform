resource "aws_s3_object" "http_not_found" {
  bucket   = module.cudl-data-processing.destination_bucket
  key      = format("%s/notfound.html", trimprefix(var.cloudfront_origin_errors_path, "/"))
  content_type = "text/html"
  content  = templatefile("${path.module}/templates/darwin/not_found.html.ttfpl", {
    link = module.cudl-data-processing.cloudfront_distribution_domain_name
  })
}
