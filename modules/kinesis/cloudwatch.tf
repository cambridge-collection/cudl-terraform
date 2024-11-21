resource "aws_cloudwatch_log_group" "source" {
  name = "/ecs/${var.name_prefix}"
}

resource "aws_cloudwatch_log_subscription_filter" "source" {
  name            = "${var.name_prefix}-logs"
  log_group_name  = aws_cloudwatch_log_group.source.name
  filter_pattern  = var.cloudwatch_log_subscription_filter_pattern
  destination_arn = aws_cloudwatch_log_destination.target.arn
  distribution    = "ByLogStream"
}

resource "aws_cloudwatch_log_group" "firehose" {
  name = format("/aws/kinesisfirehose/%s", format("%s-cloudwatch", var.name_prefix))
}

resource "aws_cloudwatch_log_stream" "firehose" {
  name           = "DestinationDelivery" # mandatory name
  log_group_name = aws_cloudwatch_log_group.firehose.name
}

resource "aws_cloudwatch_log_destination" "target" {
  name       = var.name_prefix
  role_arn   = aws_iam_role.cloudwatch.arn
  target_arn = aws_kinesis_stream.cloudwatch.arn
}

resource "aws_cloudwatch_log_destination_policy" "target" {
  destination_name = aws_cloudwatch_log_destination.target.name
  access_policy    = data.aws_iam_policy_document.destination_access_policy.json
}

data "aws_iam_policy_document" "destination_access_policy" {
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
      aws_cloudwatch_log_destination.target.arn,
    ]
  }
}
