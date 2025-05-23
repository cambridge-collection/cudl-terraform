environment                  = "sandbox"
project                      = "CUDL"
component                    = "cudl-data-workflows"
subcomponent                 = "cudl-transform-lambda"
destination-bucket-name      = "cudl-data-releases"
transcriptions-bucket-name   = "cudl-transcriptions"
enhancements-bucket-name     = "cudl-data-enhancements"
source-bucket-name           = "cudl-data-source"
compressed-lambdas-directory = "compressed_lambdas"
lambda-jar-bucket            = "sandbox.mvn.cudl.lib.cam.ac.uk"

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
    "subnet_names"          = ["rmm98-sandbox-cudl-ecs-subnet-private-a", "rmm98-sandbox-cudl-ecs-subnet-private-b"]
    "security_group_names"  = ["rmm98-sandbox-cudl-ecs-vpc-egress"]
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
    "vpc_name"              = "rmm98-sandbox-cudl-ecs-vpc"
    "subnet_names"          = ["rmm98-sandbox-cudl-ecs-subnet-private-a", "rmm98-sandbox-cudl-ecs-subnet-private-b"]
    "security_group_names"  = ["rmm98-sandbox-cudl-ecs-vpc-egress"]
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
    "subnet_names"          = ["rmm98-sandbox-cudl-ecs-subnet-private-a", "rmm98-sandbox-cudl-ecs-subnet-private-b"]
    "security_group_names"  = ["rmm98-sandbox-cudl-ecs-vpc-egress"]
    "use_datadog_variables" = false
    "timeout"               = 900
    "memory"                = 512
    "handler"               = "uk.ac.cam.lib.cudl.awslambda.handlers.ConvertJSONIdsHandler::handleRequest"
    "runtime"               = "java11"
  },
  {
    "name"                     = "AWSLambda_CUDLPackageData_TEI_Processing"
    "image_uri"                = "563181399728.dkr.ecr.eu-west-1.amazonaws.com/cudl-tei-processing@sha256:8b19952be936adcb5018ed37fe4cebbe86c2be82ae5a43b586745b37214c54bc"
    "queue_name"               = "CUDL_TEIProcessingQueue"
    "vpc_name"                 = "rmm98-sandbox-cudl-ecs-vpc"
    "subnet_names"             = ["rmm98-sandbox-cudl-ecs-subnet-private-a", "rmm98-sandbox-cudl-ecs-subnet-private-b"]
    "security_group_names"     = ["rmm98-sandbox-cudl-ecs-vpc-egress", "rmm98-sandbox-solr-external"]
    "timeout"                  = 300
    "memory"                   = 4096
    "batch_window"             = 2
    "batch_size"               = 1
    "maximum_concurrency"      = 100
    "use_datadog_variables"    = false
    "use_additional_variables" = true
    "environment_variables" = {
      ANT_TARGET             = "full"
      SEARCH_HOST            = "solr-api-cudl-ecs.rmm98-sandbox-solr"
      SEARCH_PORT            = 8081
      SEARCH_COLLECTION_PATH = "collections"
    }
  },
  {
    "name"                     = "AWSLambda_CUDLPackageData_SOLR_Listener"
    "image_uri"                = "563181399728.dkr.ecr.eu-west-1.amazonaws.com/cudl-solr-listener@sha256:88795e469457966c06f62e55c1c217bef3b5fb92c35589bac4a5be735c631689"
    "queue_name"               = "CUDLIndexQueue"
    "vpc_name"                 = "rmm98-sandbox-cudl-ecs-vpc"
    "subnet_names"             = ["rmm98-sandbox-cudl-ecs-subnet-private-a", "rmm98-sandbox-cudl-ecs-subnet-private-b"]
    "security_group_names"     = ["rmm98-sandbox-cudl-ecs-vpc-egress", "rmm98-sandbox-solr-external"]
    "timeout"                  = 180
    "memory"                   = 1024
    "batch_window"             = 2
    "batch_size"               = 1
    "maximum_concurrency"      = 5
    "use_datadog_variables"    = false
    "use_additional_variables" = true
    "environment_variables" = {
      API_HOST = "solr-api-cudl-ecs.rmm98-sandbox-solr"
      API_PORT = "8081"
      API_PATH = "item"
    }
  },
  {
    "name"                     = "AWSLambda_CUDLPackageData_Collection_SOLR_Listener"
    "image_uri"                = "563181399728.dkr.ecr.eu-west-1.amazonaws.com/cudl-solr-listener@sha256:88795e469457966c06f62e55c1c217bef3b5fb92c35589bac4a5be735c631689"
    "queue_name"               = "CUDLIndexCollectionQueue"
    "vpc_name"                 = "rmm98-sandbox-cudl-ecs-vpc"
    "subnet_names"             = ["rmm98-sandbox-cudl-ecs-subnet-private-a", "rmm98-sandbox-cudl-ecs-subnet-private-b"]
    "security_group_names"     = ["rmm98-sandbox-cudl-ecs-vpc-egress", "rmm98-sandbox-solr-external"]
    "timeout"                  = 180
    "memory"                   = 1024
    "batch_window"             = 2
    "batch_size"               = 1
    "maximum_concurrency"      = 5
    "use_datadog_variables"    = false
    "use_additional_variables" = true
    "environment_variables" = {
      API_HOST = "solr-api-cudl-ecs.rmm98-sandbox-solr"
      API_PORT = "8081"
      API_PATH = "collection"
    }
  },
  {
    "name"                           = "AWSLambda_CUDLPackageData_COPY_FILE_S3_to_EFS"
    "description"                    = "Copies file from S3 to EFS"
    "jar_path"                       = "release/uk/ac/cam/lib/cudl/awslambda/AWSLambda_Data_Transform/1.0/AWSLambda_Data_Transform-1.0-jar-with-dependencies.jar"
    "queue_name"                     = "CUDLPackageDataCopyFileToEFSQueue"
    "subnet_names"                   = ["rmm98-sandbox-cudl-ecs-subnet-private-a", "rmm98-sandbox-cudl-ecs-subnet-private-b"]
    "security_group_names"           = ["rmm98-sandbox-cudl-ecs-vpc-egress", "rmm98-sandbox-cudl-data-releases-efs"]
    "use_datadog_variables"          = false
    "mount_fs"                       = true
    "timeout"                        = 900
    "memory"                         = 512
    "sqs_max_tries_before_deadqueue" = 1
    "handler"                        = "uk.ac.cam.lib.cudl.awslambda.handlers.CopyToEFSFileHandler::handleRequest"
    "runtime"                        = "java11"
  },
  {
    "name"                       = "AWSLambda_CUDL_Transkribus_Ingest"
    "image_uri"                  = "563181399728.dkr.ecr.eu-west-1.amazonaws.com/curious-cures-transkribus-processing@sha256:03cf5047a7ddd72163edc8081e7cfad652c6072daa91d0ab941fc96b4d481a40"
    "queue_name"                 = "CUDL_Transkribus_IngestQueue"
    "vpc_name"                   = "rmm98-sandbox-cudl-ecs-vpc"
    "subnet_names"               = ["rmm98-sandbox-cudl-ecs-subnet-private-a", "rmm98-sandbox-cudl-ecs-subnet-private-b"]
    "security_group_names"       = ["rmm98-sandbox-cudl-ecs-vpc-egress"]
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
cloudfront_route53_zone_id   = "Z035173135AOVWW8L57UJ"

# Base Architecture
cluster_name_suffix            = "cudl-ecs"
registered_domain_name         = "cudl-sandbox.net."
asg_desired_capacity           = 4 # n = number of tasks
asg_max_size                   = 5 # n + 1
asg_allow_all_egress           = true
ec2_instance_type              = "t3.small"
ec2_additional_userdata        = <<-EOF
echo 1 > /proc/sys/vm/swappiness
echo ECS_RESERVED_MEMORY=256 >> /etc/ecs/ecs.config
EOF
route53_delegation_set_id      = "N02288771HQRX5TRME6CM"
route53_zone_id_existing       = "Z035173135AOVWW8L57UJ"
route53_zone_force_destroy     = true
alb_enable_deletion_protection = false
alb_idle_timeout               = "900"
vpc_cidr_block                 = "10.42.0.0/22" #1024 adresses
vpc_public_subnet_public_ip    = false
vpc_peering_vpc_ids            = ["vpc-057886e0bdd7c4e43"]
cloudwatch_log_group           = "/ecs/CUDLContent"

# Content Loader Workload
content_loader_name_suffix       = "cl"
content_loader_domain_name       = "contentloader"
content_loader_application_port  = 8081
content_loader_target_group_port = 9009
content_loader_ecr_repositories = {
  "dl-loader-db" = "sha256:49a8074c30f12800d1c36813d85fb4e3e69952d67990f20c6ff05b1e97e19568",
  "dl-loader-ui" = "sha256:092d9134da0c04855e61d14ddb812df9e564b8a33af4931609b5f5feb4861502"
}
content_loader_ecs_task_def_volumes                = { "dl-loader-db" = "/var/lib/postgresql/data" }
content_loader_container_name_ui                   = "dl-loader-ui"
content_loader_container_name_db                   = "dl-loader-db"
content_loader_health_check_status_code            = "401"
content_loader_allowed_methods                     = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
content_loader_waf_common_ruleset_override_actions = ["SizeRestrictions_QUERYSTRING", "SizeRestrictions_BODY", "GenericLFI_BODY", "CrossSiteScripting_BODY"]
content_loader_cloudfront_origin_read_timeout      = 180

# SOLR Worload
solr_name_suffix       = "solr"
solr_domain_name       = "solr"
solr_api_port          = 80
solr_application_port  = 8983
solr_target_group_port = 8081
solr_ecr_repositories = {
  "cudl-solr-api" = "sha256:f5663ef09aa01c90a92057d161c4a3c83bb851137eb8b6dc1228d2727a130810",
  "cudl-solr"     = "sha256:8dfcce2322e381d92bc02d19710afa8ec15e5a8f6c1efa1edddf550527c51fdb"
}
solr_ecs_task_def_volumes      = { "solr-volume" = "/var/solr" }
solr_container_name_api        = "solr-api"
solr_container_name_solr       = "solr"
solr_health_check_status_code  = "404"
solr_allowed_methods           = ["HEAD", "GET", "OPTIONS"]
solr_ecs_task_def_cpu          = 2048
solr_use_service_discovery     = true
solr_ingress_security_group_id = "sg-032f9f202ea602d21"

cudl_services_name_suffix       = "cudl-services"
cudl_services_domain_name       = "services"
cudl_services_target_group_port = 8085
cudl_services_container_port    = 3000
cudl_services_ecr_repositories = {
  "cudl-services" = "sha256:9da79f802e82b12ef6c599a88a551ca793b7ccae355e4f718e12de61e70ee202"
}
cudl_services_health_check_status_code = "404"
cudl_services_allowed_methods          = ["HEAD", "GET", "OPTIONS"]

cudl_viewer_name_suffix       = "cudl-viewer"
cudl_viewer_domain_name       = "cudl-viewer"
cudl_viewer_target_group_port = 5008
cudl_viewer_container_port    = 8080
cudl_viewer_ecr_repositories = {
  "sandbox-cudl-viewer" = "sha256:5d0485fc0565047d9006aa4ef754a6e1f3def38f1df9164e7a6ce42abaf57cba"
}
cudl_viewer_health_check_status_code        = "200"
cudl_viewer_allowed_methods                 = ["HEAD", "GET", "OPTIONS"]
cudl_viewer_ecs_task_def_volumes            = { "cudl-viewer" = "/srv/cudl-viewer/cudl-data" }
cudl_viewer_datasync_task_s3_to_efs_pattern = "/json/*|/pages/*|/cudl.dl-dataset.json|/cudl.ui.json5|/collections/*|/ui/*"
