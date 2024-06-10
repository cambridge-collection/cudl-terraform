locals {
  solr_persist_container_name_solr = join("-", [var.solr_container_name_solr, var.cluster_name_suffix])
  solr_persist_container_name_api  = join("-", [var.solr_container_name_api, var.cluster_name_suffix])
  solr_persist_container_defs = [
    {
      name           = local.solr_persist_container_name_solr,
      systemControls = [],
      image          = data.aws_ecr_image.solr["cudl-solr"].image_uri,
      cpu            = 0,
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
          name  = "SOLR_JAVA_MEM",
          value = "-Xms1g -Xmx1g"
        }
      ],
      environmentFiles = [],
      # NOTE it does not seem to be possible to specify the host path here
      # Volume must match name specified in task definition
      mountPoints = [for name, path in var.solr_persist_ecs_task_def_volumes :
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
      # dependsOn = [
      #   {
      #     containerName = local.solr_persist_container_name_api,
      #     condition     = "HEALTHY"
      #   }
      # ],
      hostname   = local.solr_persist_container_name_solr,
      privileged = true,
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group           = module.base_architecture.cloudwatch_log_group_name,
          awslogs-region          = var.deployment-aws-region,
          awslogs-stream-prefix   = "ecs"
          awslogs-datetime-format = "\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2}.\\d{3}"
        }
      }
    },
    {
      name              = local.solr_persist_container_name_api,
      systemControls    = [],
      image             = data.aws_ecr_image.solr["cudl-solr-api"].image_uri,
      cpu               = 1024,
      memory            = 1024,
      memoryReservation = 1024,
      links = [
        local.solr_persist_container_name_solr
      ],
      portMappings = [
        {
          containerPort = var.solr_api_port,
          hostPort      = 8091
          protocol      = "tcp"
          name          = tostring(var.solr_api_port)
          appProtocol   = "http"
        }
      ],
      essential = true,
      command   = [],
      environment = [
        {
          name  = "SOLR_HOST",
          value = local.solr_persist_container_name_solr
        },
        {
          name  = "SOLR_PORT",
          value = tostring(var.solr_application_port)
        }
      ],
      environmentFiles = [],
      mountPoints      = [],
      volumesFrom      = [],
      hostname         = local.solr_persist_container_name_api,
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group           = module.base_architecture.cloudwatch_log_group_name,
          awslogs-region          = var.deployment-aws-region,
          awslogs-stream-prefix   = "ecs"
          awslogs-datetime-format = "\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2},\\d{3}"
        }
      }
    },

  ]
}
