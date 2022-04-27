data "aws_iam_policy_document" "assume-role-lambda-policy" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "allow-get-and-list-policy" {
  statement {
    actions = [
      "s3:Get*",
      "s3:List*",
      "s3:Put*"
    ]

    resources = [
      "arn:aws:s3:::${aws_s3_bucket.source-bucket.arn}",
      "arn:aws:s3:::${aws_s3_bucket.source-bucket.arn}/*",
      "arn:aws:s3:::${aws_s3_bucket.dest-bucket.arn}",
      "arn:aws:s3:::${aws_s3_bucket.dest-bucket.arn}/*"
    ]
  }
}

resource "aws_iam_role" "assume-lambda-role" {
  name = "${var.environment}-assume-lambda-role"

  assume_role_policy = data.aws_iam_policy_document.assume-role-lambda-policy.json
}

resource "aws_iam_policy" "run-lambda-policy" {
  name = "${var.environment}-cudl-lambda-test-policy"

  policy = data.aws_iam_policy_document.allow-get-and-list-policy.json
}

resource "aws_iam_role_policy_attachment" "cudl-policy-and-role-attachment" {
  role       = aws_iam_role.assume-lambda-role.name
  policy_arn = aws_iam_policy.run-lambda-policy.arn
}
