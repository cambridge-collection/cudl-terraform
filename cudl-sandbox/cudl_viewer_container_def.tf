locals {
  cudl_viewer_container_name = join("-", ["cudl-viewer", var.cluster_name_suffix])
  cudl_viewer_container_defs = [
    {
      name              = local.cudl_viewer_container_name,
      image             = "${module.cudl_viewer.ecr_repository_urls["sandbox-cudl-viewer"]}:latest",
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
      environment = [],
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
    }
  ]
}
