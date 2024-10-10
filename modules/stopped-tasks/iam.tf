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

data "aws_iam_policy_document" "stopped_tasks" {
  statement {
    actions = [
      "ec2:TerminateInstances"
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "ecs:DescribeContainerInstances",
      "ecs:DescribeServices",
      "ecs:DescribeTasks",
      "ecs:ListTasks"
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "logs:CreateLogGroup"
    ]
    resources = [format(
      "arn:aws:logs:%s:%s:*",
      data.aws_region.current.name,
      data.aws_caller_identity.current.account_id
    )]
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
      local.log_group_name
    )]
  }
}

resource "aws_iam_policy" "stopped_tasks" {
  name        = "${var.ecs_service_name}-stopped-tasks"
  path        = "/"
  description = "Policy for ${local.lambda_function_name}"
  policy      = data.aws_iam_policy_document.stopped_tasks.json
}

resource "aws_iam_role" "stopped_tasks" {
  name               = "${var.ecs_service_name}-stopped-tasks"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "stopped_tasks" {
  role       = aws_iam_role.stopped_tasks.name
  policy_arn = aws_iam_policy.stopped_tasks.arn
}
