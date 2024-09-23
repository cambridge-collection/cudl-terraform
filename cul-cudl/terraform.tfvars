environment                  = "first"
project                      = "CUDL"
component                    = "cudl-data-workflows"
subcomponent                 = "cudl-transform-lambda"
destination-bucket-name      = "cudl-data-releases"
transcriptions-bucket-name   = "cudl-transcriptions"
enhancements-bucket-name     = "cudl-data-enhancements"
source-bucket-name           = "cudl-data-source"
compressed-lambdas-directory = "compressed_lambdas"
lambda-jar-bucket            = "cul-cudl.mvn.cudl.lib.cam.ac.uk"

transform-lambda-bucket-sns-notifications = [
  {
    "bucket_name"   = "cudl-data-source"
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
    "bucket_name"   = "cudl-data-releases"
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
    "bucket_name"   = "cudl-data-source"
  },
  {
    "type"          = "SQS",
    "queue_name"    = "CUDLPackageDataQueue_FILES_UNCHANGED_COPY"
    "filter_prefix" = "pages/images/"
    "bucket_name"   = "cudl-data-source"
  },
  {
    "type"          = "SQS",
    "queue_name"    = "CUDLPackageDataQueue_FILES_UNCHANGED_COPY"
    "filter_prefix" = "cudl.dl-dataset"
    "filter_suffix" = ".json"
    "bucket_name"   = "cudl-data-source"
  },
  {
    "type"          = "SQS",
    "queue_name"    = "CUDLPackageDataQueue_FILES_UNCHANGED_COPY"
    "filter_prefix" = "cudl.ui"
    "filter_suffix" = ".json5"
    "bucket_name"   = "cudl-data-source"
  },
  {
    "type"          = "SQS",
    "queue_name"    = "CUDLPackageDataQueue_Collections"
    "filter_prefix" = "collections/"
    "filter_suffix" = ".json"
    "bucket_name"   = "cudl-data-source"
  },
  {
    "type"          = "SQS",
    "queue_name"    = "CUDLPackageDataQueue_FILES_UNCHANGED_COPY"
    "filter_prefix" = "ui/"
    "filter_suffix" = ""
    "bucket_name"   = "cudl-data-source"
  },
  {
    "type"          = "SQS",
    "queue_name"    = "CUDLIndexQueue"
    "filter_prefix" = "solr-json/"
    "filter_suffix" = ".json"
    "bucket_name"   = "cudl-data-releases"
  },
  {
    "type"          = "SQS",
    "queue_name"    = "CUDLPackageDataCopyFileToEFSQueue"
    "filter_prefix" = "cudl.dl-dataset.json"
    "filter_suffix" = ""
    "bucket_name"   = "cudl-data-releases"
  },
  {
    "type"          = "SQS",
    "queue_name"    = "CUDLPackageDataCopyFileToEFSQueue"
    "filter_prefix" = "cudl.ui.json5"
    "filter_suffix" = ""
    "bucket_name"   = "cudl-data-releases"
  },
  {
    "type"          = "SQS",
    "queue_name"    = "CUDLPackageDataCopyFileToEFSQueue"
    "filter_prefix" = "json/"
    "filter_suffix" = ".json"
    "bucket_name"   = "cudl-data-releases"
  },
  {
    "type"          = "SQS",
    "queue_name"    = "CUDLPackageDataCopyFileToEFSQueue"
    "filter_prefix" = "pages/"
    "filter_suffix" = ""
    "bucket_name"   = "cudl-data-releases"
  },
  {
    "type"          = "SQS",
    "queue_name"    = "CUDLPackageDataCopyFileToEFSQueue"
    "filter_prefix" = "ui/"
    "filter_suffix" = ""
    "bucket_name"   = "cudl-data-releases"
  },
  {
    "type"          = "SQS",
    "queue_name"    = "CUDL_Transkribus_IngestQueue"
    "filter_prefix" = "transkribus/curious-cures/"
    "filter_suffix" = ".xml"
    "bucket_name"   = "cudl-data-enhancements"
  }
]
transform-lambda-information = [
  {
    "name"                  = "AWSLambda_CUDLPackageData_HTML_to_HTML_Translate_URLS"
    "description"           = "Processes HTML files from source data format into the releases data format by transforming the URL paths"
    "jar_path"              = "release/uk/ac/cam/lib/cudl/awslambda/AWSLambda_Data_Transform/1.0/AWSLambda_Data_Transform-1.0-jar-with-dependencies.jar"
    "queue_name"            = "CUDLPackageDataQueue_HTML"
    "subnet_names"          = ["first-cudl-ecs-subnet-private-a", "first-cudl-ecs-subnet-private-b"]
    "security_group_names"  = ["first-cudl-ecs-vpc-endpoints"]
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
    "vpc_name"              = "first-cudl-ecs-vpc"
    "subnet_names"          = ["first-cudl-ecs-subnet-private-a", "first-cudl-ecs-subnet-private-b"]
    "security_group_names"  = ["first-cudl-ecs-vpc-endpoints"]
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
    "subnet_names"          = ["first-cudl-ecs-subnet-private-a", "first-cudl-ecs-subnet-private-b"]
    "security_group_names"  = ["first-cudl-ecs-vpc-endpoints"]
    "use_datadog_variables" = false
    "timeout"               = 900
    "memory"                = 512
    "handler"               = "uk.ac.cam.lib.cudl.awslambda.handlers.ConvertJSONIdsHandler::handleRequest"
    "runtime"               = "java11"
  },
  {
    "name"                     = "AWSLambda_CUDLPackageData_TEI_Processing"
    "image_uri"                = "438117829123.dkr.ecr.eu-west-1.amazonaws.com/cudl/tei-processing@sha256:6e4cb978ca3e673fed2da24b12615fc510745798f9a74aedd6be5a239fa78466"
    "queue_name"               = "CUDL_TEIProcessingQueue"
    "vpc_name"                 = "first-cudl-ecs-vpc"
    "subnet_names"             = ["first-cudl-ecs-subnet-private-a", "first-cudl-ecs-subnet-private-b"]
    "security_group_names"     = ["first-cudl-ecs-vpc-endpoints", "first-solr-external"]
    "timeout"                  = 300
    "memory"                   = 4096
    "batch_window"             = 2
    "batch_size"               = 1
    "maximum_concurrency"      = 100
    "use_datadog_variables"    = false
    "use_additional_variables" = true
    "environment_variables" = {
      ANT_TARGET             = "full"
      SEARCH_HOST            = "solr-api-cudl-ecs.first-solr"
      SEARCH_PORT            = 8081
      SEARCH_COLLECTION_PATH = "collections"
    }
  },
  {
    "name"                     = "AWSLambda_CUDLPackageData_SOLR_Listener"
    "image_uri"                = "438117829123.dkr.ecr.eu-west-1.amazonaws.com/cudl/solr-listener@sha256:7ff916e5d805361e86a81669f83263cb7f65a66d3bff754583d88f3d01b1a962"
    "queue_name"               = "CUDLIndexQueue"
    "vpc_name"                 = "first-cudl-ecs-vpc"
    "subnet_names"             = ["first-cudl-ecs-subnet-private-a", "first-cudl-ecs-subnet-private-b"]
    "security_group_names"     = ["first-cudl-ecs-vpc-endpoints", "first-solr-external"]
    "timeout"                  = 180
    "memory"                   = 1024
    "batch_window"             = 2
    "batch_size"               = 1
    "maximum_concurrency"      = 100
    "use_datadog_variables"    = false
    "use_additional_variables" = true
    "environment_variables" = {
      API_HOST = "solr-api-cudl-ecs.first-solr"
      API_PORT = "8081"
      API_PATH = "item"
    }
  },
  {
    "name"                     = "AWSLambda_CUDLPackageData_Collection_SOLR_Listener"
    "image_uri"                = "438117829123.dkr.ecr.eu-west-1.amazonaws.com/cudl/solr-listener@sha256:7ff916e5d805361e86a81669f83263cb7f65a66d3bff754583d88f3d01b1a962"
    "queue_name"               = "CUDLIndexCollectionQueue"
    "vpc_name"                 = "first-cudl-ecs-vpc"
    "subnet_names"             = ["first-cudl-ecs-subnet-private-a", "first-cudl-ecs-subnet-private-b"]
    "security_group_names"     = ["first-cudl-ecs-vpc-endpoints", "first-solr-external"]
    "timeout"                  = 180
    "memory"                   = 1024
    "batch_window"             = 2
    "batch_size"               = 1
    "maximum_concurrency"      = 100
    "use_datadog_variables"    = false
    "use_additional_variables" = true
    "environment_variables" = {
      API_HOST = "solr-api-cudl-ecs.first-solr"
      API_PORT = "8081"
      API_PATH = "collection"
    }
  },
  {
    "name"                  = "AWSLambda_CUDLPackageData_COPY_FILE_S3_to_EFS"
    "description"           = "Copies file from S3 to EFS"
    "jar_path"              = "release/uk/ac/cam/lib/cudl/awslambda/AWSLambda_Data_Transform/1.0/AWSLambda_Data_Transform-1.0-jar-with-dependencies.jar"
    "queue_name"            = "CUDLPackageDataCopyFileToEFSQueue"
    "subnet_names"          = ["first-cudl-ecs-subnet-private-a", "first-cudl-ecs-subnet-private-b"]
    "security_group_names"  = ["first-cudl-ecs-vpc-endpoints", "first-cudl-data-releases-efs"]
    "use_datadog_variables" = false
    "mount_fs"              = true
    "timeout"               = 900
    "memory"                = 512
    "handler"               = "uk.ac.cam.lib.cudl.awslambda.handlers.CopyToEFSFileHandler::handleRequest"
    "runtime"               = "java11"
  },
  {
    "name"                       = "AWSLambda_CUDL_Transkribus_Ingest"
    "image_uri"                  = "438117829123.dkr.ecr.eu-west-1.amazonaws.com/cudl/transkribus-processing@sha256:03cf5047a7ddd72163edc8081e7cfad652c6072daa91d0ab941fc96b4d481a40"
    "queue_name"                 = "CUDL_Transkribus_IngestQueue"
    "vpc_name"                   = "first-cudl-ecs-vpc"
    "subnet_names"               = ["first-cudl-ecs-subnet-private-a", "first-cudl-ecs-subnet-private-b"]
    "security_group_names"       = ["first-cudl-ecs-vpc-endpoints"]
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

releases-root-directory-path = "/data"
efs-name                     = "cudl-data-releases-efs"
cloudfront_route53_zone_id   = "Z048007032WTKFJCB78QT"

# Base Architecture
cluster_name_suffix            = "cudl-ecs"
registered_domain_name         = "cul-cudl.net."
asg_desired_capacity           = 4 # n = number of tasks
asg_max_size                   = 5 # n + 1
asg_allow_all_egress           = true
route53_zone_id_existing       = "Z048007032WTKFJCB78QT"
route53_zone_force_destroy     = true
alb_enable_deletion_protection = false
vpc_cidr_block                 = "10.88.0.0/22" #1024 adresses
vpc_public_subnet_public_ip    = false
cloudwatch_log_group           = "/ecs/CUDL"
vpc_endpoint_services          = ["ssmmessages", "ssm", "ec2messages", "ecr.api", "ecr.dkr", "ecs", "ecs-agent", "ecs-telemetry", "logs", "elasticfilesystem", "secretsmanager"]

# Content Loader Workload
content_loader_name_suffix              = "cl"
content_loader_domain_name              = "contentloader"
content_loader_application_port         = 8081
content_loader_target_group_port        = 9009
content_loader_ecr_repository_names     = ["cudl/content-loader-db", "cudl/content-loader-ui"]
content_loader_ecs_task_def_volumes     = { "dl-loader-db" = "/var/lib/postgresql" }
content_loader_container_name_ui        = "dl-loader-ui"
content_loader_container_name_db        = "dl-loader-db"
content_loader_health_check_status_code = "401"
content_loader_allowed_methods          = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]

# SOLR Worload
solr_name_suffix               = "solr"
solr_domain_name               = "solr"
solr_api_port                  = 80
solr_application_port          = 8983
solr_target_group_port         = 8081
solr_ecr_repository_names      = ["cudl/solr-api", "cudl/solr"]
solr_ecs_task_def_volumes      = { "solr-volume" = "/var/solr" }
solr_container_name_api        = "solr-api"
solr_container_name_solr       = "solr"
solr_health_check_status_code  = "404"
solr_allowed_methods           = ["HEAD", "GET", "OPTIONS"]
solr_ecs_task_def_cpu          = 1536
solr_ecs_task_def_memory       = 1638
solr_use_service_discovery     = true
solr_ingress_security_group_id = "sg-032f9f202ea602d21"

cudl_services_name_suffix              = "cudl-services"
cudl_services_domain_name              = "services"
cudl_services_target_group_port        = 8085
cudl_services_container_port           = 3000
cudl_services_ecr_repository_names     = ["cudl/services"]
cudl_services_health_check_status_code = "404"
cudl_services_allowed_methods          = ["HEAD", "GET", "OPTIONS"]

cudl_viewer_name_suffix                     = "cudl-viewer"
cudl_viewer_domain_name                     = "cudl-viewer"
cudl_viewer_target_group_port               = 5008
cudl_viewer_container_port                  = 8080
cudl_viewer_ecr_repository_names            = ["cudl/viewer"]
cudl_viewer_health_check_status_code        = "200"
cudl_viewer_allowed_methods                 = ["HEAD", "GET", "OPTIONS"]
cudl_viewer_ecs_task_def_volumes            = { "cudl-viewer" = "/srv/cudl-viewer/cudl-data" }
cudl_viewer_datasync_task_s3_to_efs_pattern = "/json/*|/pages/*|/cudl.dl-dataset.json|/cudl.ui.json5|/collections/*|/ui/*"
