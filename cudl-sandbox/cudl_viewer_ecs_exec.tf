resource "aws_iam_role_policy" "cudl_viewer_ecs_exec" {
  name = "sandbox-cudl-viewer-ecs-exec-policy"
  role = "sandbox-cudl-viewer-workload-task-role"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ]
        Resource = "*"
      }
    ]
  })
}
