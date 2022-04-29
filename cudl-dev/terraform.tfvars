environment                  = "dev"
destination-bucket-name      = "cudl-data-releases"
transcriptions-bucket-name   = "cudl-transcriptions"
source-bucket-name           = "cudl-data-source"
compressed-lambdas-directory = "compressed_lambdas"
lambda-jar-bucket            = "mvn.cudl.lib.cam.ac.uk"
lambda-layer-name            = "cudl-xslt-layer"
lambda-layer-bucket          = "cudl-artefacts"
lambda-layer-filepath        = "projects/cudl-data-processing/xslt/cudl-transform-xslt.zip"
transform-lambda-information = [
  {
    "name"          = "AWSLambda_CUDLPackageData_TEI_to_JSON"
    "jar_path"      = "release/uk/ac/cam/lib/cudl/awslambda/AWSLambda_Data_Transform/0.5/AWSLambda_Data_Transform-0.5-jar-with-dependencies.jar"
    "queue_name"    = "CUDLPackageDataQueue"
    "transcription" = false
    "filter_prefix" = "items/data/tei/"
    "filter_suffix" = ".xml"
    "handler"       = "uk.ac.cam.lib.cudl.awslambda.handlers.XSLTTransformRequestHandler::handleRequest"
    "runtime"       = "java11"
    "live_version"  = 5
  },
  {
    "name"          = "AWSLambda_CUDLPackageData_HTML_to_HTML_Translate_URLS"
    "jar_path"      = "release/uk/ac/cam/lib/cudl/awslambda/AWSLambda_Data_Transform/0.5/AWSLambda_Data_Transform-0.5-jar-with-dependencies.jar"
    "queue_name"    = "CUDLPackageDataQueue_HTML"
    "transcription" = false
    "filter_prefix" = "pages/html/"
    "filter_suffix" = ".html"
    "handler"       = "uk.ac.cam.lib.cudl.awslambda.handlers.ConvertHTMLIdsHandler::handleRequest"
    "runtime"       = "java11"
    "live_version"  = 5
  },
  {
    "name"          = "AWSLambda_CUDLPackageData_FILE_UNCHANGED_COPY"
    "jar_path"      = "release/uk/ac/cam/lib/cudl/awslambda/AWSLambda_Data_Transform/0.5/AWSLambda_Data_Transform-0.5-jar-with-dependencies.jar"
    "queue_name"    = "CUDLPackageDataQueue_FILES_UNCHANGED_COPY"
    "transcription" = false
    "filter_prefix" = "pages/images/"
    "other_filters" = "cudl.dl-dataset.json|cudl.ui.json"
    "handler"       = "uk.ac.cam.lib.cudl.awslambda.handlers.CopyFileHandler::handleRequest"
    "runtime"       = "java11"
    "live_version"  = 5
  },
  {
    "name"          = "AWSLambda_CUDLPackageData_JSON_to_JSON_Translate_URLS"
    "jar_path"      = "release/uk/ac/cam/lib/cudl/awslambda/AWSLambda_Data_Transform/0.5/AWSLambda_Data_Transform-0.5-jar-with-dependencies.jar"
    "queue_name"    = "CUDLPackageDataQueue_Collections"
    "transcription" = false
    "filter_prefix" = "collections/"
    "filter_suffix" = ".json"
    "handler"       = "uk.ac.cam.lib.cudl.awslambda.handlers.ConvertJSONIdsHandler::handleRequest"
    "runtime"       = "java11"
    "live_version"  = 5
  },
  {
    "name"          = "AWSLambda_CUDLGenerateTranscriptionHTML_AddEvent"
    "jar_path"      = "release/uk/ac/cam/lib/cudl/awslambda/AWSLambda_CUDLGenerateTranscriptionHTML/0.1/AWSLambda_CUDLGenerateTranscriptionHTML-0.1-jar-with-dependencies.jar"
    "queue_name"    = "CUDLTranscriptionsQueue"
    "transcription" = true
    "filter_prefix" = "items/data/tei/"
    "filter_suffix" = ".xml"
    "handler"       = "uk.ac.cam.lib.cudl.awslambda.AWSLambda_CUDLGenerateTranscriptionHTML_AddEvent::handleRequest"
    "runtime"       = "java11"
    "live_version"  = 4
  }
]
db-lambda-information = [
  {
    "name"          = "AWSLambda_CUDLPackageData_UPDATE_DB"
    "jar_path"      = "release/uk/ac/cam/lib/cudl/awslambda/AWSLambda_Data_Transform/0.5/AWSLambda_Data_Transform-0.5-jar-with-dependencies.jar"
    "queue_name"    = "CUDLPackageDataUpdateDBQueue"
    "filter_prefix" = "collections/"
    "filter_suffix" = ".json"
    "handler"       = "uk.ac.cam.lib.cudl.awslambda.handlers.CollectionFileDBHandler::handleRequest"
    "runtime"       = "java11"
    "live_version"  = 5
  },
  {
    "name"          = "AWSLambda_CUDLPackageData_DATASET_JSON"
    "jar_path"      = "release/uk/ac/cam/lib/cudl/awslambda/AWSLambda_Data_Transform/0.5/AWSLambda_Data_Transform-0.5-jar-with-dependencies.jar"
    "queue_name"    = "CUDLPackageDataDatasetQueue"
    "filter_suffix" = "cudl.dl-dataset.json"
    "handler"       = "uk.ac.cam.lib.cudl.awslambda.handlers.DatasetFileDBHandler::handleRequest"
    "runtime"       = "java11"
    "live_version"  = 5
  },
  {
    "name"          = "AWSLambda_CUDLPackageData_UI_JSON"
    "jar_path"      = "release/uk/ac/cam/lib/cudl/awslambda/AWSLambda_Data_Transform/0.5/AWSLambda_Data_Transform-0.5-jar-with-dependencies.jar"
    "queue_name"    = "CUDLPackageDataUIQueue"
    "filter_suffix" = "cudl.ui.json"
    "handler"       = "uk.ac.cam.lib.cudl.awslambda.handlers.UIFileDBHandler::handleRequest"
    "runtime"       = "java11"
    "live_version"  = 5
  }
]
dst-efs-prefix               = "/mnt/cudl-data-releases"
dst-prefix                   = "html/"
dst-s3-prefix                = ""
tmp-dir                      = "/tmp/dest"
large-file-limit             = 1000000
chunks                       = 4
data-function-name           = "AWSLambda_CUDLPackageDataJSON_AddEvent"
transcription-function-name  = "AWSLambda_CUDLGenerateTranscriptionHTML_AddEvent"
lambda-alias-name            = "LIVE"

# Existing vpc info
vpc-id                       = "vpc-ab7880ce"
cidr-blocks                  = ["10.0.0.0/24", "10.1.0.0/16"]
vpc-name                     = "CUDL-NETBLOCK"
domain-name                  = "internal.cudl.lib.cam.ac.uk"
dchp-options-name            = "cudl internal domain 3"
releases-root-directory-path = "/data"
efs-name                     = "cudl-data-releases"

