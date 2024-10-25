environment                  = "production"
project                      = "CUDL"
component                    = "cudl-data-workflows"
subcomponent                 = "cudl-transform-lambda"
destination-bucket-name      = "cul-cudl-data-releases"
transcriptions-bucket-name   = "cul-cudl-transcriptions"
enhancements-bucket-name     = "cul-cudl-data-enhancements"
source-bucket-name           = "cul-cudl-data-source"
compressed-lambdas-directory = "compressed_lambdas"
lambda-jar-bucket            = "cul-cudl.mvn.cudl.lib.cam.ac.uk"

transform-lambda-bucket-sns-notifications = [
  {
    "bucket_name"   = "cul-cudl-data-releases"
    "filter_prefix" = "collections/",
    "filter_suffix" = ".json"
    "subscriptions" = [
      {
        "queue_name" = "CUDLIndexCollectionQueue",
        "raw"        = true
      },
      {
        "queue_name" = "CUDLPackageDataCopyFileToEFSQueue",
        "raw"        = true
      }
    ]
  }
]
transform-lambda-bucket-sqs-notifications = [
  {
    "type"          = "SQS",
    "queue_name"    = "CUDLIndexQueue"
    "filter_prefix" = "solr-json/"
    "filter_suffix" = ".json"
    "bucket_name"   = "cul-cudl-data-releases"
  },
  {
    "type"          = "SQS",
    "queue_name"    = "CUDLPackageDataCopyFileToEFSQueue"
    "filter_prefix" = "cudl.dl-dataset.json"
    "filter_suffix" = ""
    "bucket_name"   = "cul-cudl-data-releases"
  },
  {
    "type"          = "SQS",
    "queue_name"    = "CUDLPackageDataCopyFileToEFSQueue"
    "filter_prefix" = "cudl.ui.json5"
    "filter_suffix" = ""
    "bucket_name"   = "cul-cudl-data-releases"
  },
  {
    "type"          = "SQS",
    "queue_name"    = "CUDLPackageDataCopyFileToEFSQueue"
    "filter_prefix" = "json/"
    "filter_suffix" = ".json"
    "bucket_name"   = "cul-cudl-data-releases"
  },
  {
    "type"          = "SQS",
    "queue_name"    = "CUDLPackageDataCopyFileToEFSQueue"
    "filter_prefix" = "pages/"
    "filter_suffix" = ""
    "bucket_name"   = "cul-cudl-data-releases"
  },
  {
    "type"          = "SQS",
    "queue_name"    = "CUDLPackageDataCopyFileToEFSQueue"
    "filter_prefix" = "ui/"
    "filter_suffix" = ""
    "bucket_name"   = "cul-cudl-data-releases"
  }
]
transform-lambda-information = [
  {
    "name"                     = "AWSLambda_CUDLPackageData_SOLR_Listener"
    "image_uri"                = "438117829123.dkr.ecr.eu-west-1.amazonaws.com/cudl/solr-listener@sha256:88795e469457966c06f62e55c1c217bef3b5fb92c35589bac4a5be735c631689"
    "queue_name"               = "CUDLIndexQueue"
    "queue_delay_seconds"      = 10
    "vpc_name"                 = "production-cudl-ecs-vpc"
    "subnet_names"             = ["production-cudl-ecs-subnet-private-a", "production-cudl-ecs-subnet-private-b"]
    "security_group_names"     = ["production-cudl-ecs-vpc-egress", "production-solr-external"]
    "timeout"                  = 180
    "memory"                   = 1024
    "batch_window"             = 2
    "batch_size"               = 1
    "maximum_concurrency"      = 5
    "use_datadog_variables"    = false
    "use_additional_variables" = true
    "environment_variables" = {
      API_HOST = "solr-api-cudl-ecs.production-solr"
      API_PORT = "8081"
      API_PATH = "item"
    }
  },
  {
    "name"                     = "AWSLambda_CUDLPackageData_Collection_SOLR_Listener"
    "image_uri"                = "438117829123.dkr.ecr.eu-west-1.amazonaws.com/cudl/solr-listener@sha256:88795e469457966c06f62e55c1c217bef3b5fb92c35589bac4a5be735c631689"
    "queue_name"               = "CUDLIndexCollectionQueue"
    "vpc_name"                 = "production-cudl-ecs-vpc"
    "subnet_names"             = ["production-cudl-ecs-subnet-private-a", "production-cudl-ecs-subnet-private-b"]
    "security_group_names"     = ["production-cudl-ecs-vpc-egress", "production-solr-external"]
    "timeout"                  = 180
    "memory"                   = 1024
    "batch_window"             = 2
    "batch_size"               = 1
    "maximum_concurrency"      = 5
    "use_datadog_variables"    = false
    "use_additional_variables" = true
    "environment_variables" = {
      API_HOST = "solr-api-cudl-ecs.production-solr"
      API_PORT = "8081"
      API_PATH = "collection"
    }
  },
  {
    "name"                  = "AWSLambda_CUDLPackageData_COPY_FILE_S3_to_EFS"
    "description"           = "Copies file from S3 to EFS"
    "jar_path"              = "release/uk/ac/cam/lib/cudl/awslambda/AWSLambda_Data_Transform/1.0/AWSLambda_Data_Transform-1.0-jar-with-dependencies.jar"
    "queue_name"            = "CUDLPackageDataCopyFileToEFSQueue"
    "subnet_names"          = ["production-cudl-ecs-subnet-private-a", "production-cudl-ecs-subnet-private-b"]
    "security_group_names"  = ["production-cudl-ecs-vpc-egress", "production-cudl-data-releases-efs"]
    "use_datadog_variables" = false
    "mount_fs"              = true
    "timeout"               = 900
    "memory"                = 512
    "handler"               = "uk.ac.cam.lib.cudl.awslambda.handlers.CopyToEFSFileHandler::handleRequest"
    "runtime"               = "java11"
  }
]
dst-efs-prefix    = "/mnt/cudl-data-releases"
dst-prefix        = "html/"
dst-s3-prefix     = ""
tmp-dir           = "/tmp/dest/"
lambda-alias-name = "LIVE"

releases-root-directory-path = "/data"
efs-name                     = "cudl-data-releases-efs"
cloudfront_route53_zone_id   = "Z03809063VDGJ8MKPHFRV"

# Base Architecture
cluster_name_suffix            = "cudl-ecs"
registered_domain_name         = "cudl.lib.cam.ac.uk."
asg_desired_capacity           = 3 # n = number of tasks
asg_max_size                   = 4 # n + 1
asg_allow_all_egress           = true
route53_zone_id_existing       = "Z03809063VDGJ8MKPHFRV"
route53_zone_force_destroy     = true
acm_certificate_arn            = "arn:aws:acm:eu-west-1:438117829123:certificate/fec4f8c7-8c2d-4274-abc4-a6fa3f65583f"
acm_certificate_arn_us-east-1  = "arn:aws:acm:us-east-1:438117829123:certificate/3ebbcb94-1cf1-4adf-832f-add73eaea151"
alb_enable_deletion_protection = false
vpc_cidr_block                 = "10.27.0.0/22" #1024 adresses
vpc_public_subnet_public_ip    = false
cloudwatch_log_group           = "/ecs/CUDL"

# SOLR Worload
solr_name_suffix       = "solr"
solr_domain_name       = "search"
solr_application_port  = 8983
solr_target_group_port = 8081
solr_ecr_repositories = {
  "cudl/solr-api" = "sha256:2892d0023e4014ad569121551b8b959cd32f5c6658e671973bcfc783836bf65f",
  "cudl/solr"     = "sha256:8dfcce2322e381d92bc02d19710afa8ec15e5a8f6c1efa1edddf550527c51fdb"
}
solr_ecs_task_def_volumes     = { "solr-volume" = "/var/solr" }
solr_container_name_api       = "solr-api"
solr_container_name_solr      = "solr"
solr_health_check_status_code = "404"
solr_allowed_methods          = ["HEAD", "GET", "OPTIONS"]
solr_ecs_task_def_cpu         = 1536
solr_ecs_task_def_memory      = 1638
solr_use_service_discovery    = true

cudl_services_name_suffix       = "cudl-services"
cudl_services_domain_name       = "services"
cudl_services_target_group_port = 8085
cudl_services_container_port    = 3000
cudl_services_ecr_repositories = {
  "cudl/services" = "sha256:98b7ee01cca8c1093d3d719d13640db9f9d7e2439933d847a63e733d96f4660e"
}
cudl_services_health_check_status_code = "404"
cudl_services_allowed_methods          = ["HEAD", "GET", "OPTIONS"]

cudl_viewer_name_suffix       = "cudl-viewer"
cudl_viewer_domain_name       = "viewer"
cudl_viewer_target_group_port = 5008
cudl_viewer_container_port    = 8080
cudl_viewer_ecr_repositories = {
  "cudl/viewer" = "sha256:19fdc50eb01e5c7e2baa70c21dca0ca410ac8c1f4335a68a2145e89dee1dfb86"
}
cudl_viewer_health_check_status_code        = "200"
cudl_viewer_allowed_methods                 = ["HEAD", "GET", "OPTIONS"]
cudl_viewer_ecs_task_def_volumes            = { "cudl-viewer" = "/srv/cudl-viewer/cudl-data" }
cudl_viewer_datasync_task_s3_to_efs_pattern = "/json/*|/pages/*|/cudl.dl-dataset.json|/cudl.ui.json5|/collections/*|/ui/*"
cudl_viewer_alternative_domain_names        = ["cudl.lib.cam.ac.uk"]
cudl_viewer_ecs_task_def_memory             = 1920
