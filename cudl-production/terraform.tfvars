environment                  = "production"
project                      = "CUDL"
component                    = "cudl-data-workflows"
subcomponent                 = "cudl-transform-lambda"
destination-bucket-name      = "cudl-data-releases"
transcriptions-bucket-name   = "cudl-transcriptions"
enhancements-bucket-name     = "cudl-data-enhancements"
source-bucket-name           = "cudl-data-source"
compressed-lambdas-directory = "compressed_lambdas"
lambda-jar-bucket            = "mvn.cudl.lib.cam.ac.uk"
lambda-db-jdbc-driver        = "org.postgresql.Driver"
lambda-db-url                = "jdbc:postgresql://<HOST>:<PORT>/production_cudl_viewer?autoReconnect=true"
lambda-db-secret-key         = "production/cudl/cudl_viewer_db"

transform-lambda-bucket-sns-notifications = [
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
        "queue_name" = "CUDLPackageDataUpdateDBQueue",
        "raw"        = true
      },
    ]
  }
]
transform-lambda-information = [
  {
    "name"                     = "AWSLambda_CUDLPackageData_SOLR_Listener"
    "image_uri"                = "247242244017.dkr.ecr.eu-west-1.amazonaws.com/cudl-listener@sha256:fc6f79c9a5f68029b2d2de3ec49690b27e9baf948e43ce34d6d744d864d4fca8"
    "queue_name"               = "CUDLIndexQueue"
    "vpc_name"                 = "CUDL-NETBLOCK"
    "subnet_names"             = ["CUDL-EUW1A"]
    "security_group_names"     = ["default"]
    "timeout"                  = 180
    "memory"                   = 1024
    "batch_window"             = 2
    "batch_size"               = 1
    "maximum_concurrency"      = 100
    "use_datadog_variables"    = false
    "use_additional_variables" = true
    "mount_fs"                 = false
    "environment_variables" = {
      API_HOST = "a064b0b5c52e49afa469b4ec4567e17e.solr-api-ccc.sandbox-solr-persist"
      API_PORT = "8091"
      API_PATH = "item"
    }
  },
  {
    "name"                     = "AWSLambda_CUDLPackageData_Collection_SOLR_Listener"
    "image_uri"                = "247242244017.dkr.ecr.eu-west-1.amazonaws.com/cudl-listener@sha256:fc6f79c9a5f68029b2d2de3ec49690b27e9baf948e43ce34d6d744d864d4fca8"
    "queue_name"               = "CUDLIndexCollectionQueue"
    "vpc_name"                 = "CUDL-NETBLOCK"
    "subnet_names"             = ["CUDL-EUW1A"]
    "security_group_names"     = ["default"]
    "timeout"                  = 180
    "memory"                   = 1024
    "batch_window"             = 2
    "batch_size"               = 1
    "maximum_concurrency"      = 100
    "use_datadog_variables"    = false
    "use_additional_variables" = true
    "mount_fs"                 = false
    "environment_variables" = {
      API_HOST = "a064b0b5c52e49afa469b4ec4567e17e.solr-api-ccc.sandbox-solr-persist"
      API_PORT = "8091"
      API_PATH = "collection"
    }
  },
  {
    "name"                  = "AWSLambda_CUDLPackageData_UPDATE_DB"
    "description"           = "Updates the CUDL database with collection information from the collections json file"
    "jar_path"              = "release/uk/ac/cam/lib/cudl/awslambda/AWSLambda_Data_Transform/1.0/AWSLambda_Data_Transform-1.0-jar-with-dependencies.jar"
    "queue_name"            = "CUDLPackageDataUpdateDBQueue"
    "use_datadog_variables" = false
    "vpc_name"              = "CUDL-NETBLOCK"
    "subnet_names"          = ["CUDL-EUW1A"]
    "security_group_names"  = ["default"]
    "timeout"               = 900
    "memory"                = 512
    "handler"               = "uk.ac.cam.lib.cudl.awslambda.handlers.CollectionFileDBHandler::handleRequest"
    "runtime"               = "java11"
  },
  {
    "name"                  = "AWSLambda_CUDLPackageData_DATASET_JSON"
    "description"           = "Transforms the dataset json file into a json format with suitable paths for the viewer / db"
    "jar_path"              = "release/uk/ac/cam/lib/cudl/awslambda/AWSLambda_Data_Transform/1.0/AWSLambda_Data_Transform-1.0-jar-with-dependencies.jar"
    "queue_name"            = "CUDLPackageDataDatasetQueue"
    "vpc_name"              = "CUDL-NETBLOCK"
    "subnet_names"          = ["CUDL-EUW1A"]
    "security_group_names"  = ["default"]
    "use_datadog_variables" = false
    "timeout"               = 900
    "memory"                = 512
    "handler"               = "uk.ac.cam.lib.cudl.awslambda.handlers.DatasetFileDBHandler::handleRequest"
    "runtime"               = "java11"
  },
  {
    "name"                  = "AWSLambda_CUDLPackageData_UI_JSON"
    "description"           = "Transforms the UI json file into a json format with suitable paths for the viewer / db"
    "jar_path"              = "release/uk/ac/cam/lib/cudl/awslambda/AWSLambda_Data_Transform/1.0/AWSLambda_Data_Transform-1.0-jar-with-dependencies.jar"
    "queue_name"            = "CUDLPackageDataUIQueue"
    "vpc_name"              = "CUDL-NETBLOCK"
    "subnet_names"          = ["CUDL-EUW1A"]
    "security_group_names"  = ["default"]
    "use_datadog_variables" = false
    "timeout"               = 900
    "memory"                = 512
    "handler"               = "uk.ac.cam.lib.cudl.awslambda.handlers.UIFileDBHandler::handleRequest"
    "runtime"               = "java11"
  },
  {
    "name"                  = "AWSLambda_CUDLPackageData_COPY_FILE_S3_to_EFS"
    "description"           = "Copies file from S3 to EFS"
    "jar_path"              = "release/uk/ac/cam/lib/cudl/awslambda/AWSLambda_Data_Transform/1.0/AWSLambda_Data_Transform-1.0-jar-with-dependencies.jar"
    "queue_name"            = "CUDLPackageDataCopyFileToEFSQueue"
    "vpc_name"              = "CUDL-NETBLOCK"
    "subnet_names"          = ["CUDL-EUW1A"]
    "security_group_names"  = ["default"]
    "use_datadog_variables" = false
    "mount_fs"              = true
    "timeout"               = 900
    "memory"                = 512
    "handler"               = "uk.ac.cam.lib.cudl.awslambda.handlers.CopyToEFSFileHandler::handleRequest"
    "runtime"               = "java11"
  }
]
transform-lambda-bucket-sqs-notifications = [
  {
    "type"          = "SQS",
    "queue_name"    = "CUDLPackageDataDatasetQueue"
    "filter_prefix" = "cudl.dl-dataset.json"
    "filter_suffix" = ""
    "bucket_name"   = "cudl-data-releases"
  },
  {
    "type"          = "SQS",
    "queue_name"    = "CUDLPackageDataUIQueue"
    "filter_prefix" = "cudl.ui.json"
    "filter_suffix" = ""
    "bucket_name"   = "cudl-data-releases"
  },
  {
    "type"          = "SQS",
    "queue_name"    = "CUDLPackageDataUpdateDBQueue"
    "filter_prefix" = "collections/"
    "filter_suffix" = ".json"
    "bucket_name"   = "cudl-data-releases"
  }
]
dst-efs-prefix    = "/mnt/cudl-data-releases"
dst-prefix        = "html/"
dst-s3-prefix     = ""
tmp-dir           = "/tmp/dest/"
lambda-alias-name = "LIVE"

# Existing vpc info
vpc-id            = "vpc-ab7880ce"
subnet-id         = "subnet-fa1ed08d"
security-group-id = "sg-b79833d2"

releases-root-directory-path = "/data"
efs-name                     = "cudl-data-releases"
cloudfront_route53_zone_id   = "Z1TSUAQ9EOFHVW"