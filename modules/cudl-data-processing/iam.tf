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
      "s3:GetObject",
      "s3:ListBucket",
      "s3:GetBucketNotification",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:PutObjectAcl",
      "s3:GetObjectAcl"
    ]
    resources = compact([
      try(aws_s3_bucket.source-bucket.0.arn, null),
      try("${aws_s3_bucket.source-bucket.0.arn}/*", null),
      aws_s3_bucket.dest-bucket.arn,
      "${aws_s3_bucket.dest-bucket.arn}/*",
      aws_s3_bucket.transcriptions-bucket.arn,
      "${aws_s3_bucket.transcriptions-bucket.arn}/*",
      aws_s3_bucket.distribution-bucket.arn,
      "${aws_s3_bucket.distribution-bucket.arn}/*",
    ])
  }
  statement {
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes"
    ]
    resources = [
      "arn:aws:sqs:*:*:${var.environment}-*"
    ]
  }
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:*:*:/aws/lambda/${var.environment}-*"
    ]
  }
  statement {
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
      "ec2:UnassignPrivateIpAddresses",
      "ec2:AssignPrivateIpAddresses"
    ]
    resources = [
      "*"
    ]
  }
  statement {
    actions = [
      "secretsmanager:GetRandomPassword",
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecretVersionIds",
      "secretsmanager:ListSecrets"
    ]
    resources = [
      "arn:aws:secretsmanager:*:*:${var.environment}/cudl/*"
    ]
  }
  statement {
    actions = [
      "lambda:InvokeFunction",
      "lambda:InvokeAsync"
    ]
    resources = [
      "arn:aws:lambda:*:*:${var.environment}-*"
    ]
  }
  statement {
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:ListSecrets"
    ]
    resources = [
      "arn:aws:secretsmanager:${var.deployment-aws-region}:${var.aws-account-number}:secret:datadog_api*"
    ]
  }
}

resource "aws_iam_role" "assume-lambda-role" {
  name = "${var.environment}-assume-lambda-role"

  assume_role_policy = data.aws_iam_policy_document.assume-role-lambda-policy.json
}

resource "aws_iam_policy" "run-lambda-policy" {
  name = "${var.environment}-cudl-lambda-policy"

  policy = data.aws_iam_policy_document.allow-get-and-list-policy.json
}

resource "aws_iam_role_policy_attachment" "cudl-policy-and-role-attachment" {
  role       = aws_iam_role.assume-lambda-role.name
  policy_arn = aws_iam_policy.run-lambda-policy.arn
}


resource "aws_s3_bucket_acl" "transcriptions-bucket-acl" {
  bucket = aws_s3_bucket.transcriptions-bucket.id
  acl    = "public-read"
  depends_on = [aws_s3_bucket_public_access_block.transcriptions-bucket-public-access,
  aws_s3_bucket_ownership_controls.transcriptions-bucket-acl-ownership]
}

# Resource to avoid error "AccessControlListNotSupported: The bucket does not allow ACLs"
resource "aws_s3_bucket_ownership_controls" "transcriptions-bucket-acl-ownership" {
  bucket = aws_s3_bucket.transcriptions-bucket.id
  rule {
    object_ownership = "ObjectWriter"
  }
}

# Turns off block for public access on bucket
resource "aws_s3_bucket_public_access_block" "transcriptions-bucket-public-access" {
  bucket = aws_s3_bucket.transcriptions-bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "transcriptions-bucket-policy" {
  bucket     = aws_s3_bucket.transcriptions-bucket.id
  policy     = data.aws_iam_policy_document.s3-transcription-document.json
  depends_on = [aws_s3_bucket_acl.transcriptions-bucket-acl]
}

data "aws_iam_policy_document" "s3-transcription-document" {
  statement {
    actions = [
      "s3:GetObject"
    ]
    principals {
      identifiers = ["*"]
      type        = "AWS"
    }
    resources = [
      "${aws_s3_bucket.transcriptions-bucket.arn}/*"
    ]
  }
}

data "aws_iam_policy_document" "assume-role-datasync-policy" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type        = "Service"
      identifiers = ["datasync.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "s3-deploy-document" {
  statement {
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:AbortMultipartUpload",
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:ListMultipartUploadParts",
      "s3:GetObjectTagging",
      "s3:PutObjectTagging",
      "s3:PutObject"
    ]

    resources = [
      aws_s3_bucket.dest-bucket.arn,
      "${aws_s3_bucket.dest-bucket.arn}/*",
      aws_s3_bucket.transcriptions-bucket.arn,
      "${aws_s3_bucket.transcriptions-bucket.arn}/*",
    ]
  }
}

resource "aws_iam_role" "assume-datasync-role" {
  name = "${var.environment}-cudl-assume-datasync-role"

  assume_role_policy = data.aws_iam_policy_document.assume-role-datasync-policy.json
}

resource "aws_iam_policy" "run-datasync-policy" {
  name = "${var.environment}-cudl-datasync-policy"

  policy = data.aws_iam_policy_document.s3-deploy-document.json
}

resource "aws_iam_role_policy_attachment" "cudl-datasync-policy-and-role-attachment" {
  role       = aws_iam_role.assume-datasync-role.name
  policy_arn = aws_iam_policy.run-datasync-policy.arn
}
