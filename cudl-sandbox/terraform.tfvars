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
lambda-db-jdbc-driver        = "org.postgresql.Driver"
lambda-db-url                = "jdbc:postgresql://<HOST>:<PORT>/sandboxtf_cudl_viewer?autoReconnect=true"
lambda-db-secret-key         = "sandboxtf/cudl/cudl_viewer_db"

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
        "queue_name" = "CUDLPackageDataUpdateDBQueue",
        "raw"        = true
      },
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
    "subnet_names"          = ["cudl-subnet-private1-eu-west-1a"]
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
    "subnet_names"          = ["cudl-subnet-private1-eu-west-1a"]
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
    "subnet_names"          = ["cudl-subnet-private1-eu-west-1a"]
    "use_datadog_variables" = false
    "timeout"               = 900
    "memory"                = 512
    "handler"               = "uk.ac.cam.lib.cudl.awslambda.handlers.ConvertJSONIdsHandler::handleRequest"
    "runtime"               = "java11"
  },
  {
    "name"                     = "AWSLambda_CUDLPackageData_TEI_Processing"
    "image_uri"                = "563181399728.dkr.ecr.eu-west-1.amazonaws.com/cudl-tei-processing@sha256:a35d1beea05ffffe1461f260648d1bcf6521ceba8309cd9d071a34422a288015"
    "queue_name"               = "CUDL_TEIProcessingQueue"
    "vpc_name"                 = "sandbox-ccc-vpc"
    "subnet_names"             = ["sandbox-ccc-subnet-private-a", "sandbox-ccc-subnet-private-b"]
    "security_group_names"     = ["sandbox-ccc-vpc-endpoints", "sandbox-solr-persist-private-access"]
    "timeout"                  = 300
    "memory"                   = 4096
    "batch_window"             = 2
    "batch_size"               = 1
    "maximum_concurrency"      = 100
    "use_datadog_variables"    = false
    "use_additional_variables" = true
    "mount_fs"                 = false
    "environment_variables" = {
      ANT_TARGET             = "full"
      SEARCH_HOST            = "a064b0b5c52e49afa469b4ec4567e17e.solr-api-ccc.sandbox-solr-persist"
      SEARCH_PORT            = 8091
      SEARCH_COLLECTION_PATH = "collections"
    }
  },
  {
    "name"                     = "AWSLambda_CUDLPackageData_SOLR_Listener"
    "image_uri"                = "563181399728.dkr.ecr.eu-west-1.amazonaws.com/cudl-solr-listener@sha256:04e64aaeed3ac04a06952010dfae0d22397a567f3d39d03796d4124c8c0b439b"
    "queue_name"               = "CUDLIndexQueue"
    "vpc_name"                 = "sandbox-ccc-vpc"
    "subnet_names"             = ["sandbox-ccc-subnet-private-a", "sandbox-ccc-subnet-private-b"]
    "security_group_names"     = ["sandbox-ccc-vpc-endpoints", "sandbox-solr-persist-private-access"]
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
    "image_uri"                = "563181399728.dkr.ecr.eu-west-1.amazonaws.com/cudl-solr-listener@sha256:04e64aaeed3ac04a06952010dfae0d22397a567f3d39d03796d4124c8c0b439b"
    "queue_name"               = "CUDLIndexCollectionQueue"
    "vpc_name"                 = "sandbox-ccc-vpc"
    "subnet_names"             = ["sandbox-ccc-subnet-private-a", "sandbox-ccc-subnet-private-b"]
    "security_group_names"     = ["sandbox-ccc-vpc-endpoints", "sandbox-solr-persist-private-access"]
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
    "subnet_names"          = ["cudl-subnet-private1-eu-west-1a"]
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
    "subnet_names"          = ["cudl-subnet-private1-eu-west-1a"]
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
    "subnet_names"          = ["cudl-subnet-private1-eu-west-1a"]
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
    "subnet_names"          = ["cudl-subnet-private1-eu-west-1a"]
    "use_datadog_variables" = false
    "mount_fs"              = true
    "timeout"               = 900
    "memory"                = 512
    "handler"               = "uk.ac.cam.lib.cudl.awslambda.handlers.CopyToEFSFileHandler::handleRequest"
    "runtime"               = "java11"
  },
  {
    "name"                       = "AWSLambda_CUDL_Transkribus_Ingest"
    "image_uri"                  = "563181399728.dkr.ecr.eu-west-1.amazonaws.com/curious-cures-transkribus-processing@sha256:9f9567895171a803f879158a1196c319d69efa6b483955365ec325ffd609ee45"
    "queue_name"                 = "CUDL_Transkribus_IngestQueue"
    "vpc_name"                   = "sandbox-ccc-vpc"
    "subnet_names"               = ["sandbox-ccc-subnet-private-a", "sandbox-ccc-subnet-private-b"]
    "security_group_names"       = ["sandbox-ccc-vpc-endpoints", "sandbox-solr-persist-private-access"]
    "timeout"                    = 300
    "memory"                     = 4096
    "batch_window"               = 2
    "batch_size"                 = 1
    "maximum_concurrency"        = 100
    "use_datadog_variables"      = false
    "use_additional_variables"   = false
    "use_enhancements_variables" = true
    "mount_fs"                   = false
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

# Existing vpc info
vpc-id            = "vpc-057886e0bdd7c4e43"
subnet-id         = "subnet-02c0767268df8f171"
security-group-id = "sg-032f9f202ea602d21"

releases-root-directory-path = "/data"
efs-name                     = "cudl-data-releases"
cloudfront_route53_zone_id   = "Z035173135AOVWW8L57UJ"
