variable "transkribus-bucket-name" {
  description = "The name of the s3 bucket that stores the Transkribus transcriptions. Will be prefixed with the environment value."
}

variable "environment" {
description = "The environment you're working with. Should be one of: dev, staging, live."
type        = string
default     = "dev"
}