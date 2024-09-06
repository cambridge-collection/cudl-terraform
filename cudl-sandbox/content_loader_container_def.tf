locals {
  content_loader_container_name_db = join("-", [var.content_loader_container_name_db, var.cluster_name_suffix])
  content_loader_container_name_ui = join("-", [var.content_loader_container_name_ui, var.cluster_name_suffix])
  content_loader_container_defs = [
    {
      name           = local.content_loader_container_name_db,
      systemControls = [],
      image          = data.aws_ecr_image.content_loader["dl-loader-db"].image_uri,
      cpu            = 1024,
      portMappings = [
        {
          containerPort = 5432,
          hostPort      = 5432,
          protocol      = "tcp"
        }
      ],
      essential = true,
      command = [
        "-p 5432"
      ],
      environment = [
        {
          name  = "POSTGRES_USER",
          value = "dl-loading-ui"
        },
        {
          name  = "POSTGRES_PASSWORD",
          value = "password"
        },
        {
          name  = "POSTGRES_DB",
          value = "dl-loading-ui"
        }
      ],
      environmentFiles = [
        {
          value = "${module.base_architecture.s3_bucket_arn}/${var.environment}-cudl-loader-ui.env",
          type  = "s3"
        }
      ],
      mountPoints = [
        {
          sourceVolume  = join("-", [module.content_loader.name_prefix, var.content_loader_container_name_db]),
          containerPath = var.content_loader_ecs_task_def_volumes[var.content_loader_container_name_db],
          readOnly      = false
        }
      ],
      volumesFrom = [],
      hostname    = local.content_loader_container_name_db,
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group           = module.base_architecture.cloudwatch_log_group_name,
          awslogs-region          = var.deployment-aws-region,
          awslogs-stream-prefix   = "ecs"
          awslogs-datetime-format = "\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2}.\\d{3}"
        }
      },
      healthCheck = {
        command = [
          "CMD-SHELL",
          "pg_isready  || exit 1"
        ],
        interval    = 30,
        timeout     = 5,
        retries     = 3,
        startPeriod = 300
      }
    },
    {
      name           = local.content_loader_container_name_ui,
      systemControls = [],
      image          = data.aws_ecr_image.content_loader["dl-loader-ui"].image_uri,
      links = [
        local.content_loader_container_name_db
      ],
      portMappings = [
        {
          containerPort = var.content_loader_application_port,
          hostPort      = var.content_loader_target_group_port,
          protocol      = "tcp"
        }
      ],
      essential = true,
      entryPoint = [
        "bash",
        "-c",
        "mount-s3 --version && mkdir -p /mnt/s3data/data && mount-s3 --allow-overwrite --allow-delete ${module.cudl-data-processing.source_bucket} /mnt/s3data/data && java -jar -debug /usr/local/dl-loading-ui.war --spring.config.additional-location=/etc/dl-loading-ui/"
      ],
      environment = [
        {
          name  = "LOADING_DB_HOST_AND_PORT",
          value = "${local.content_loader_container_name_db}:5432"
        }
      ],
      environmentFiles = [
        {
          value = "${module.base_architecture.s3_bucket_arn}/${var.environment}-cudl-loader-ui.env",
          type  = "s3"
        }
      ],
      mountPoints = [],
      volumesFrom = [],
      linuxParameters = {
        capabilities = {
          drop = [],
          add = [
            "SYS_ADMIN"
          ]
        },
        devices = [
          {
            hostPath      = "/dev/fuse",
            containerPath = "/dev/fuse"
          }
        ]
      },
      dependsOn = [
        {
          containerName = local.content_loader_container_name_db,
          condition     = "HEALTHY"
        }
      ],
      hostname   = local.content_loader_container_name_ui,
      privileged = true,
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = module.base_architecture.cloudwatch_log_group_name,
          awslogs-region        = var.deployment-aws-region,
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ]
}
