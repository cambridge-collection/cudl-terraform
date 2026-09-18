environment                       = "staging"
project                           = "CUDL"
component                         = "cudl-data-workflows"
subcomponent                      = "cudl-transform-lambda"
destination-bucket-name           = "cul-cudl-data-releases"
transcriptions-bucket-name        = "cul-cudl-transcriptions"
enhancements-bucket-name          = "cul-cudl-data-enhancements"
source-bucket-name                = "cul-cudl-data-source"
compressed-lambdas-directory      = "compressed_lambdas"
lambda-jar-bucket                 = "cul-cudl.mvn.cudl.lib.cam.ac.uk"
enable_ark_workflow               = true
tei_processing_forward_queue_name = "CUDL_TEIProcessingForwardQueue"
tei_ark_ingestion_queue_name      = "CUDL_TEIArkIngestionQueue"

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
  },
  {
    "bucket_name"   = "cul-cudl-data-releases"
    "filter_prefix" = "unreleased/collections/",
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
    "bucket_name"   = "cul-cudl-data-source"
  },
  {
    "type"          = "SQS",
    "queue_name"    = "CUDLPackageDataQueue_FILES_UNCHANGED_COPY"
    "filter_prefix" = "pages/images/"
    "bucket_name"   = "cul-cudl-data-source"
  },
  {
    "type"          = "SQS",
    "queue_name"    = "CUDLPackageDataQueue_FILES_UNCHANGED_COPY"
    "filter_prefix" = "cudl.dl-dataset"
    "filter_suffix" = ".json"
    "bucket_name"   = "cul-cudl-data-source"
  },
  {
    "type"          = "SQS",
    "queue_name"    = "CUDLPackageDataQueue_FILES_UNCHANGED_COPY"
    "filter_prefix" = "cudl.ui"
    "filter_suffix" = ".json5"
    "bucket_name"   = "cul-cudl-data-source"
  },
  {
    "type"          = "SQS",
    "queue_name"    = "CUDLPackageDataQueue_Collections"
    "filter_prefix" = "collections/"
    "filter_suffix" = ".json"
    "bucket_name"   = "cul-cudl-data-source"
  },
  {
    "type"          = "SQS",
    "queue_name"    = "CUDLPackageDataQueue_FILES_UNCHANGED_COPY"
    "filter_prefix" = "ui/"
    "filter_suffix" = ""
    "bucket_name"   = "cul-cudl-data-source"
  },
  {
    "type"          = "SQS",
    "queue_name"    = "CUDLPackageDataQueue_UI_TEI_ASSETS_COPY"
    "filter_prefix" = "tei-assets/"
    "filter_suffix" = ""
    "bucket_name"   = "cul-cudl-data-source"
  },
  {
    "type"          = "SQS",
    "queue_name"    = "CUDLIndexQueue"
    "filter_prefix" = "solr-json/"
    "filter_suffix" = ".json"
    "bucket_name"   = "cul-cudl-data-releases"
  },
  {
    "type"          = "SQS",
    "queue_name"    = "CUDLIndexQueue"
    "filter_prefix" = "unreleased/solr-json/"
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
    "filter_prefix" = "unreleased/json/"
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
  },
  {
    "type"          = "SQS",
    "queue_name"    = "CUDL_Transkribus_IngestQueue"
    "filter_prefix" = "transkribus/curious-cures/"
    "filter_suffix" = ".xml"
    "bucket_name"   = "cul-cudl-data-enhancements"
  },
  {
    "type"          = "SQS",
    "queue_name"    = "CUDL_TEIArkIngestionQueue"
    "filter_prefix" = "items/data/tei/"
    "filter_suffix" = ".xml"
    "bucket_name"   = "cul-cudl-data-source"
  }
]
transform-lambda-information = [
  {
    "name"                           = "AWSLambda_CUDLPackageData_HTML_to_HTML_Translate_URLS"
    "description"                    = "Processes HTML files from source data format into the releases data format by transforming the URL paths"
    "image_uri"                      = "438117829123.dkr.ecr.eu-west-1.amazonaws.com/cudl/data-transmogrifier@sha256:6f17655e7ea9c06f92113a42f4b6f62b978df49c33ca90acb486a4fd652d1336"
    "queue_name"                     = "CUDLPackageDataQueue_HTML"
    "subnet_names"                   = ["staging-cudl-ecs-subnet-private-eu-west-1a", "staging-cudl-ecs-subnet-private-eu-west-1b"]
    "security_group_names"           = ["staging-cudl-ecs-vpc-egress"]
    "timeout"                        = 60
    "memory"                         = 256
    "batch_window"                   = 0
    "batch_size"                     = 1
    "sqs_max_tries_before_deadqueue" = 3
    "use_datadog_variables"          = false
    "function_response_types"        = ["ReportBatchItemFailures"]
    "environment_variables" = {
      DEST_BUCKET = "staging-cul-cudl-data-releases"
      TRANSFORM   = "html"
    }
  },
  {
    "name"                           = "AWSLambda_CUDLPackageData_FILE_UNCHANGED_COPY"
    "description"                    = "Copies files verbatim from the source bucket to the releases bucket (identity copy)"
    "image_uri"                      = "438117829123.dkr.ecr.eu-west-1.amazonaws.com/cudl/s3-replicator@sha256:4db60990316e63307a3fb557649e7ce8c898dadef82aec653310f900e71a8663"
    "queue_name"                     = "CUDLPackageDataQueue_FILES_UNCHANGED_COPY"
    "vpc_name"                       = "staging-cudl-ecs-vpc"
    "subnet_names"                   = ["staging-cudl-ecs-subnet-private-eu-west-1a", "staging-cudl-ecs-subnet-private-eu-west-1b"]
    "security_group_names"           = ["staging-cudl-ecs-vpc-egress"]
    "timeout"                        = 60
    "memory"                         = 256
    "batch_window"                   = 0
    "batch_size"                     = 1
    "sqs_max_tries_before_deadqueue" = 3
    "use_datadog_variables"          = false
    "function_response_types"        = ["ReportBatchItemFailures"]
    "environment_variables" = {
      DEST_BUCKET = "staging-cul-cudl-data-releases"
    }
  },
  {
    "name"                           = "AWSLambda_CUDLPackageData_JSON_to_JSON_Translate_URLS"
    "description"                    = "Transforms the collection json file into a json format with suitable paths for the viewer / db"
    "image_uri"                      = "438117829123.dkr.ecr.eu-west-1.amazonaws.com/cudl/data-transmogrifier@sha256:6f17655e7ea9c06f92113a42f4b6f62b978df49c33ca90acb486a4fd652d1336"
    "queue_name"                     = "CUDLPackageDataQueue_Collections"
    "subnet_names"                   = ["staging-cudl-ecs-subnet-private-eu-west-1a", "staging-cudl-ecs-subnet-private-eu-west-1b"]
    "security_group_names"           = ["staging-cudl-ecs-vpc-egress"]
    "timeout"                        = 60
    "memory"                         = 512
    "batch_window"                   = 0
    "batch_size"                     = 1
    "sqs_max_tries_before_deadqueue" = 3
    "use_datadog_variables"          = false
    "function_response_types"        = ["ReportBatchItemFailures"]
    "environment_variables" = {
      DEST_BUCKET            = "staging-cul-cudl-data-releases"
      TRANSFORM              = "json"
      DST_XSLT_OUTPUT_FOLDER = "json/"
      DST_XSLT_OUTPUT_SUFFIX = ".json"
    }
  },
  {
    "name"                     = "AWSLambda_CUDLPackageData_TEI_Processing"
    "image_uri"                = "438117829123.dkr.ecr.eu-west-1.amazonaws.com/cudl/tei-processing@sha256:6fb3d81a1563556edc7bd1b174136ff7e033f616a4003017a9ddf0c9533e95cc"
    "queue_name"               = "CUDL_TEIProcessingForwardQueue"
    "vpc_name"                 = "staging-cudl-ecs-vpc"
    "subnet_names"             = ["staging-cudl-ecs-subnet-private-eu-west-1a", "staging-cudl-ecs-subnet-private-eu-west-1b"]
    "security_group_names"     = ["staging-cudl-ecs-vpc-egress", "staging-solr-external"]
    "timeout"                  = 300
    "memory"                   = 4096
    "batch_window"             = 2
    "batch_size"               = 1
    "maximum_concurrency"      = 50
    "use_datadog_variables"    = false
    "use_additional_variables" = true
    "ephemeral_storage"        = 1024
    "environment_variables" = {
      ANT_TARGET                     = "full"
      SEARCH_HOST                    = "solr-api-cudl-ecs.staging-solr"
      SEARCH_PORT                    = 8081
      SEARCH_COLLECTION_PATH         = "collections"
      SKIP_COPY_TEI_WEB_ASSETS       = "true"
      SKIP_PAGE_XML_COPY             = "true"
      SKIP_CORE_XML_COPY             = "true"
      SKIP_TEI_FULL_COPY             = "false"
      EMIT_EMF_METRICS               = "false"
      LAMBDA_TIMEOUT_MARGIN_MS       = 180000
      ENABLE_SHA_METADATA            = "true"
      ENABLE_RELEASE_STATUS_METADATA = "true"
      ENABLE_TEI_SHA_IN_CORE_XML     = "true"
      ENABLE_UNRELEASED_PARTITION    = "TRUE"
      LOG_LEVEL                      = "INFO"

    }
  },
  {
    "name"                     = "AWSLambda_CUDLPackageData_SOLR_Listener"
    "image_uri"                = "438117829123.dkr.ecr.eu-west-1.amazonaws.com/cudl/solr-listener@sha256:402837f03848d9c55645a3437e062362b18aaaf812dcc54e931a90a586fbda5e"
    "queue_name"               = "CUDLIndexQueue"
    "vpc_name"                 = "staging-cudl-ecs-vpc"
    "subnet_names"             = ["staging-cudl-ecs-subnet-private-eu-west-1a", "staging-cudl-ecs-subnet-private-eu-west-1b"]
    "security_group_names"     = ["staging-cudl-ecs-vpc-egress", "staging-solr-external"]
    "timeout"                  = 180
    "memory"                   = 1024
    "batch_window"             = 2
    "batch_size"               = 1
    "maximum_concurrency"      = 2
    "use_datadog_variables"    = false
    "use_additional_variables" = true
    "environment_variables" = {
      API_HOST             = "solr-api-cudl-ecs.staging-solr"
      API_PORT             = "8081"
      API_PATH             = "item"
      LOG_LEVEL            = "INFO"
      RELEASES_PARTITIONED = "TRUE"
    }
  },
  {
    "name"                     = "AWSLambda_CUDLPackageData_Collection_SOLR_Listener"
    "image_uri"                = "438117829123.dkr.ecr.eu-west-1.amazonaws.com/cudl/solr-listener@sha256:402837f03848d9c55645a3437e062362b18aaaf812dcc54e931a90a586fbda5e"
    "queue_name"               = "CUDLIndexCollectionQueue"
    "vpc_name"                 = "staging-cudl-ecs-vpc"
    "subnet_names"             = ["staging-cudl-ecs-subnet-private-eu-west-1a", "staging-cudl-ecs-subnet-private-eu-west-1b"]
    "security_group_names"     = ["staging-cudl-ecs-vpc-egress", "staging-solr-external"]
    "timeout"                  = 180
    "memory"                   = 1024
    "batch_window"             = 2
    "batch_size"               = 1
    "maximum_concurrency"      = 5
    "use_datadog_variables"    = false
    "use_additional_variables" = true
    "environment_variables" = {
      API_HOST             = "solr-api-cudl-ecs.staging-solr"
      API_PORT             = "8081"
      API_PATH             = "collection"
      LOG_LEVEL            = "INFO"
      RELEASES_PARTITIONED = "TRUE"
    }
  },
  {
    "name"                           = "AWSLambda_CUDLPackageData_COPY_FILE_S3_to_EFS"
    "description"                    = "Copies files verbatim from the releases bucket to the EFS mount"
    "image_uri"                      = "438117829123.dkr.ecr.eu-west-1.amazonaws.com/cudl/efs-copier@sha256:50eaeb6fea6158e1d186e786dc438e0a286944396f60e3f114bc6ca43df6afaf"
    "queue_name"                     = "CUDLPackageDataCopyFileToEFSQueue"
    "subnet_names"                   = ["staging-cudl-ecs-subnet-private-eu-west-1a", "staging-cudl-ecs-subnet-private-eu-west-1b"]
    "security_group_names"           = ["staging-cudl-ecs-vpc-egress", "staging-cudl-data-releases-efs"]
    "use_datadog_variables"          = false
    "mount_fs"                       = true
    "timeout"                        = 900
    "memory"                         = 512
    "sqs_max_tries_before_deadqueue" = 3
    "function_response_types"        = ["ReportBatchItemFailures"]
    "environment_variables" = {
      DST_EFS_PREFIX  = "/mnt/cudl-data-releases"
      DST_EFS_ENABLED = "true"
      LOG_LEVEL       = "INFO"
    }
  },
  {
    "name"                       = "AWSLambda_CUDL_Transkribus_Ingest"
    "image_uri"                  = "438117829123.dkr.ecr.eu-west-1.amazonaws.com/cudl/transkribus-processing@sha256:03cf5047a7ddd72163edc8081e7cfad652c6072daa91d0ab941fc96b4d481a40"
    "queue_name"                 = "CUDL_Transkribus_IngestQueue"
    "vpc_name"                   = "staging-cudl-ecs-vpc"
    "subnet_names"               = ["staging-cudl-ecs-subnet-private-eu-west-1a", "staging-cudl-ecs-subnet-private-eu-west-1b"]
    "security_group_names"       = ["staging-cudl-ecs-vpc-egress"]
    "timeout"                    = 300
    "memory"                     = 4096
    "batch_window"               = 2
    "batch_size"                 = 1
    "maximum_concurrency"        = 100
    "use_datadog_variables"      = false
    "use_additional_variables"   = false
    "use_enhancements_variables" = true
    "environment_variables" = {
      ANT_TARGET                = "full"
      ANT_BUILDFILE             = "bin/build.xml"
      XSLT_ENTRYPOINT           = "xslt/curious-cures.xsl"
      OUTPUT_EXTENSION          = "xml"
      EXPAND_DEFAULT_ATTRIBUTES = false
      ALLOW_DELETE              = false
    }
  },
  {
    "name"                           = "cudl-copy-tei-assets"
    "image_uri"                      = "438117829123.dkr.ecr.eu-west-1.amazonaws.com/cudl/s3-replicator@sha256:4db60990316e63307a3fb557649e7ce8c898dadef82aec653310f900e71a8663"
    "queue_name"                     = "CUDLPackageDataQueue_UI_TEI_ASSETS_COPY"
    "subnet_names"                   = ["staging-cudl-ecs-subnet-private-eu-west-1a", "staging-cudl-ecs-subnet-private-eu-west-1b"]
    "security_group_names"           = ["staging-cudl-ecs-vpc-egress"]
    "timeout"                        = 60
    "memory"                         = 256
    "batch_window"                   = 0
    "batch_size"                     = 1
    "sqs_max_tries_before_deadqueue" = 3
    "use_datadog_variables"          = false
    "function_response_types"        = ["ReportBatchItemFailures"]
    "environment_variables" = {
      DEST_BUCKET   = "staging-cul-cudl-data-releases"
      SOURCE_PREFIX = "tei-assets/"
      DEST_PREFIX   = "html/cudl-resources/"
    }
  },
  {
    "name"                     = "AWSLambda_CUDL_ARK_Ingestion"
    "image_uri"                = "438117829123.dkr.ecr.eu-west-1.amazonaws.com/cudl/pid-minting@sha256:9ae349c86bc7ac998e71ebf71e6cc112f7d1d9b40cdcee807d75796b86536741" # VERIFY
    "queue_name"               = "CUDL_TEIArkIngestionQueue"
    "vpc_name"                 = "staging-cudl-ecs-vpc"
    "subnet_names"             = ["staging-cudl-ecs-subnet-private-eu-west-1a", "staging-cudl-ecs-subnet-private-eu-west-1b"]
    "security_group_names"     = ["staging-cudl-ecs-vpc-egress", "staging-solr-external"]
    "timeout"                  = 300
    "memory"                   = 4096
    "batch_window"             = 2
    "batch_size"               = 1
    "maximum_concurrency"      = 50
    "use_datadog_variables"    = false
    "use_additional_variables" = false
    "ephemeral_storage"        = 1024
    "environment_variables" = {
      PID_LOG_LEVEL           = "INFO"
      PID_FORWARD_QUEUE_URL   = "https://sqs.eu-west-1.amazonaws.com/438117829123/staging-CUDL_TEIProcessingForwardQueue" #VERIFY
      PID_PIPELINE_SECRET_ARN = "arn:aws:secretsmanager:eu-west-1:438117829123:secret:staging/cudl/pid-pipeline-nD9nmb"   #VERIFY
    }
  }
]
dst-efs-prefix = "/mnt/cudl-data-releases"
dst-prefix     = "html/"
dst-s3-prefix  = ""
tmp-dir        = "/tmp/dest/"

releases-root-directory-path               = "/data"
efs-name                                   = "cudl-data-releases-efs"
cloudfront_route53_zone_id                 = "Z03809063VDGJ8MKPHFRV"
data_processing_efs_throughput_mode        = "provisioned"
data_processing_efs_provisioned_throughput = 3


# Base Architecture
cluster_name_suffix            = "cudl-ecs"
registered_domain_name         = "cudl.lib.cam.ac.uk."
ec2_instance_type              = "t3.medium"
asg_desired_capacity           = 4 # n = number of tasks
asg_max_size                   = 5 # n + 1
asg_allow_all_egress           = true
route53_zone_id_existing       = "Z03809063VDGJ8MKPHFRV"
route53_zone_force_destroy     = true
acm_certificate_arn            = "arn:aws:acm:eu-west-1:438117829123:certificate/5a38d7e0-b903-4cbe-bc35-ebf41f4bddd1"
acm_certificate_arn_us-east-1  = "arn:aws:acm:us-east-1:438117829123:certificate/3dd73bf2-740b-4c67-b6c5-2b4af4492a16"
alb_enable_deletion_protection = false
alb_idle_timeout               = "900"
vpc_cidr_block                 = "10.88.0.0/22" #1024 adresses
vpc_public_subnet_public_ip    = false
cloudwatch_log_group           = "/ecs/CUDL-Staging"
cloudwatch_log_destination_arn = "arn:aws:logs:eu-west-1:874581676011:destination:cul-logs-cloudwatch-log-destination"
vpc_endpoint_services          = ["ssmmessages", "ssm", "ec2messages", "ecr.api", "ecr.dkr", "ecs", "ecs-agent", "ecs-telemetry", "logs", "elasticfilesystem", "secretsmanager"]

# Content Loader Workload
content_loader_name_suffix       = "cl"
content_loader_domain_name       = "content-loader"
content_loader_application_port  = 8081
content_loader_target_group_port = 9009
content_loader_ecr_repositories = {
  "cudl/content-loader-db" = "sha256:56081ed5d1876b190c9b15d150d8512477e4baeb9f874e93c4250cd29097d066",
  "cudl/content-loader-ui" = "sha256:73e819ebeef099f84ad2fdb8cef0eeacea94a0a0cf7511ea50c2bad7de5c6a51"
}
content_loader_ecs_task_def_volumes                = { "dl-loader-db" = "/var/lib/postgresql/data" }
content_loader_container_name_ui                   = "dl-loader-ui"
content_loader_container_name_db                   = "dl-loader-db"
content_loader_health_check_status_code            = "401"
content_loader_allowed_methods                     = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
content_loader_releases_bucket_production          = "production-cul-cudl-data-releases"
content_loader_waf_common_ruleset_override_actions = ["SizeRestrictions_QUERYSTRING", "SizeRestrictions_BODY", "GenericLFI_BODY", "CrossSiteScripting_BODY"]
content_loader_cloudfront_origin_read_timeout      = 180
content_loader_ecs_task_def_memory                 = 3000

# SOLR Worload
solr_name_suffix       = "solr"
solr_domain_name       = "search"
solr_application_port  = 8983
solr_target_group_port = 8081
solr_ecr_repositories = {
  "cudl/solr-api" = "sha256:7f25aa28700724d63618c50c7c5fe7b64892748a8ae9abf9e6c96f0200a69e27",
  "cudl/solr"     = "sha256:76966d3d7cfae08f0693f53eb2a09209dc669f060c9273810ad00614b82d4106"
}
solr_ecs_task_def_volumes     = { "solr-volume" = "/var/solr" }
solr_container_name_api       = "solr-api"
solr_container_name_solr      = "solr"
solr_health_check_status_code = "404"
solr_allowed_methods          = ["HEAD", "GET", "OPTIONS"]
solr_ecs_task_def_cpu         = 2048
solr_use_service_discovery    = true

cudl_services_name_suffix       = "cudl-services"
cudl_services_domain_name       = "services"
cudl_services_target_group_port = 8085
cudl_services_container_port    = 3000
cudl_services_ecr_repositories = {
  "cudl/services" = "sha256:7742e6781a774e3f9bab833b8dbb1714de30a8bce1d86d9868d1171e8fcf464a"
}
cudl_services_health_check_status_code = "404"
cudl_services_allowed_methods          = ["HEAD", "GET", "OPTIONS"]

cudl_viewer_name_suffix       = "cudl-viewer"
cudl_viewer_domain_name       = "viewer"
cudl_viewer_target_group_port = 5008
cudl_viewer_container_port    = 8080
cudl_viewer_ecr_repositories = {
  "cudl/viewer" = "sha256:66ecbb1118cc7ea178ef5e1034d50a298e94cb98bd1953b7763009566894ae44"
}
cudl_viewer_health_check_status_code        = "200"
cudl_viewer_allowed_methods                 = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"] # NOTE need to allow email feedback
cudl_viewer_ecs_task_def_volumes            = { "cudl-viewer" = "/srv/cudl-viewer/cudl-data" }
cudl_viewer_datasync_task_s3_to_efs_pattern = "/json/*|/pages/*|/cudl.dl-dataset.json|/cudl.ui.json5|/collections/*|/ui/*"
cudl_viewer_ecs_task_def_memory             = 3520

rti_image_server_name_suffix                             = "cul"
rti_image_server_bucket                                  = "cudl-rti-images"
rti_image_server_domain_name                             = "staging-rti-images.cudl.lib.cam.ac.uk"
rti_image_server_hosted_zone_domain                      = "cudl.lib.cam.ac.uk"
rti_image_server_route53_zone_id_existing                = "Z03809063VDGJ8MKPHFRV"
rti_image_server_cloudfront_viewer_response_function_arn = "arn:aws:cloudfront::438117829123:function/staging-cudl-add-cors-response"
rti_image_server_cloudfront_cache_policy                 = "optimized"
rti_image_server_cloudfront_origin_request_policy_name   = "Managed-CORS-S3Origin"
rti_image_server_cloudfront_response_headers_policy_name = "Managed-CORS-With-Preflight"
