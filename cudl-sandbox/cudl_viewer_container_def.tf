locals {
  cudl_viewer_container_name = join("-", ["cudl-viewer", var.cluster_name_suffix])
  cudl_viewer_db_container_name = join("-", ["cudl-viewer-db", var.cluster_name_suffix])
  # cudl_viewer_sidecar_container_name = join("-", ["cudl-viewer-sidecar", var.cluster_name_suffix])
  cudl_viewer_container_defs = [
    {
      name              = local.cudl_viewer_container_name,
      hostname          = local.cudl_viewer_container_name,
      image             = data.aws_ecr_image.cudl_viewer["sandbox-cudl-viewer"].image_uri,
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
          value = "jdbc:mysql://${local.cudl_viewer_db_container_name}/${var.cudl_viewer_db_name}"
        }
      ],
      environmentFiles = [
        {
          value = "${module.base_architecture.s3_bucket_arn}/${module.cudl_viewer.name_prefix}/cudl-viewer.env",
          type  = "s3"
        }
      ],
      secrets = [],
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
      name              = local.cudl_viewer_db_container_name,
      hostname          = local.cudl_viewer_db_container_name,
      image             = data.aws_ecr_image.cudl_viewer["sandbox-cudl-viewer-db"].image_uri,
      # cpu               = 0,
      # memoryReservation = 512,
      portMappings = [
        {
          containerPort = 5432,
          hostPort      = 5432,
          protocol      = "tcp"
        }
      ],
      essential = true,
      environment = [],
      secrets = [],
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
