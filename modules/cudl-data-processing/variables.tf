variable "deployment-aws-region" {
  description = "The AWS region to deploy resources to"
  type        = string
  default     = "eu-west-1"
}

variable "environment" {
  description = "The environment you're working with. Should be one of: dev, staging, live."
  type        = string
  default     = "dev"
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

variable "transform-lambda-information" {
  description = "A list of maps containing information about the transformation lambda functions"
  type        = list(any)
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

variable "lambda-alias-name" {
  description = "Use to set the name for the lambda function alias(es)"
  type        = string
}

variable "cidr-blocks" {
  description = "Specify the CIDR blocks to be used by the VPC"
  type        = list(string)
}

variable "vpc-id" {
  description = "Specify a id of an existing VPC to use"
  type        = string
}

variable "vpc-name" {
  description = "Specify a name to be given to the VPC"
  type        = string
}

variable "domain-name" {
  description = "Specify the domain name to be used in the VPC"
  type        = string
}

variable "dchp-options-name" {
  description = "Specify the name for the DCHP options set. To be prefixed by the environment."
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
