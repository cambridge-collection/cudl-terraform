locals {
  solr_container_name_solr = join("-", [var.solr_container_name_solr, var.cluster_name_suffix])
  solr_container_name_api  = join("-", [var.solr_container_name_api, var.cluster_name_suffix])
  solr_container_defs = [
    {
      name           = local.solr_container_name_solr,
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
        logDriver = "syslog",
        options = {
          syslog-address = "tcp://fluentd.sandbox-fluentd:5140"
          tag            = local.solr_container_name_solr
        }
      }
    },
    {
      name              = local.solr_container_name_api,
      systemControls    = [],
      image             = data.aws_ecr_image.solr["cudl-solr-api"].image_uri,
      cpu               = 1024,
      memory            = 1024,
      memoryReservation = 1024,
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
          name  = "EXTRA_VAR"
          value = "14"
        }
      ],
      environmentFiles = [],
      mountPoints      = [],
      volumesFrom      = [],
      logConfiguration = {
        logDriver = "syslog",
        options = {
          syslog-address = "tcp://fluentd.sandbox-fluentd:5140"
          tag            = local.solr_container_name_api
        }
      }
    },

  ]
}
