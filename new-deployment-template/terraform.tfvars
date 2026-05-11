# Institution-specific values (environment, domain, account, ECR digests, etc.)
# are in institution.auto.tfvars — that is the only file to edit for a new deployment.

project                      = "CUDL"
component                    = "cudl-data-workflows"
subcomponent                 = "cudl-transform-lambda"
destination-bucket-name      = "REPLACEME-cudl-data-releases"
transcriptions-bucket-name   = "REPLACEME-cudl-transcriptions"
source-bucket-name           = "REPLACEME-cudl-data-source"
compressed-lambdas-directory = "compressed_lambdas"

transform-lambda-bucket-sns-notifications = [
  {
    "bucket_name"   = "REPLACEME-cudl-data-source"
    "filter_prefix" = "items/data/tei/",
    "filter_suffix" = ".xml"
    "subscriptions" = [
      {
        "queue_name" = "CUDLPackageDataQueue_FILES_UNCHANGED_COPY",
        "raw"        = true
      },
      {
        "queue_name" = "CUDL_TEIProcessingQueue",
        "raw"        = true
      },
    ]
  },
  {
    "bucket_name"   = "REPLACEME-cudl-data-releases"
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
    "queue_name"    = "CUDLPackageDataQueue_HTML",
    "filter_prefix" = "pages/html/",
    "filter_suffix" = ".html"
    "bucket_name"   = "REPLACEME-cudl-data-source"
  },
  {
    "type"          = "SQS",
    "queue_name"    = "CUDLPackageDataQueue_FILES_UNCHANGED_COPY"
    "filter_prefix" = "pages/images/"
    "bucket_name"   = "REPLACEME-cudl-data-source"
  },
  {
    "type"          = "SQS",
    "queue_name"    = "CUDLPackageDataQueue_FILES_UNCHANGED_COPY"
    "filter_prefix" = "cudl.dl-dataset"
    "filter_suffix" = ".json"
    "bucket_name"   = "REPLACEME-cudl-data-source"
  },
  {
    "type"          = "SQS",
    "queue_name"    = "CUDLPackageDataQueue_FILES_UNCHANGED_COPY"
    "filter_prefix" = "cudl.ui"
    "filter_suffix" = ".json5"
    "bucket_name"   = "REPLACEME-cudl-data-source"
  },
  {
    "type"          = "SQS",
    "queue_name"    = "CUDLPackageDataQueue_Collections"
    "filter_prefix" = "collections/"
    "filter_suffix" = ".json"
    "bucket_name"   = "REPLACEME-cudl-data-source"
  },
  {
    "type"          = "SQS",
    "queue_name"    = "CUDLPackageDataQueue_FILES_UNCHANGED_COPY"
    "filter_prefix" = "ui/"
    "filter_suffix" = ""
    "bucket_name"   = "REPLACEME-cudl-data-source"
  },
  {
    "type"          = "SQS",
    "queue_name"    = "CUDLIndexQueue"
    "filter_prefix" = "solr-json/"
    "filter_suffix" = ".json"
    "bucket_name"   = "REPLACEME-cudl-data-releases"
  },
  {
    "type"          = "SQS",
    "queue_name"    = "CUDLPackageDataCopyFileToEFSQueue"
    "filter_prefix" = "cudl.dl-dataset.json"
    "filter_suffix" = ""
    "bucket_name"   = "REPLACEME-cudl-data-releases"
  },
  {
    "type"          = "SQS",
    "queue_name"    = "CUDLPackageDataCopyFileToEFSQueue"
    "filter_prefix" = "cudl.ui.json5"
    "filter_suffix" = ""
    "bucket_name"   = "REPLACEME-cudl-data-releases"
  },
  {
    "type"          = "SQS",
    "queue_name"    = "CUDLPackageDataCopyFileToEFSQueue"
    "filter_prefix" = "json/"
    "filter_suffix" = ".json"
    "bucket_name"   = "REPLACEME-cudl-data-releases"
  },
  {
    "type"          = "SQS",
    "queue_name"    = "CUDLPackageDataCopyFileToEFSQueue"
    "filter_prefix" = "pages/"
    "filter_suffix" = ""
    "bucket_name"   = "REPLACEME-cudl-data-releases"
  },
  {
    "type"          = "SQS",
    "queue_name"    = "CUDLPackageDataCopyFileToEFSQueue"
    "filter_prefix" = "ui/"
    "filter_suffix" = ""
    "bucket_name"   = "REPLACEME-cudl-data-releases"
  },
]
transform-lambda-information = [
  {
    "name"                  = "AWSLambda_CUDLPackageData_HTML_to_HTML_Translate_URLS"
    "description"           = "Processes HTML files from source data format into the releases data format by transforming the URL paths"
    "jar_path"              = "release/uk/ac/cam/lib/cudl/awslambda/AWSLambda_Data_Transform/1.0/AWSLambda_Data_Transform-1.0-jar-with-dependencies.jar"
    "queue_name"            = "CUDLPackageDataQueue_HTML"
    "subnet_names"          = ["REPLACEME-cudl-ecs-subnet-private-eu-west-1a", "REPLACEME-cudl-ecs-subnet-private-eu-west-1b"]
    "security_group_names"  = ["REPLACEME-cudl-ecs-vpc-egress"]
    "use_datadog_variables" = false
    "timeout"               = 900
    "memory"                = 512
    "handler"               = "uk.ac.cam.lib.cudl.awslambda.handlers.ConvertHTMLIdsHandler::handleRequest"
    "runtime"               = "java11"
  },
  {
    "name"                  = "AWSLambda_CUDLPackageData_FILE_UNCHANGED_COPY"
    "description"           = "Copies file from the source s3 bucket into the destination (release) s3 bucket, unchanged"
    "jar_path"              = "release/uk/ac/cam/lib/cudl/awslambda/AWSLambda_Data_Transform/1.0/AWSLambda_Data_Transform-1.0-jar-with-dependencies.jar"
    "queue_name"            = "CUDLPackageDataQueue_FILES_UNCHANGED_COPY"
    "vpc_name"              = "REPLACEME-cudl-ecs-vpc"
    "subnet_names"          = ["REPLACEME-cudl-ecs-subnet-private-eu-west-1a", "REPLACEME-cudl-ecs-subnet-private-eu-west-1b"]
    "security_group_names"  = ["REPLACEME-cudl-ecs-vpc-egress"]
    "use_datadog_variables" = false
    "timeout"               = 900
    "memory"                = 512
    "other_filters"         = "sample.dl-dataset.json|sample.ui.json"
    "handler"               = "uk.ac.cam.lib.cudl.awslambda.handlers.CopyFileHandler::handleRequest"
    "runtime"               = "java11"
  },
  {
    "name"                  = "AWSLambda_CUDLPackageData_JSON_to_JSON_Translate_URLS"
    "description"           = "Transforms the collection json file into a json format with suitable paths for the viewer / db"
    "jar_path"              = "release/uk/ac/cam/lib/cudl/awslambda/AWSLambda_Data_Transform/1.0/AWSLambda_Data_Transform-1.0-jar-with-dependencies.jar"
    "queue_name"            = "CUDLPackageDataQueue_Collections"
    "subnet_names"          = ["REPLACEME-cudl-ecs-subnet-private-eu-west-1a", "REPLACEME-cudl-ecs-subnet-private-eu-west-1b"]
    "security_group_names"  = ["REPLACEME-cudl-ecs-vpc-egress"]
    "use_datadog_variables" = false
    "timeout"               = 900
    "memory"                = 512
    "handler"               = "uk.ac.cam.lib.cudl.awslambda.handlers.ConvertJSONIdsHandler::handleRequest"
    "runtime"               = "java11"
  },
  {
    "name"                     = "AWSLambda_CUDLPackageData_TEI_Processing"
    "image_uri"                = "ACCOUNT_ID.dkr.ecr.eu-west-1.amazonaws.com/cudl/tei-processing@sha256:FIXME"
    "queue_name"               = "CUDL_TEIProcessingQueue"
    "vpc_name"                 = "REPLACEME-cudl-ecs-vpc"
    "subnet_names"             = ["REPLACEME-cudl-ecs-subnet-private-eu-west-1a", "REPLACEME-cudl-ecs-subnet-private-eu-west-1b"]
    "security_group_names"     = ["REPLACEME-cudl-ecs-vpc-egress", "REPLACEME-solr-external"]
    "timeout"                  = 300
    "memory"                   = 3000 # There is a limit of 3008 memory for new AWS acocunts
    "batch_window"             = 2
    "batch_size"               = 1
    "maximum_concurrency"      = 100
    "use_datadog_variables"    = false
    "use_additional_variables" = true
    "ephemeral_storage"        = 1024
    "environment_variables" = {
      ANT_TARGET               = "full"
      SEARCH_HOST              = "solr-api-cudl-ecs.REPLACEME-solr"
      SEARCH_PORT              = 8081
      SEARCH_COLLECTION_PATH   = "collections"
      SKIP_PAGE_XML_COPY       = "true"
      SKIP_CORE_XML_COPY       = "true"
      #SKIP_COPY_TEI_WEB_ASSETS = "true"
    }
  },
  {
    "name"                     = "AWSLambda_CUDLPackageData_SOLR_Listener"
    "image_uri"                = "ACCOUNT_ID.dkr.ecr.eu-west-1.amazonaws.com/cudl/solr-listener@sha256:FIXME"
    "queue_name"               = "CUDLIndexQueue"
    "vpc_name"                 = "REPLACEME-cudl-ecs-vpc"
    "subnet_names"             = ["REPLACEME-cudl-ecs-subnet-private-eu-west-1a", "REPLACEME-cudl-ecs-subnet-private-eu-west-1b"]
    "security_group_names"     = ["REPLACEME-cudl-ecs-vpc-egress", "REPLACEME-solr-external"]
    "timeout"                  = 180
    "memory"                   = 1024
    "batch_window"             = 2
    "batch_size"               = 1
    "maximum_concurrency"      = 2
    "use_datadog_variables"    = false
    "use_additional_variables" = true
    "environment_variables" = {
      API_HOST = "solr-api-cudl-ecs.REPLACEME-solr"
      API_PORT = "8081"
      API_PATH = "item"
    }
  },
  {
    "name"                     = "AWSLambda_CUDLPackageData_Collection_SOLR_Listener"
    "image_uri"                = "ACCOUNT_ID.dkr.ecr.eu-west-1.amazonaws.com/cudl/solr-listener@sha256:FIXME"
    "queue_name"               = "CUDLIndexCollectionQueue"
    "vpc_name"                 = "REPLACEME-cudl-ecs-vpc"
    "subnet_names"             = ["REPLACEME-cudl-ecs-subnet-private-eu-west-1a", "REPLACEME-cudl-ecs-subnet-private-eu-west-1b"]
    "security_group_names"     = ["REPLACEME-cudl-ecs-vpc-egress", "REPLACEME-solr-external"]
    "timeout"                  = 180
    "memory"                   = 1024
    "batch_window"             = 2
    "batch_size"               = 1
    "maximum_concurrency"      = 5
    "use_datadog_variables"    = false
    "use_additional_variables" = true
    "environment_variables" = {
      API_HOST = "solr-api-cudl-ecs.REPLACEME-solr"
      API_PORT = "8081"
      API_PATH = "collection"
    }
  },
  {
    "name"                           = "AWSLambda_CUDLPackageData_COPY_FILE_S3_to_EFS"
    "description"                    = "Copies file from S3 to EFS"
    "jar_path"                       = "release/uk/ac/cam/lib/cudl/awslambda/AWSLambda_Data_Transform/1.0/AWSLambda_Data_Transform-1.0-jar-with-dependencies.jar"
    "queue_name"                     = "CUDLPackageDataCopyFileToEFSQueue"
    "subnet_names"                   = ["REPLACEME-cudl-ecs-subnet-private-eu-west-1a", "REPLACEME-cudl-ecs-subnet-private-eu-west-1b"]
    "security_group_names"           = ["REPLACEME-cudl-ecs-vpc-egress", "REPLACEME-cudl-data-releases-efs"]
    "use_datadog_variables"          = false
    "mount_fs"                       = true
    "sqs_max_tries_before_deadqueue" = 1
    "timeout"                        = 900
    "memory"                         = 512
    "handler"                        = "uk.ac.cam.lib.cudl.awslambda.handlers.CopyToEFSFileHandler::handleRequest"
    "runtime"                        = "java11"
  },
]
dst-efs-prefix    = "/mnt/cudl-data-releases"
dst-prefix        = "html/"
dst-s3-prefix     = ""
tmp-dir           = "/tmp/dest/"
lambda-alias-name = "LIVE"

releases-root-directory-path               = "/data"
efs-name                                   = "cudl-data-releases-efs"
data_processing_efs_throughput_mode        = "provisioned"
data_processing_efs_provisioned_throughput = 3

# Base Architecture
cluster_name_suffix            = "cudl-ecs"
ec2_instance_type              = "t3.medium"
asg_desired_capacity           = 3 # n = number of tasks
asg_max_size                   = 4 # n + 1
asg_allow_all_egress           = true
route53_zone_force_destroy     = true
# acm_certificate_arn_us-east-1 is not set here; wildcard cert is managed in acm_wildcard_cert.tf
alb_enable_deletion_protection = false
alb_idle_timeout               = "900"
vpc_public_subnet_public_ip    = false
vpc_endpoint_services          = ["ssmmessages", "ssm", "ec2messages", "ecr.api", "ecr.dkr", "ecs", "ecs-agent", "ecs-telemetry", "logs", "elasticfilesystem", "secretsmanager"]

# Content Loader Workload
content_loader_name_suffix       = "cl"
content_loader_domain_name       = "content-loader"
content_loader_application_port  = 8081
content_loader_target_group_port = 9009
content_loader_ecs_task_def_volumes                = { "dl-loader-db" = "/var/lib/postgresql/data" }
content_loader_container_name_ui                   = "dl-loader-ui"
content_loader_container_name_db                   = "dl-loader-db"
content_loader_health_check_status_code            = "401"
content_loader_allowed_methods                     = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
content_loader_releases_bucket_production          = "production-REPLACEME-cudl-data-releases"
content_loader_waf_common_ruleset_override_actions = ["SizeRestrictions_QUERYSTRING", "SizeRestrictions_BODY", "GenericLFI_BODY", "CrossSiteScripting_BODY"]
content_loader_cloudfront_origin_read_timeout      = 60   # 180 requires a quota increase; default max is 60
content_loader_ecs_task_def_memory                 = 2700
content_loader_ecs_task_def_cpu                    = 1024

# SOLR Workload
solr_name_suffix       = "solr"
solr_domain_name       = "search"
solr_application_port  = 8983
solr_target_group_port = 8081
solr_ecs_task_def_volumes     = { "solr-volume" = "/var/solr" }
solr_container_name_api       = "solr-api"
solr_container_name_solr      = "solr"
solr_health_check_status_code = "404"
solr_allowed_methods          = ["HEAD", "GET", "OPTIONS"]
solr_ecs_task_def_cpu         = 2048
solr_use_service_discovery    = true

cudl_services_name_suffix              = "cudl-services"
cudl_services_domain_name              = "services"
cudl_services_target_group_port        = 8085
cudl_services_container_port           = 3000
cudl_services_health_check_status_code = "404"
cudl_services_ecs_task_def_memory      = 1024
cudl_services_ecs_task_def_cpu         = 512
cudl_services_allowed_methods          = ["HEAD", "GET", "OPTIONS"]

cudl_viewer_name_suffix              = "cudl-viewer"
cudl_viewer_domain_name              = "viewer"
cudl_viewer_target_group_port        = 5008
cudl_viewer_container_port           = 8080
cudl_viewer_health_check_status_code = "200"
cudl_viewer_allowed_methods                 = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"] # NOTE need to allow email feedback
cudl_viewer_ecs_task_def_volumes            = { "cudl-viewer" = "/srv/cudl-viewer/cudl-data" }
cudl_viewer_ecs_task_def_memory             = 3520

iiif_image_server_url = "https://images.lib.cam.ac.uk/iiif/"
