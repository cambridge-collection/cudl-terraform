environment                          = "staging"
project                              = "CUDL"
component                            = "cudl-data-workflows"
subcomponent                         = "cudl-transform-lambda"
aws-account-number                   = "247242244017"
destination-bucket-name              = "cudl-data-releases"
transcriptions-bucket-name           = "cudl-transcriptions"
transkribus-bucket-name              = "cudl-data-enhancements"
enhancements-destination-bucket-name = "cudl-data-source"
source-bucket-name                   = "cudl-data-source"
distribution-bucket-name             = "cudl-dist"
compressed-lambdas-directory         = "compressed_lambdas"
lambda-jar-bucket                    = "mvn.cudl.lib.cam.ac.uk"
lambda-layer-name                    = "cudl-xslt-layer"
enhancements-lambda-layer-name       = "cudl-transkribus-xslt-layer"
lambda-layer-bucket                  = "cudl-artefacts"
lambda-layer-filepath                = "projects/cudl-data-processing/xslt/cudl-transform-xslt-0.0.16.zip"
enhancements-lambda-layer-filepath   = "projects/curious-cures/xslt/curious-cures-xslt-0.0.2.zip"
lambda-db-jdbc-driver                = "org.postgresql.Driver"
lambda-db-url                        = "jdbc:postgresql://<HOST>:<PORT>/staging_cudl_viewer?autoReconnect=true"
lambda-db-secret-key                 = "staging/cudl/cudl_viewer_db"

// NOTE: If you are adding anything here you need to add a code block to
// the s3.tf file
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
  }
]
transform-lambda-information = [
  {
    "name"          = "AWSLambda_CUDLPackageData_TEI_to_JSON"
    "description"   = "Transforms the CUDL TEI into JSON format for the cudl viewer to consume"
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
    "name"          = "AWSLambda_CUDLGenerateTranscriptionHTML_AddEvent"
    "description"   = "Generates transcription HTML from the CUDL TEI for display"
    "jar_path"      = "release/uk/ac/cam/lib/cudl/awslambda/AWSLambda_Data_Transform/0.16/AWSLambda_Data_Transform-0.16-jar-with-dependencies.jar"
    "queue_name"    = "CUDLTranscriptionsQueue"
    "transcription" = true
    "timeout"       = 900
    "memory"        = 1024
    "handler"       = "uk.ac.cam.lib.cudl.awslambda.handlers.GenerateTranscriptionHTMLHandler::handleRequest"
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
  {
    "name"          = "AWSLambda_CUDLPackageData_UPDATE_DB"
    "description"   = "Updates the CUDL database with collection information from the collections json file"
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
    "description"   = "Transforms the dataset json file into a json format with suitable paths for the viewer / db"
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
    "description"   = "Transforms the UI json file into a json format with suitable paths for the viewer / db"
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
vpc-id            = "vpc-ab7880ce"
subnet-id         = "subnet-fa1ed08d"
security-group-id = "sg-b79833d2"

releases-root-directory-path = "/data"
efs-name                     = "cudl-data-releases"

