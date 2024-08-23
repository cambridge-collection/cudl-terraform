locals {
  cudl_services_container_name = join("-", ["cudl-services", var.cluster_name_suffix])
  cudl_services_container_defs = [
    {
      name              = local.cudl_services_container_name,
      image             = "${module.cudl_services.ecr_repository_urls["cudl-services"]}:ae4e",
      cpu               = 0,
      memoryReservation = 512,
      portMappings = [
        {
          containerPort = var.cudl_services_container_port,
          hostPort      = var.cudl_services_target_group_port,
          protocol      = "tcp"
        }
      ],
      essential = true,
      environment = [
        {
          name  = "CUDL_SERVICES_DB_NAME",
          value = "dev_cudl_viewer"
        },
        {
          name  = "AWS_REGION",
          value = "eu-west-1"
        },
        {
          name  = "CUDL_SERVICES_XTF_URL",
          value = "https://cudl-dev.lib.cam.ac.uk/xtf/"
        },
        {
          name  = "CUDL_SERVICES_DB_HOST",
          value = "cudl-postgres.cmzjzpssbgnq.eu-west-1.rds.amazonaws.com"
        },
        {
          name  = "CUDL_SERVICES_USER_0_USERNAME",
          value = "darwin_website"
        },
        {
          name  = "CUDL_SERVICES_TEI_HTML_URL",
          value = "https://dev-transcriptions.cudl.link/"
        },
        {
          name  = "CUDL_SERVICES_XTF_INDEX_PATH",
          value = "/usr/local/indices/index-cudl"
        },
        {
          name  = "CUDL_SERVICES_USER_0_EMAIL",
          value = "cudl-admin@lib.cam.ac.uk"
        },
        {
          name  = "CUDL_SERVICES_DB_USERNAME",
          value = "cudl_viewer_dev_user_1"
        },
        {
          name  = "CUDL_SERVICES_ZACYNTHIUS_HTML_URL",
          value = "http://staging.codex-zacynthius-transcription.cudl.lib.cam.ac.uk/"
        },
        {
          name  = "CUDL_SERVICES_DATA_LOCATION",
          value = "s3://${module.cudl-data-processing.destination_bucket}/"
        }
      ],
      secrets = [
        {
          name      = "CUDL_SERVICES_DB_PASSWORD",
          valueFrom = data.aws_ssm_parameter.database_password.arn
        },
        {
          name      = "CUDL_SERVICES_USER_0_KEY",
          valueFrom = data.aws_ssm_parameter.apikey_darwin.arn
        }
      ],
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = module.base_architecture.cloudwatch_log_group_name,
          awslogs-region        = var.deployment-aws-region,
          awslogs-stream-prefix = "cudl-services-log"
        },
        secretOptions = []
      },
      healthCheck = {
        command = [
          "CMD-SHELL",
          "/opt/cudl-services/healthcheck.sh"
        ],
        interval = 30,
        timeout  = 5,
        retries  = 3
      }
    }
  ]
}