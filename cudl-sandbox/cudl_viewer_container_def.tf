locals {
  cudl_viewer_container_name    = join("-", ["cudl-viewer", var.cluster_name_suffix])
  cudl_viewer_db_container_name = join("-", ["cudl-viewer-db", var.cluster_name_suffix])
  # cudl_viewer_sidecar_container_name = join("-", ["cudl-viewer-sidecar", var.cluster_name_suffix])
  cudl_viewer_container_defs = [
    {
      name              = local.cudl_viewer_container_name,
      image             = data.aws_ecr_image.cudl_viewer["sandbox-cudl-viewer"].image_uri,
      cpu               = 0,
      memoryReservation = 512,
      portMappings = [
        {
          containerPort = var.cudl_viewer_container_port,
          hostPort      = var.cudl_viewer_container_port,
          protocol      = "tcp"
        }
      ],
      essential = true,
      environment = [
        {
          name  = "S3_URL",
          value = "s3://${module.base_architecture.s3_bucket}/${module.cudl_viewer.name_prefix}/cudl-global.properties"
        }
      ],
      mountPoints = [for name, path in var.cudl_viewer_ecs_task_def_volumes :
        {
          sourceVolume  = join("-", [module.cudl_viewer.name_prefix, name]),
          containerPath = path,
          readOnly      = false
        }
      ],
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = module.kinesis.source_log_group_name,
          awslogs-region        = var.deployment-aws-region,
          awslogs-stream-prefix = "cudl-viewer-log"
        },
        secretOptions = []
      }
    }
  ]
}
