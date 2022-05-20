environment                  = "production"
db-only-processing           = true
aws-account-number           = "247242244017"
destination-bucket-name      = "cudl-data-releases"
transcriptions-bucket-name   = "cudl-transcriptions"
source-bucket-name           = "cudl-data-source"
compressed-lambdas-directory = "compressed_lambdas"
lambda-jar-bucket            = "mvn.cudl.lib.cam.ac.uk"
lambda-layer-name            = "cudl-xslt-layer"
lambda-layer-bucket          = "cudl-artefacts"
lambda-layer-filepath        = "projects/cudl-data-processing/xslt/cudl-transform-xslt.zip"
lambda-db-jdbc-driver        = "org.postgresql.Driver"
lambda-db-url                = "jdbc:postgresql://<HOST>:<PORT>/production_cudl_viewer?autoReconnect=true"
lambda-db-secret-key         = "production/cudl/cudl_viewer_db"

source-bucket-sns-notifications  = [
]
source-bucket-sqs-notifications  = [
]
transform-lambda-information = [
]
db-lambda-information = [
  {
    "name"          = "AWSLambda_CUDLPackageData_UPDATE_DB"
    "jar_path"      = "release/uk/ac/cam/lib/cudl/awslambda/AWSLambda_Data_Transform/0.6/AWSLambda_Data_Transform-0.6-jar-with-dependencies.jar"
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
    "jar_path"      = "release/uk/ac/cam/lib/cudl/awslambda/AWSLambda_Data_Transform/0.6/AWSLambda_Data_Transform-0.6-jar-with-dependencies.jar"
    "queue_name"    = "CUDLPackageDataDatasetQueue"
    "timeout"       = 900
    "memory"        = 512
    "filter_prefix" = "cudl.dl-dataset.json"
    "handler"       = "uk.ac.cam.lib.cudl.awslambda.handlers.DatasetFileDBHandler::handleRequest"
    "runtime"       = "java11"
  },
  {
    "name"          = "AWSLambda_CUDLPackageData_UI_JSON"
    "jar_path"      = "release/uk/ac/cam/lib/cudl/awslambda/AWSLambda_Data_Transform/0.6/AWSLambda_Data_Transform-0.6-jar-with-dependencies.jar"
    "queue_name"    = "CUDLPackageDataUIQueue"
    "timeout"       = 900
    "memory"        = 512
    "filter_prefix" = "cudl.ui.json"
    "handler"       = "uk.ac.cam.lib.cudl.awslambda.handlers.UIFileDBHandler::handleRequest"
    "runtime"       = "java11"
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
transcription-pagify-xslt    = "/opt/xslt/transcription/pagify.xsl"
transcription-mstei-xslt     = "/opt/xslt/transcription/msTeiTrans.xsl"
lambda-alias-name            = "LIVE"

# Existing vpc info
vpc-id                       = "vpc-ab7880ce"
subnet-id                    = "subnet-fa1ed08d"
security-group-id            = "sg-b79833d2"

releases-root-directory-path = "/data"
efs-name                     = "cudl-data-releases"

