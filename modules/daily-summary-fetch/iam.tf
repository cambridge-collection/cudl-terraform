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
      "logs:CreateLogGroup",
    ]
    resources = [format(
      "arn:aws:logs:%s:%s:*",
      data.aws_region.current.name,
      data.aws_caller_identity.current.account_id,
    )]
  }

  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = [format(
      "arn:aws:logs:%s:%s:log-group:%s:*",
      data.aws_region.current.name,
      data.aws_caller_identity.current.account_id,
      local.log_group_name,
    )]
  }

  statement {
    actions = [
      "s3:PutObject",
    ]
    resources = [
      format("arn:aws:s3:::%s/*", var.results_bucket_name),
    ]
  }
}

resource "aws_iam_policy" "lambda" {
  name        = "${local.lambda_function_name}-policy"
  path        = "/"
  description = "Policy for ${local.lambda_function_name}"
  policy      = data.aws_iam_policy_document.lambda.json
}

resource "aws_iam_role" "lambda" {
  name               = "${local.lambda_function_name}-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "lambda" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda.arn
}

