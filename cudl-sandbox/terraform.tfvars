environment                          = "sandbox"
project                              = "CUDL"
component                            = "cudl-data-workflows"
subcomponent                         = "cudl-transform-lambda"
db-only-processing                   = false
destination-bucket-name              = "cudl-data-releases"
transcriptions-bucket-name           = "cudl-transcriptions"
transkribus-bucket-name              = "cudl-data-enhancements"
enhancements-destination-bucket-name = "cudl-data-source"
source-bucket-name                   = "cudl-data-source"
compressed-lambdas-directory         = "compressed_lambdas"
lambda-jar-bucket                    = "sandbox.mvn.cudl.lib.cam.ac.uk"
lambda-layer-name                    = "cudl-xslt-layer"
enhancements-lambda-layer-name       = "cudl-transkribus-xslt-layer"
lambda-layer-bucket                  = "sandbox-cudl-artefacts"
lambda-layer-filepath                = "projects/cudl-data-processing/xslt/cudl-transform-xslt-0.0.15.zip"
enhancements-lambda-layer-filepath   = "projects/curious-cures/xslt/curious-cures-xslt-0.0.2.zip"
lambda-db-jdbc-driver                = "org.postgresql.Driver"
lambda-db-url                        = "jdbc:postgresql://<HOST>:<PORT>/sandboxtf_cudl_viewer?autoReconnect=true"
lambda-db-secret-key                 = "sandboxtf/cudl/cudl_viewer_db"

source-bucket-sns-notifications = [
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
source-bucket-sqs-notifications = [
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
    "bucket_name"   = "cudl-data-source"
  },
  {
    "type"          = "SQS",
    "queue_name"    = "CUDLIndexQueue"
    "filter_prefix" = "solr-json/"
    "filter_suffix" = ".json"
    "bucket_name"   = "cudl-data-releases"
  },
#   {
#     "type"          = "SQS",
#     "queue_name"    = "CUDLIndexCollectionQueue"
#     "filter_prefix" = "collection/"
#     "filter_suffix" = ".json"
#     "bucket_name"   = "cudl-data-releases"
#   },
#   {
#     "type"          = "SQS",
#     "queue_name"    = "CUDLPackageDataUpdateDBQueue"
#     "filter_prefix" = "collections/"
#     "filter_suffix" = ".json"
#     "bucket_name"   = "cudl-data-releases"
#   },
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
  }
]
transform-lambda-information = [
  {
    "name"          = "AWSLambda_CUDLPackageData_HTML_to_HTML_Translate_URLS"
    "description"   = "Processes HTML files from source data format into the releases data format by transforming the URL paths"
    "jar_path"      = "release/uk/ac/cam/lib/cudl/awslambda/AWSLambda_Data_Transform/0.16/AWSLambda_Data_Transform-0.16-jar-with-dependencies.jar"
    "queue_name"    = "CUDLPackageDataQueue_HTML"
    "transcription" = false
    "timeout"       = 900
    "memory"        = 512
    "handler"       = "uk.ac.cam.lib.cudl.awslambda.handlers.ConvertHTMLIdsHandler::handleRequest"
    "runtime"       = "java11"
  },
  {
    "name"          = "AWSLambda_CUDLPackageData_FILE_UNCHANGED_COPY"
    "description"   = "Copies file from the source s3 bucket into the destination (release) s3 bucket, unchanged"
    "jar_path"      = "release/uk/ac/cam/lib/cudl/awslambda/AWSLambda_Data_Transform/0.16/AWSLambda_Data_Transform-0.16-jar-with-dependencies.jar"
    "queue_name"    = "CUDLPackageDataQueue_FILES_UNCHANGED_COPY"
    "transcription" = false
    "timeout"       = 900
    "memory"        = 512
    "other_filters" = "cudl.dl-dataset.json|cudl.ui.json"
    "handler"       = "uk.ac.cam.lib.cudl.awslambda.handlers.CopyFileHandler::handleRequest"
    "runtime"       = "java11"
  },
  {
    "name"          = "AWSLambda_CUDLPackageData_JSON_to_JSON_Translate_URLS"
    "description"   = "Transforms the collection json file into a json format with suitable paths for the viewer / db"
    "jar_path"      = "release/uk/ac/cam/lib/cudl/awslambda/AWSLambda_Data_Transform/0.16/AWSLambda_Data_Transform-0.16-jar-with-dependencies.jar"
    "queue_name"    = "CUDLPackageDataQueue_Collections"
    "transcription" = false
    "timeout"       = 900
    "memory"        = 512
    "handler"       = "uk.ac.cam.lib.cudl.awslambda.handlers.ConvertJSONIdsHandler::handleRequest"
    "runtime"       = "java11"
  },
  {
    "name"                     = "AWSLambda_CUDLPackageData_TEI_Processing"
    "image_uri"                = "563181399728.dkr.ecr.eu-west-1.amazonaws.com/cudl-tei-processing@sha256:5c2fdf33a259ee2bc3c21de7e19eccef41aa5126781ddd56eef0d66d2d58bc84"
    "queue_name"               = "CUDL_TEIProcessingQueue"
    "transcription"            = true
    "timeout"                  = 300
    "memory"                   = 4096
    "batch_window"             = 2
    "batch_size"               = 1
    "maximum_concurrency"      = 100
    "use_datadog_variables"    = false
    "use_additional_variables" = true
    "mount_fs"                 = false
    "environment_variables" = {
      ANT_TARGET            = "full"
      #COLLECTION_XML_SOURCE = "/tmp/opt/cdcp/dist-pending/collection-xml"
      #CORE_XML_SOURCE       = "/tmp/opt/cdcp/dist-pending/core-xml"
      #PAGE_XML_SOURCE       = "/tmp/opt/cdcp/dist-pending/page-xml"
      SEARCH_HOST           = "3228e23cefe14d1291b146570655133a.solr-api-ccc.sandbox-solr"
      SEARCH_PORT           = 8081
      SEARCH_COLLECTION_PATH = "collection"
    }
  },
  {
    "name"                     = "AWSLambda_CUDLPackageData_SOLR_Listener"
    "image_uri"                = "563181399728.dkr.ecr.eu-west-1.amazonaws.com/cudl-solr-listener@sha256:04e64aaeed3ac04a06952010dfae0d22397a567f3d39d03796d4124c8c0b439b"
    "queue_name"               = "CUDLIndexQueue"
    "transcription"            = false
    "vpc_name"                 = "sandbox-ccc-vpc"
    "subnet_names"             = ["sandbox-ccc-subnet-private-a", "sandbox-ccc-subnet-private-b"]
    "security_group_names"     = ["sandbox-ccc-vpc-endpoints", "sandbox-solr-private-access"]
    "timeout"                  = 180
    "memory"                   = 1024
    "batch_window"             = 2
    "batch_size"               = 1
    "maximum_concurrency"      = 100
    "use_datadog_variables"    = false
    "use_additional_variables" = true
    "mount_fs"                 = false
    "environment_variables" = {
      API_HOST = "3228e23cefe14d1291b146570655133a.solr-api-ccc.sandbox-solr"
      API_PORT = "8081"
      API_PATH = "item"
    }
  },
  {
    "name"                     = "AWSLambda_CUDLPackageData_Collection_SOLR_Listener"
    "image_uri"                = "563181399728.dkr.ecr.eu-west-1.amazonaws.com/cudl-solr-listener@sha256:04e64aaeed3ac04a06952010dfae0d22397a567f3d39d03796d4124c8c0b439b"
    "queue_name"               = "CUDLIndexCollectionQueue"
    "transcription"            = false
    "vpc_name"                 = "sandbox-ccc-vpc"
    "subnet_names"             = ["sandbox-ccc-subnet-private-a", "sandbox-ccc-subnet-private-b"]
    "security_group_names"     = ["sandbox-ccc-vpc-endpoints", "sandbox-solr-private-access"]
    "timeout"                  = 180
    "memory"                   = 1024
    "batch_window"             = 2
    "batch_size"               = 1
    "maximum_concurrency"      = 100
    "use_datadog_variables"    = false
    "use_additional_variables" = true
    "mount_fs"                 = false
    "environment_variables" = {
      API_HOST = "3228e23cefe14d1291b146570655133a.solr-api-ccc.sandbox-solr"
      API_PORT = "8081"
      API_PATH = "collection"
    }
  },
  {
    "name"          = "AWSLambda_CUDLPackageData_UPDATE_DB"
    "description"   = "Updates the CUDL database with collection information from the collections json file"
    "jar_path"      = "release/uk/ac/cam/lib/cudl/awslambda/AWSLambda_Data_Transform/0.16/AWSLambda_Data_Transform-0.16-jar-with-dependencies.jar"
    "queue_name"    = "CUDLPackageDataUpdateDBQueue"
    "transcription"            = false
    "timeout"       = 900
    "memory"        = 512
    "handler"       = "uk.ac.cam.lib.cudl.awslambda.handlers.CollectionFileDBHandler::handleRequest"
    "runtime"       = "java11"
  },
  {
    "name"          = "AWSLambda_CUDLPackageData_DATASET_JSON"
    "description"   = "Transforms the dataset json file into a json format with suitable paths for the viewer / db"
    "jar_path"      = "release/uk/ac/cam/lib/cudl/awslambda/AWSLambda_Data_Transform/0.16/AWSLambda_Data_Transform-0.16-jar-with-dependencies.jar"
    "queue_name"    = "CUDLPackageDataDatasetQueue"
    "transcription"            = false
    "timeout"       = 900
    "memory"        = 512
    "handler"       = "uk.ac.cam.lib.cudl.awslambda.handlers.DatasetFileDBHandler::handleRequest"
    "runtime"       = "java11"
  },
  {
    "name"          = "AWSLambda_CUDLPackageData_UI_JSON"
    "description"   = "Transforms the UI json file into a json format with suitable paths for the viewer / db"
    "jar_path"      = "release/uk/ac/cam/lib/cudl/awslambda/AWSLambda_Data_Transform/0.16/AWSLambda_Data_Transform-0.16-jar-with-dependencies.jar"
    "queue_name"    = "CUDLPackageDataUIQueue"
    "transcription"            = false
    "timeout"       = 900
    "memory"        = 512
    "handler"       = "uk.ac.cam.lib.cudl.awslambda.handlers.UIFileDBHandler::handleRequest"
    "runtime"       = "java11"
  }
]
enhancements-lambda-information = [{
  "name"          = "AWSLambda_CUDLDataEnhancements_TranskribusMergeTEI"
  "description"   = "Used by the Transkribus pipeline to merge TEI transcription output from Transkribus into the TEI CUDL metadata.  Enhances the CUDL TEI with the Transkribus transcription data"
  "jar_path"      = "release/uk/ac/cam/lib/cudl/awslambda/AWSLambda_Data_Transform/0.16/AWSLambda_Data_Transform-0.16-jar-with-dependencies.jar"
  "queue_name"    = "CUDLTranskribusQueue"
  "transcription" = true
  "timeout"       = 900
  "memory"        = 512
  "handler"       = "uk.ac.cam.lib.cudl.awslambda.handlers.XSLTTransformRequestHandler::handleRequest"
  "runtime"       = "java11"
}]
db-lambda-information = [

]
dst-efs-prefix              = "/mnt/cudl-data-releases"
dst-prefix                  = "html/"
dst-s3-prefix               = ""
enhancements-dst-s3-prefix  = "items/data/tei/"
tmp-dir                     = "/tmp/dest/"
large-file-limit            = 1000000
chunks                      = 4
data-function-name          = "AWSLambda_CUDLPackageDataJSON_AddEvent"
transcription-function-name = "DEPRECATED"
transcription-pagify-xslt   = "/opt/xslt/transcription/pagify.xsl"
transcription-mstei-xslt    = "/opt/xslt/transcription/msTeiTrans.xsl"
lambda-alias-name           = "LIVE"

# Existing vpc info
vpc-id            = "vpc-057886e0bdd7c4e43"
subnet-id         = "subnet-02c0767268df8f171"
security-group-id = "sg-032f9f202ea602d21"

releases-root-directory-path = "/data"
efs-name                     = "cudl-data-releases"

