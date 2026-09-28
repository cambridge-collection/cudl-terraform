# Blocks direct public access to the viewer-internal /pages/* tree (collection HTML,
# site-content pages, page images) and to any /unreleased/* content on the
# cudl-data-releases CloudFront distribution. The viewer reads /pages off EFS server-side
# and serves /images itself; cudl-services only fetches /html/*. Nothing in the serving
# stack fetches /pages or /unreleased over this distribution.
resource "aws_cloudfront_function" "releases_path_filter" {
  name    = "${local.environment}-cudl-data-releases-path-filter"
  runtime = "cloudfront-js-2.0"
  publish = true
  code    = templatefile("${path.module}/templates/cudl-data-releases/cloudfront-function.js.ttfpl", {})
}
