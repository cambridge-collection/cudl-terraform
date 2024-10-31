resource "aws_cloudfront_function" "viewer" {
  name                         = "${local.environment}-cudl-viewer"
  runtime                      = "cloudfront-js-2.0"
  publish                      = true
  key_value_store_associations = [aws_cloudfront_key_value_store.viewer.arn]
  code = templatefile("${path.module}/templates/viewer/cloudfront-function.js.ttfpl", {
    key_pass = aws_cloudfrontkeyvaluestore_key.password.key
    key_user = aws_cloudfrontkeyvaluestore_key.username.key
  })
}

resource "aws_cloudfront_key_value_store" "viewer" {
  name = "${local.environment}-cudl-viewer"
}

resource "aws_cloudfrontkeyvaluestore_key" "username" {
  key_value_store_arn = aws_cloudfront_key_value_store.viewer.arn
  key                 = "username"
  value               = data.aws_ssm_parameter.cudl_viewer_cloudfront_username.value
}

resource "aws_cloudfrontkeyvaluestore_key" "password" {
  key_value_store_arn = aws_cloudfront_key_value_store.viewer.arn
  key                 = "password"
  value               = data.aws_ssm_parameter.cudl_viewer_cloudfront_password.value
}

resource "aws_cloudfront_function" "viewer-cors-header" {
  name    = "${local.environment}-cudl-viewer-cors-header"
  runtime = "cloudfront-js-2.0"
  publish = true
  code    = <<-EOT

  async function handler(event)  {
      const request = event.request;
      const response  = event.response;

      // If Access-Control-Allow-Origin CORS header is missing, add it.
      // Since JavaScript doesn't allow for hyphens in variable names, we use the dict["key"] notation.
      // This function is required for IIIF Manifests to be allowed to be loaded by external IIIF viewers.
      // Also possibly required for some embedded viewer content - requires investigation.
      if (!response.headers['access-control-allow-origin'] && request.headers['origin']) {
          response.headers['access-control-allow-origin'] = {value: "*"};
      }

      return response;
  }
EOT

}
