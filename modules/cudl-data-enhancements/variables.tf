variable "deployment-aws-region" {
  description = "The AWS region to deploy resources to"
  type        = string
  default     = "eu-west-1"
}

variable "aws-account-number" {
  description = "Account number for AWS.  Used to build arn values"
  type        = string
}

variable "transkribus-bucket-name" {
  description = "The name of the s3 bucket that stores the Transkribus transcriptions. Will be prefixed with the environment value."
}

variable "environment" {
  description = "The environment you're working with. Should be one of: dev, staging, live."
  type        = string
  default     = "dev"
}

variable "enhancements-lambda-information" {
  description = "A map containing information about the enhancements lambda functions"
  type        = list(any)
}

variable "lambda-jar-bucket" {
  description = "The name of the s3 bucket that holds the lambda jars"
  type        = string
}

variable "enhancements-lambda-layer-name" {
  description = "The name to be given to the XSLT Transkribus transform layer"
  type        = string
}

variable "lambda-layer-bucket" {
  description = "The s3 bucket in which the XSLT layer ZIP can be found"
  type        = string
}

variable "enhancements-lambda-layer-filepath" {
  description = "The full path to the Transkribus XSLT layer ZIP, found in the `lambda-layer-bucket`"
  type        = string
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

variable "subnet-id" {
  description = "Specify an existing subnet id for cudl vpn"
  type        = string
}

variable "security-group-id" {
  description = "Specify an existing security group id for cudl vpn"
  type        = string
}

variable "efs-name" {
  description = "Specify the name of the EFS. This will be set as a tag, prefixed by the environment"
  type        = string
}

variable "releases-root-directory-path" {
  description = "Specify the root path for the releases access point in the EFS"
  type        = string
}

variable "dst-efs-prefix" {
  description = "Use to set the DST_EFS_PREFIX variable in the properties file passed to the lambda layer"
  type        = string
}

variable "enhancements-dst-s3-prefix" {
  description = "Use to set the DST_S3_PREFIX variable in the properties file passed to the enhancements lambda layer"
  type        = string
}

variable "enhancements-destination-bucket-name" {
  description = "The name of the s3 bucket that stores the source CUDL files (before processing). Will be prefixed with the environment value."
  type        = string
}

variable "tmp-dir" {
  description = "Use to set the TMP_DIR variable in the properties file passed to the lambda layer"
  type        = string
}
