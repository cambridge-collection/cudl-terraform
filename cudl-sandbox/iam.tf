data "aws_iam_policy_document" "assume_role_logs" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["logs.amazonaws.com"]
    }

    # condition {
    #   test     = "StringEquals"
    #   variable = "aws:SourceArn"
    #   values   = [
    #     "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
    #   ]
    # }
  }
}

data "aws_iam_policy_document" "cloudwatch" {
  statement {
    actions   = ["kinesis:PutRecord"]
    resources = [aws_kinesis_stream.cloudwatch.arn]
  }
}

resource "aws_iam_policy" "cloudwatch" {
  name        = format("%s-cloudwatch", module.cudl_viewer.name_prefix)
  path        = "/"
  description = "Policy granting permission for CloudWatch to put events in a Kinesis Stream"
  policy      = data.aws_iam_policy_document.cloudwatch.json
}

resource "aws_iam_role" "cloudwatch" {
  path                 = "/"
  description          = "IAM role for CloudWatch"
  name                 = format("%s-cloudwatch", module.cudl_viewer.name_prefix)
  assume_role_policy   = data.aws_iam_policy_document.assume_role_logs.json
  max_session_duration = 3600
}

resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.cloudwatch.name
  policy_arn = aws_iam_policy.cloudwatch.arn
}

data "aws_iam_policy_document" "assume_role_firehose" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "firehose" {
  name               = format("%s-firehose", module.cudl_viewer.name_prefix)
  assume_role_policy = data.aws_iam_policy_document.assume_role_firehose.json
}
