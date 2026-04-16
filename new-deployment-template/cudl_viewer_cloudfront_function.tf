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
