locals {
  environment = var.environment # NOTE use of local variable allows for owner-specific naming in sandbox environment
  default_tags = {
    Environment  = title(var.environment)
    Project      = var.project
    Component    = var.component
    Subcomponent = var.subcomponent
    Deployment   = title(local.environment)
    Source       = "https://github.com/cambridge-collection/cudl-terraform"
    terraform    = true
  }
  additional_lambda_variables = {
    AWS_DATA_ENHANCEMENTS_BUCKET = "${local.environment}-cudl-data-enhancements"
    AWS_DATA_SOURCE_BUCKET       = "${local.environment}-cudl-data-source"
    AWS_OUTPUT_BUCKET            = "${local.environment}-cudl-data-releases"
  }
  enhancements_lambda_variables = {
    AWS_CUDL_DATA_SOURCE_BUCKET = "${local.environment}-cudl-data-source"
    AWS_OUTPUT_BUCKET           = "${local.environment}-cudl-data-source"
  }

  # Solr
  solr_container_name_solr = join("-", [var.solr_container_name_solr, var.cluster_name_suffix])
  solr_container_name_api  = join("-", [var.solr_container_name_api, var.cluster_name_suffix])
  solr_container_defs = [
    {
      name           = local.solr_container_name_solr,
      systemControls = [],
      image          = "${module.solr.ecr_repository_urls["cudl-solr"]}:latest",
      cpu            = 0,
      links = [
        local.solr_container_name_api
      ],
      portMappings = [
        {
          containerPort = var.solr_application_port,
          hostPort      = var.solr_application_port,
          protocol      = "tcp"
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
      # dependsOn = [
      #   {
      #     containerName = local.solr_container_name_api,
      #     condition     = "HEALTHY"
      #   }
      # ],
      hostname   = local.solr_container_name_solr,
      privileged = true,
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = module.base_architecture.cloudwatch_log_group_name,
          awslogs-region        = var.deployment-aws-region,
          awslogs-stream-prefix = "ecs"
        }
      }
    },
    {
      name              = local.solr_container_name_api,
      systemControls    = [],
      image             = "${module.solr.ecr_repository_urls["cudl-solr-api"]}:latest",
      cpu               = 1024,
      memory            = 1024,
      memoryReservation = 1024,
      portMappings = [
        {
          containerPort = var.solr_api_port,
          hostPort      = var.solr_target_group_port,
          protocol      = "tcp"
        }
      ],
      essential = true,
      command   = [],
      environment = [
        {
          name  = "SOLR_HOST",
          value = local.solr_container_name_solr
        },
        {
          name  = "SOLR_PORT",
          value = tostring(var.solr_application_port)
        }
      ],
      environmentFiles = [],
      mountPoints      = [],
      volumesFrom      = [],
      hostname         = local.solr_container_name_api,
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = module.base_architecture.cloudwatch_log_group_name,
          awslogs-region        = var.deployment-aws-region,
          awslogs-stream-prefix = "ecs"
        }
      }
    },

  ]
}

