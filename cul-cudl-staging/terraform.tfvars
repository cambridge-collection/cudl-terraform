environment                  = "staging"
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
    "bucket_name"   = "cul-cudl-data-source"
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
  },
  {
    "type"          = "SQS",
    "queue_name"    = "CUDL_Transkribus_IngestQueue"
    "filter_prefix" = "transkribus/curious-cures/"
    "filter_suffix" = ".xml"
    "bucket_name"   = "cul-cudl-data-enhancements"
  }
]
transform-lambda-information = [
  {
    "name"                  = "AWSLambda_CUDLPackageData_HTML_to_HTML_Translate_URLS"
    "description"           = "Processes HTML files from source data format into the releases data format by transforming the URL paths"
    "jar_path"              = "release/uk/ac/cam/lib/cudl/awslambda/AWSLambda_Data_Transform/1.0/AWSLambda_Data_Transform-1.0-jar-with-dependencies.jar"
    "queue_name"            = "CUDLPackageDataQueue_HTML"
    "subnet_names"          = ["staging-cudl-ecs-subnet-private-a", "staging-cudl-ecs-subnet-private-b"]
    "security_group_names"  = ["staging-cudl-ecs-vpc-egress"]
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
    "vpc_name"              = "staging-cudl-ecs-vpc"
    "subnet_names"          = ["staging-cudl-ecs-subnet-private-a", "staging-cudl-ecs-subnet-private-b"]
    "security_group_names"  = ["staging-cudl-ecs-vpc-egress"]
    "use_datadog_variables" = false
    "timeout"               = 900
    "memory"                = 512
    "other_filters"         = "cudl.dl-dataset.json|cudl.ui.json"
    "handler"               = "uk.ac.cam.lib.cudl.awslambda.handlers.CopyFileHandler::handleRequest"
    "runtime"               = "java11"
  },
  {
    "name"                  = "AWSLambda_CUDLPackageData_JSON_to_JSON_Translate_URLS"
    "description"           = "Transforms the collection json file into a json format with suitable paths for the viewer / db"
    "jar_path"              = "release/uk/ac/cam/lib/cudl/awslambda/AWSLambda_Data_Transform/1.0/AWSLambda_Data_Transform-1.0-jar-with-dependencies.jar"
    "queue_name"            = "CUDLPackageDataQueue_Collections"
    "subnet_names"          = ["staging-cudl-ecs-subnet-private-a", "staging-cudl-ecs-subnet-private-b"]
    "security_group_names"  = ["staging-cudl-ecs-vpc-egress"]
    "use_datadog_variables" = false
    "timeout"               = 900
    "memory"                = 512
    "handler"               = "uk.ac.cam.lib.cudl.awslambda.handlers.ConvertJSONIdsHandler::handleRequest"
    "runtime"               = "java11"
  },
  {
    "name"                     = "AWSLambda_CUDLPackageData_TEI_Processing"
    "image_uri"                = "438117829123.dkr.ecr.eu-west-1.amazonaws.com/cudl/tei-processing@sha256:b2ee8fb7419e5060373b48cc6dbea8a54669f813f623401605d88028341bcba1"
    "queue_name"               = "CUDL_TEIProcessingQueue"
    "vpc_name"                 = "staging-cudl-ecs-vpc"
    "subnet_names"             = ["staging-cudl-ecs-subnet-private-a", "staging-cudl-ecs-subnet-private-b"]
    "security_group_names"     = ["staging-cudl-ecs-vpc-egress", "staging-solr-external"]
    "timeout"                  = 300
    "memory"                   = 4096
    "batch_window"             = 2
    "batch_size"               = 1
    "maximum_concurrency"      = 100
    "use_datadog_variables"    = false
    "use_additional_variables" = true
    "ephemeral_storage"        = 1024
    "environment_variables" = {
      ANT_TARGET             = "full"
      SEARCH_HOST            = "solr-api-cudl-ecs.staging-solr"
      SEARCH_PORT            = 8081
      SEARCH_COLLECTION_PATH = "collections"
    }
  },
  {
    "name"                     = "AWSLambda_CUDLPackageData_SOLR_Listener"
    "image_uri"                = "438117829123.dkr.ecr.eu-west-1.amazonaws.com/cudl/solr-listener@sha256:40246a8a291b1e87113b4af7ab5167115e8d3f8015b6409db42a20fda3992403"
    "queue_name"               = "CUDLIndexQueue"
    "vpc_name"                 = "staging-cudl-ecs-vpc"
    "subnet_names"             = ["staging-cudl-ecs-subnet-private-a", "staging-cudl-ecs-subnet-private-b"]
    "security_group_names"     = ["staging-cudl-ecs-vpc-egress", "staging-solr-external"]
    "timeout"                  = 180
    "memory"                   = 1024
    "batch_window"             = 2
    "batch_size"               = 1
    "maximum_concurrency"      = 2
    "use_datadog_variables"    = false
    "use_additional_variables" = true
    "environment_variables" = {
      API_HOST = "solr-api-cudl-ecs.staging-solr"
      API_PORT = "8081"
      API_PATH = "item"
    }
  },
  {
    "name"                     = "AWSLambda_CUDLPackageData_Collection_SOLR_Listener"
    "image_uri"                = "438117829123.dkr.ecr.eu-west-1.amazonaws.com/cudl/solr-listener@sha256:40246a8a291b1e87113b4af7ab5167115e8d3f8015b6409db42a20fda3992403"
    "queue_name"               = "CUDLIndexCollectionQueue"
    "vpc_name"                 = "staging-cudl-ecs-vpc"
    "subnet_names"             = ["staging-cudl-ecs-subnet-private-a", "staging-cudl-ecs-subnet-private-b"]
    "security_group_names"     = ["staging-cudl-ecs-vpc-egress", "staging-solr-external"]
    "timeout"                  = 180
    "memory"                   = 1024
    "batch_window"             = 2
    "batch_size"               = 1
    "maximum_concurrency"      = 5
    "use_datadog_variables"    = false
    "use_additional_variables" = true
    "environment_variables" = {
      API_HOST = "solr-api-cudl-ecs.staging-solr"
      API_PORT = "8081"
      API_PATH = "collection"
    }
  },
  {
    "name"                           = "AWSLambda_CUDLPackageData_COPY_FILE_S3_to_EFS"
    "description"                    = "Copies file from S3 to EFS"
    "jar_path"                       = "release/uk/ac/cam/lib/cudl/awslambda/AWSLambda_Data_Transform/1.0/AWSLambda_Data_Transform-1.0-jar-with-dependencies.jar"
    "queue_name"                     = "CUDLPackageDataCopyFileToEFSQueue"
    "subnet_names"                   = ["staging-cudl-ecs-subnet-private-a", "staging-cudl-ecs-subnet-private-b"]
    "security_group_names"           = ["staging-cudl-ecs-vpc-egress", "staging-cudl-data-releases-efs"]
    "use_datadog_variables"          = false
    "mount_fs"                       = true
    "sqs_max_tries_before_deadqueue" = 1
    "timeout"                        = 900
    "memory"                         = 512
    "handler"                        = "uk.ac.cam.lib.cudl.awslambda.handlers.CopyToEFSFileHandler::handleRequest"
    "runtime"                        = "java11"
  },
  {
    "name"                       = "AWSLambda_CUDL_Transkribus_Ingest"
    "image_uri"                  = "438117829123.dkr.ecr.eu-west-1.amazonaws.com/cudl/transkribus-processing@sha256:03cf5047a7ddd72163edc8081e7cfad652c6072daa91d0ab941fc96b4d481a40"
    "queue_name"                 = "CUDL_Transkribus_IngestQueue"
    "vpc_name"                   = "staging-cudl-ecs-vpc"
    "subnet_names"               = ["staging-cudl-ecs-subnet-private-a", "staging-cudl-ecs-subnet-private-b"]
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
  }
]
dst-efs-prefix    = "/mnt/cudl-data-releases"
dst-prefix        = "html/"
dst-s3-prefix     = ""
tmp-dir           = "/tmp/dest/"
lambda-alias-name = "LIVE"

releases-root-directory-path               = "/data"
efs-name                                   = "cudl-data-releases-efs"
cloudfront_route53_zone_id                 = "Z03809063VDGJ8MKPHFRV"
data_processing_efs_throughput_mode        = "provisioned"
data_processing_efs_provisioned_throughput = 3


# Base Architecture
cluster_name_suffix            = "cudl-ecs"
registered_domain_name         = "cudl.lib.cam.ac.uk."
asg_desired_capacity           = 4 # n = number of tasks
asg_max_size                   = 5 # n + 1
asg_allow_all_egress           = true
route53_zone_id_existing       = "Z03809063VDGJ8MKPHFRV"
route53_zone_force_destroy     = true
acm_certificate_arn            = "arn:aws:acm:eu-west-1:438117829123:certificate/fec4f8c7-8c2d-4274-abc4-a6fa3f65583f"
acm_certificate_arn_us-east-1  = "arn:aws:acm:us-east-1:438117829123:certificate/3ebbcb94-1cf1-4adf-832f-add73eaea151"
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
  "cudl/content-loader-db" = "sha256:26092924ee4c2e086f8ca116a7f9de2350233658107aa5e76e75b07f2d31f5b4",
  "cudl/content-loader-ui" = "sha256:6d042df4170b601411bf63488253fbd70eb54bad335d04eeee956d2c4f31f4f8"
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
  "cudl/solr-api" = "sha256:a94e790d34dfbe9eaa7f07403efc21c27dd19fb0769bed1c978745f5f9bf1754",
  "cudl/solr"     = "sha256:16436e1492cabeaf8e97808f1bbb30b4e60221d67cefe0a18a1408a2b9d7320c"
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
  "cudl/services" = "sha256:bc86da808e1420fde49196cdbc12251f1e79ba5dc3f0c5a68e4e197ebe1c7902"
}
cudl_services_health_check_status_code = "404"
cudl_services_allowed_methods          = ["HEAD", "GET", "OPTIONS"]

cudl_viewer_name_suffix       = "cudl-viewer"
cudl_viewer_domain_name       = "viewer"
cudl_viewer_target_group_port = 5008
cudl_viewer_container_port    = 8080
cudl_viewer_ecr_repositories = {
  "cudl/viewer" = "sha256:deaea94196bffafd168bbda5f41b7cc2da8f315050ccc7b438a417a062480c50"
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
rti_image_server_certificate_arn                         = "arn:aws:acm:us-east-1:438117829123:certificate/3ebbcb94-1cf1-4adf-832f-add73eaea151"
rti_image_server_cloudfront_viewer_response_function_arn = "arn:aws:cloudfront::438117829123:function/staging-cudl-add-cors-response"
rti_image_server_cloudfront_cache_policy                 = "optimized"
rti_image_server_cloudfront_origin_request_policy_name   = "Managed-CORS-S3Origin"
rti_image_server_cloudfront_response_headers_policy_name = "Managed-CORS-With-Preflight"