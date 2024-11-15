data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "lambda" {
  statement {
    actions = [
      "s3:PutObject",
      "s3:PutObjectVersion"
    ]
    resources = [
      aws_s3_bucket.this.arn,
      format("%s/*", aws_s3_bucket.this.arn,)
    ]
  }

  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [format(
      "arn:aws:logs:%s:%s:log-group:%s:*",
      data.aws_region.current.name,
      data.aws_caller_identity.current.account_id,
      aws_cloudwatch_log_group.lambda.name
    )]
  }
}

resource "aws_iam_policy" "lambda" {
  name        = "${var.name_prefix}-logs"
  path        = "/"
  description = "Policy for ${"${var.name_prefix}-logs"}"
  policy      = data.aws_iam_policy_document.lambda.json
}

resource "aws_iam_role" "lambda" {
  name               = "${var.name_prefix}-logs"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "lambda" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda.arn
}
