resource "aws_iam_policy" "logging" {
  name        = "${local.base_name_prefix}-logging"
  description = "IAM policy for central logging"
  policy      = data.aws_iam_policy_document.logging.json
}

data "aws_iam_policy_document" "logging" {
  statement {
    effect = "Allow"

    resources = [
      data.aws_secretsmanager_secret_version.logs_access_key_id.arn,
      data.aws_secretsmanager_secret_version.logs_secret_access_key.arn
    ]

    actions = [
      "secretsmanager:GetSecretValue"
    ]
  }

  statement {
    effect = "Allow"

    resources = [
      "arn:aws:logs:eu-west-1:874581676011:log-group:/cul/cudl/staging:*"
    ]

    actions = [
      "logs:CreateLogStream",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
      "logs:GetLogEvents"
    ]
  }
}
