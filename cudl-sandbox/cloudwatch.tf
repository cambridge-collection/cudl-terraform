resource "aws_cloudwatch_log_group" "cudl_viewer" {
  name = "/ecs/${module.cudl_viewer.name_prefix}"
}

resource "aws_cloudwatch_log_group" "firehose" {
  name = format("%s-firehose", module.cudl_viewer.name_prefix)
}

resource "aws_cloudwatch_log_destination" "cudl_viewer" {
  name       = module.cudl_viewer.name_prefix
  role_arn   = aws_iam_role.cloudwatch.arn
  target_arn = aws_kinesis_stream.cloudwatch.arn
}

resource "aws_cloudwatch_log_destination_policy" "cudl_viewer" {
  destination_name = aws_cloudwatch_log_destination.cudl_viewer.name
  access_policy    = data.aws_iam_policy_document.access_policy.json
}

resource "aws_cloudwatch_log_subscription_filter" "cudl_viewer" {
  name            = "${module.cudl_viewer.name_prefix}-logs"
  log_group_name  = aws_cloudwatch_log_group.cudl_viewer.name
  filter_pattern  = ""
  destination_arn = aws_cloudwatch_log_destination.cudl_viewer.arn
  distribution    = "ByLogStream"
}

data "aws_iam_policy_document" "access_policy" {
  statement {
    effect = "Allow"

    principals {
      type = "AWS"

      identifiers = [
        data.aws_caller_identity.current.account_id,
      ]
    }

    actions = [
      "logs:PutSubscriptionFilter",
    ]

    resources = [
      aws_cloudwatch_log_destination.cudl_viewer.arn,
    ]
  }
}
