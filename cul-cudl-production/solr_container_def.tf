locals {
  solr_container_name_solr = join("-", [var.solr_container_name_solr, var.cluster_name_suffix])
  solr_container_name_api  = join("-", [var.solr_container_name_api, var.cluster_name_suffix])
  solr_container_defs = [
    {
      name              = local.solr_container_name_solr,
      systemControls    = [],
      image             = data.aws_ecr_image.solr["darwin/solr"].image_uri,
      cpu               = floor((var.solr_ecs_task_def_cpu / 3) * 2),
      memory            = local.solr_ecs_task_def_memory - 512
      memoryReservation = local.solr_ecs_task_def_memory - 1024
      portMappings = [
        {
          containerPort = var.solr_application_port,
          hostPort      = var.solr_application_port,
          protocol      = "tcp"
          name          = tostring(var.solr_application_port)
          appProtocol   = "http"
        }
      ],
      essential  = true,
      entryPoint = [],
      environment = [
        {
          name  = "SOLR_HEAP",
          value = format("%sm", floor(local.solr_ecs_task_def_memory / 2))
        }
      ],
      environmentFiles = [],
      # NOTE it does not seem to be possible to specify the host path here
      # Volume must match name specified in task definition
      mountPoints = [for name, path in var.solr_ecs_task_def_volumes :
        {
          sourceVolume  = join("-", [module.solr.name_prefix, name]),
          containerPath = path,
          readOnly      = false
        }
      ],
      volumesFrom = [],
      linuxParameters = {
        capabilities = {
          drop = [],
          add = [
            "SYS_ADMIN"
          ]
        },
        devices = []
      },
      privileged = true,
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = module.base_architecture.cloudwatch_log_group_name,
          awslogs-region        = var.deployment-aws-region,
          awslogs-stream-prefix = "ecs/${local.solr_container_name_solr}"
        },
        secretOptions = []
      }
    },
    {
      name              = local.solr_container_name_api,
      systemControls    = [],
      image             = data.aws_ecr_image.solr["darwin/solr-api"].image_uri,
      cpu               = floor(var.solr_ecs_task_def_cpu / 3),
      memory            = 1024,
      memoryReservation = 512,
      portMappings = [
        {
          containerPort = var.solr_target_group_port,
          hostPort      = var.solr_target_group_port
          protocol      = "tcp"
          name          = tostring(var.solr_target_group_port)
          appProtocol   = "http"
        }
      ],
      essential = true,
      command   = [],
      environment = [
        {
          name  = "SOLR_HOST",
          value = "localhost"
        },
        {
          name  = "SOLR_PORT",
          value = tostring(var.solr_application_port)
        },
        {
          name  = "API_PORT",
          value = tostring(var.solr_target_group_port)
        },
        {
          name  = "NUM_WORKERS"
          value = "3"
        }
      ],
      environmentFiles = [],
      mountPoints      = [],
      volumesFrom      = [],
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = module.base_architecture.cloudwatch_log_group_name,
          awslogs-region        = var.deployment-aws-region,
          awslogs-stream-prefix = "ecs/${local.solr_container_name_api}"
        },
        secretOptions = []
      }
    },
  ]
}
