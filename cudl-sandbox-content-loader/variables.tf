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

variable "content-loader-domain" {
  description = "Domain to use for the content loader"
  type        = string
}