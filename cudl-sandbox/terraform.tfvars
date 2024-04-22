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
distribution-bucket-name             = "cudl-dist"
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

// NOTE: If you are adding anything here you need to add a code block to
// the s3.tf file
source-bucket-sns-notifications = [
  {
    "filter_prefix" = "items/data/tei/",
    "filter_suffix" = ".xml"
    "subscriptions" = [
      {
        "queue_name" = "CUDLPackageDataQueue_FILES_UNCHANGED_COPY",
        "raw"        = true
      },
      {
        "queue_name" = "CUDLPackageDataQueue",
        "raw"        = true
      },
      {
        "queue_name" = "CUDLTranscriptionsQueue",
        "raw"        = true
      },
    ]
  }
]
// NOTE: If you are adding anything here you need to add a code block to
// the s3.tf file
source-bucket-sqs-notifications = [
  {
    "type"          = "SQS",
    "queue_name"    = "CUDLPackageDataQueue_HTML",
    "filter_prefix" = "pages/html/",
    "filter_suffix" = ".html"
  },
  {
    "type"          = "SQS",
    "queue_name"    = "CUDLPackageDataQueue_FILES_UNCHANGED_COPY"
    "filter_prefix" = "pages/images/"
  },
  {
    "type"          = "SQS",
    "queue_name"    = "CUDLPackageDataQueue_FILES_UNCHANGED_COPY"
    "filter_prefix" = "cudl.dl-dataset"
    "filter_suffix" = ".json"
  },
  {
    "type"          = "SQS",
    "queue_name"    = "CUDLPackageDataQueue_FILES_UNCHANGED_COPY"
    "filter_prefix" = "cudl.ui"
    "filter_suffix" = ".json5"
  },
  {
    "type"          = "SQS",
    "queue_name"    = "CUDLPackageDataQueue_Collections"
    "filter_prefix" = "collections/"
    "filter_suffix" = ".json"
  },
  {
    "type"          = "SQS",
    "queue_name"    = "CUDLPackageDataQueue_FILES_UNCHANGED_COPY"
    "filter_prefix" = "ui/"
    "filter_suffix" = ""
  }
]
transform-lambda-information = [
  {
    "name"          = "AWSLambda_CUDLPackageData_TEI_to_JSON"
    "jar_path"      = "release/uk/ac/cam/lib/cudl/awslambda/AWSLambda_Data_Transform/0.16/AWSLambda_Data_Transform-0.16-jar-with-dependencies.jar"
    "queue_name"    = "CUDLPackageDataQueue"
    "transcription" = false
    "timeout"       = 900
    "memory"        = 512
    "handler"       = "uk.ac.cam.lib.cudl.awslambda.handlers.XSLTTransformRequestHandler::handleRequest"
    "runtime"       = "java11"
  },
  {
    "name"          = "AWSLambda_CUDLPackageData_HTML_to_HTML_Translate_URLS"
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
    "jar_path"      = "release/uk/ac/cam/lib/cudl/awslambda/AWSLambda_Data_Transform/0.16/AWSLambda_Data_Transform-0.16-jar-with-dependencies.jar"
    "queue_name"    = "CUDLPackageDataQueue_Collections"
    "transcription" = false
    "timeout"       = 900
    "memory"        = 512
    "handler"       = "uk.ac.cam.lib.cudl.awslambda.handlers.ConvertJSONIdsHandler::handleRequest"
    "runtime"       = "java11"
  },
  {
    "name"          = "AWSLambda_CUDLGenerateTranscriptionHTML_AddEvent"
    "jar_path"      = "release/uk/ac/cam/lib/cudl/awslambda/AWSLambda_Data_Transform/0.16/AWSLambda_Data_Transform-0.16-jar-with-dependencies.jar"
    "queue_name"    = "CUDLTranscriptionsQueue"
    "transcription" = true
    "timeout"       = 900
    "memory"        = 1024
    "handler"       = "uk.ac.cam.lib.cudl.awslambda.handlers.GenerateTranscriptionHTMLHandler::handleRequest"
    "runtime"       = "java11"
  },
  {
    "name"                     = "AWSLambda_CUDLPackageData_TEI_Processing"
    "image_uri"                = "563181399728.dkr.ecr.eu-west-1.amazonaws.com/cudl-tei-processing@sha256:9a7fdab4f5ee6ab637669cbdf46c4a5f59783b87566fcc884cd65686c605387d"
    "queue_name"               = "CUDLTranscriptionsQueue"
    "transcription"            = true
    "timeout"                  = 300
    "memory"                   = 4096
    "batch_window"             = 2
    "batch_size"               = 1
    "maximum_concurrency"      = 100
    "use_datadog_variables"    = false
    "use_additional_variables" = true
    "environment_variables" = {
      ANT_TARGET            = "full"
      COLLECTION_XML_SOURCE = "/tmp/opt/cdcp/dist-pending/collection-xml"
      CORE_XML_SOURCE       = "/tmp/opt/cdcp/dist-pending/core-xml"
      PAGE_XML_SOURCE       = "/tmp/opt/cdcp/dist-pending/page-xml"
    }
  }
]
enhancements-lambda-information = [{
  "name"          = "AWSLambda_CUDLDataEnhancements_TranskribusMergeTEI"
  "jar_path"      = "release/uk/ac/cam/lib/cudl/awslambda/AWSLambda_Data_Transform/0.16/AWSLambda_Data_Transform-0.16-jar-with-dependencies.jar"
  "queue_name"    = "CUDLTranskribusQueue"
  "transcription" = true
  "timeout"       = 900
  "memory"        = 512
  "handler"       = "uk.ac.cam.lib.cudl.awslambda.handlers.XSLTTransformRequestHandler::handleRequest"
  "runtime"       = "java11"
}]
db-lambda-information = [
  {
    "name"          = "AWSLambda_CUDLPackageData_UPDATE_DB"
    "jar_path"      = "release/uk/ac/cam/lib/cudl/awslambda/AWSLambda_Data_Transform/0.16/AWSLambda_Data_Transform-0.16-jar-with-dependencies.jar"
    "queue_name"    = "CUDLPackageDataUpdateDBQueue"
    "timeout"       = 900
    "memory"        = 512
    "filter_prefix" = "collections/"
    "filter_suffix" = ".json"
    "handler"       = "uk.ac.cam.lib.cudl.awslambda.handlers.CollectionFileDBHandler::handleRequest"
    "runtime"       = "java11"
  },
  {
    "name"          = "AWSLambda_CUDLPackageData_DATASET_JSON"
    "jar_path"      = "release/uk/ac/cam/lib/cudl/awslambda/AWSLambda_Data_Transform/0.16/AWSLambda_Data_Transform-0.16-jar-with-dependencies.jar"
    "queue_name"    = "CUDLPackageDataDatasetQueue"
    "timeout"       = 900
    "memory"        = 512
    "filter_prefix" = "cudl.dl-dataset.json"
    "handler"       = "uk.ac.cam.lib.cudl.awslambda.handlers.DatasetFileDBHandler::handleRequest"
    "runtime"       = "java11"
  },
  {
    "name"          = "AWSLambda_CUDLPackageData_UI_JSON"
    "jar_path"      = "release/uk/ac/cam/lib/cudl/awslambda/AWSLambda_Data_Transform/0.16/AWSLambda_Data_Transform-0.16-jar-with-dependencies.jar"
    "queue_name"    = "CUDLPackageDataUIQueue"
    "timeout"       = 900
    "memory"        = 512
    "filter_prefix" = "cudl.ui.json"
    "handler"       = "uk.ac.cam.lib.cudl.awslambda.handlers.UIFileDBHandler::handleRequest"
    "runtime"       = "java11"
  }
]
dst-efs-prefix              = "/mnt/cudl-data-releases"
dst-prefix                  = "html/"
dst-s3-prefix               = ""
enhancements-dst-s3-prefix  = "items/data/tei/"
tmp-dir                     = "/tmp/dest/"
large-file-limit            = 1000000
chunks                      = 4
data-function-name          = "AWSLambda_CUDLPackageDataJSON_AddEvent"
transcription-function-name = "AWSLambda_CUDLGenerateTranscriptionHTML_AddEvent"
transcription-pagify-xslt   = "/opt/xslt/transcription/pagify.xsl"
transcription-mstei-xslt    = "/opt/xslt/transcription/msTeiTrans.xsl"
lambda-alias-name           = "LIVE"

# Existing vpc info
vpc-id            = "vpc-057886e0bdd7c4e43"
subnet-id         = "subnet-0f2b1a30b3838d5f1"
security-group-id = "sg-032f9f202ea602d21"

releases-root-directory-path = "/data"
efs-name                     = "cudl-data-releases"

