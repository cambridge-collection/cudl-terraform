variable "deployment-aws-region" {
  description = "The AWS region to deploy resources to"
  type        = string
  default     = "eu-west-1"
}

variable "aws-account-number" {
  description = "Account number for AWS.  Used to build arn values"
  type        = string
}

variable "environment" {
  description = "The environment you're working with. Should be one of: dev, staging, live."
  type        = string
  default     = "staging"
}

variable "db-only-processing" {
  description = "true for when we just want release s3 and lambdas e.g. for production environment"
  type        = bool
}

variable "source-bucket-name" {
  description = "The name of the s3 bucket that stores the source CUDL files (pre-processing). Will be prefixed with the environment value."
  type        = string
}

variable "destination-bucket-name" {
  description = "The name of the s3 bucket that stores the final CUDL files (post-processing). Will be prefixed with the environment value."
  type        = string
}

variable "transcriptions-bucket-name" {
  description = "The name of the s3 bucket that stores the HTMl transcriptions (post-processing). Will be prefixed with the environment value."
}

variable "distribution-bucket-name" {
  description = "The name of the s3 bucket that stores the output of the data processing pipeline. Will be prefixed with the environment value."
}

variable "compressed-lambdas-directory" {
  description = "The name of the local directory where the CUDL lambdas can be found"
  type        = string
}

variable "lambda-jar-bucket" {
  description = "The name of the s3 bucket that holds the lambda jars"
  type        = string
}

variable "lambda-layer-name" {
  description = "The name to be given to the XSLT transform layer"
  type        = string
}

variable "lambda-layer-bucket" {
  description = "The s3 bucket in which the XSLT layer ZIP can be found"
  type        = string
}

variable "lambda-layer-filepath" {
  description = "The full path to the XSLT layer ZIP, found in the `lambda-layer-bucket`"
  type        = string
}

variable "lambda-db-jdbc-driver" {
  description = "The driver used for cudl db connection.  Usually org.postgresql.Driver"
  type        = string
}

variable "lambda-db-url" {
  description = "The url used for cudl db connection.  Has placeholders in for <HOST> and <PORT>."
  type        = string
}

variable "lambda-db-secret-key" {
  description = "The path to the secret key that's used to access the cudl db credentials"
  type        = string
}

variable "transform-lambda-information" {
  description = "A list of maps containing information about the transformation lambda functions"
  type = list(object({
    name                  = string
    timeout               = number
    memory                = number
    queue_name            = string
    jar_path              = optional(string)
    transcription         = optional(bool)
    handler               = optional(string)
    runtime               = optional(string)
    environment_variables = optional(map(string))
    image_uri             = optional(string)
    batch_size            = optional(number)
    batch_window          = optional(number)
  }))
}

variable "db-lambda-information" {
  description = "A list of maps containing information about the database lambda functions"
  type        = list(any)
}

variable "dst-efs-prefix" {
  description = "Use to set the DST_EFS_PREFIX variable in the properties file passed to the lambda layer"
  type        = string
}

variable "dst-prefix" {
  description = "Use to set the DST_PREFIX variable in the properties file passed to the lambda layer"
  type        = string
}

variable "dst-s3-prefix" {
  description = "Use to set the DST_S3_PREFIX variable in the properties file passed to the lambda layer"
  type        = string
}

variable "tmp-dir" {
  description = "Use to set the TMP_DIR variable in the properties file passed to the lambda layer"
  type        = string
}

variable "large-file-limit" {
  description = "Use to set the LARGE_FILE_LIMIT variable in the properties file passed to the lambda layer"
  type        = number
}

variable "chunks" {
  description = "Use to set the CHUNKS variable in the properties file passed to the lambda layer"
  type        = number
}

variable "data-function-name" {
  description = "Use to set the FUNCTION_NAME variable in the properties file passed to the lambda layer, for lambdas from the `cudl-lambda-transform` repository"
  type        = string
}

variable "transcription-function-name" {
  description = "Use to set the FUNCTION_NAME variable in the properties file passed to the lambda layer, for lambdas from the `transcription-lambda-transform` repository"
  type        = string
}

variable "transcription-pagify-xslt" {
  description = "Use to set the path to pagify xslt in /opt (from layer)"
  type        = string
}

variable "transcription-mstei-xslt" {
  description = "Use to set the path to mstei xslt in /opt (from layer)"
  type        = string
}

variable "lambda-alias-name" {
  description = "Use to set the name for the lambda function alias(es)"
  type        = string
}

variable "vpc-id" {
  description = "Specify a id of an existing VPC to use"
  type        = string
}

variable "subnet-id" {
  description = "Specify an existing subnet id for cudl vpn"
  type        = string
}

variable "security-group-id" {
  description = "Specify an existing security group id for cudl vpn"
  type        = string
}

variable "releases-root-directory-path" {
  description = "Specify the root path for the releases access point in the EFS"
  type        = string
}

variable "efs-name" {
  description = "Specify the name of the EFS. This will be set as a tag, prefixed by the environment"
  type        = string
}

variable "source-bucket-sns-notifications" {
  description = "List of SNS notifications on source s3 bucket"
  type        = list(any)
}

variable "source-bucket-sqs-notifications" {
  description = "List of SQS notifications on source s3 bucket"
  type        = list(any)
}

variable "datadog-layer-1-arn" {
  description = "Required layer for datadog"
  type        = string
  default     = "arn:aws:lambda:eu-west-1:464622532012:layer:dd-trace-java:4"
}

variable "datadog-layer-2-arn" {
  description = "Required layer for datadog"
  type        = string
  default     = "arn:aws:lambda:eu-west-1:464622532012:layer:Datadog-Extension:23"
}

variable "additional_lambda_environment_variables" {
  description = "Additional environment variables"
  type        = map(string)
  default     = {}
}

variable "lambda_environment_datadog_variables" {
  description = "Environment variables for DataDog"
  type        = map(string)
  default = {
    DD_API_KEY_SECRET_ARN = "datadog_api",
    DD_JMXFETCH_ENABLED   = false,
    DD_SITE               = "https://app.datadoghq.eu",
    DD_TRACE_ENABLED      = true,
    JAVA_TOOL_OPTIONS     = "-javaagent:\"/opt/java/lib/dd-java-agent.jar\" -XX:+TieredCompilation -XX:TieredStopAtLevel=1"
  }
}

