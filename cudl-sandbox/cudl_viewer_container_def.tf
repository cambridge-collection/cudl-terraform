locals {
  cudl_viewer_container_name    = join("-", ["cudl-viewer", var.cluster_name_suffix])
  cudl_viewer_db_container_name = join("-", ["cudl-viewer-db", var.cluster_name_suffix])
  # cudl_viewer_sidecar_container_name = join("-", ["cudl-viewer-sidecar", var.cluster_name_suffix])
  cudl_viewer_container_defs = [
    {
      name     = local.cudl_viewer_container_name,
      hostname = local.cudl_viewer_container_name,
      image    = data.aws_ecr_image.cudl_viewer["sandbox-cudl-viewer"].image_uri,
      links = [
        local.cudl_viewer_db_container_name
      ],
      cpu               = 0,
      memoryReservation = 512,
      portMappings = [
        {
          containerPort = var.cudl_viewer_container_port,
          hostPort      = var.cudl_viewer_target_group_port,
          protocol      = "tcp"
        }
      ],
      essential = true,
      environment = [
        {
          name  = "JDBC_URL"
          value = "jdbc:postgresql://${local.cudl_viewer_db_container_name}:5432/${var.cudl_viewer_db_name}?autoReconnect=true"
        },
      ],
      environmentFiles = [
        {
          value = "${module.base_architecture.s3_bucket_arn}/${module.cudl_viewer.name_prefix}/cudl-viewer.env",
          type  = "s3"
        }
      ],
      mountPoints = [for name, path in var.cudl_viewer_ecs_task_def_volumes :
        {
          sourceVolume  = join("-", [module.cudl_viewer.name_prefix, name]),
          containerPath = path,
          readOnly      = false
        }
      ],
      secrets = [
        {
          name      = "JDBC_USER",
          valueFrom = data.aws_ssm_parameter.cudl_viewer_jdbc_user.arn
        },
        {
          name      = "JDBC_PASSWORD",
          valueFrom = data.aws_ssm_parameter.cudl_viewer_jdbc_password.arn
        }
      ],
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = module.base_architecture.cloudwatch_log_group_name,
          awslogs-region        = var.deployment-aws-region,
          awslogs-stream-prefix = "cudl-viewer-log"
        },
        secretOptions = []
      }
    },
    {
      name     = local.cudl_viewer_db_container_name,
      hostname = local.cudl_viewer_db_container_name,
      image    = data.aws_ecr_image.cudl_viewer["sandbox-cudl-viewer-db"].image_uri,
      # cpu               = 0,
      # memoryReservation = 512,
      portMappings = [
        {
          containerPort = 5432,
          hostPort      = 5432,
          protocol      = "tcp"
        }
      ],
      environment = [
        {
          name  = "POSTGRES_DB"
          value = var.cudl_viewer_db_name
        },
      ],
      essential = true,
      secrets = [
        {
          name      = "POSTGRES_USER",
          valueFrom = data.aws_ssm_parameter.cudl_viewer_jdbc_user.arn
        },
        {
          name      = "POSTGRES_PASSWORD",
          valueFrom = data.aws_ssm_parameter.cudl_viewer_jdbc_password.arn
        }
      ],
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = module.base_architecture.cloudwatch_log_group_name,
          awslogs-region        = var.deployment-aws-region,
          awslogs-stream-prefix = "cudl-viewer-db-log"
        },
        secretOptions = []
      }
    }
  ]
}