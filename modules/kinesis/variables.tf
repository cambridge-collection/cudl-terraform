variable "name_prefix" {
  type        = string
  description = "Name prefix of AWS resources"
}

variable "s3_name_prefix" {
  type        = string
  description = "Name prefix of AWS S3 resources"
}

variable "cloudwatch_log_subscription_filter_pattern" {
  type        = string
  description = "Filter pattern for source log events"
  default     = ""
}

variable "s3_bucket_force_destroy" {
  type        = bool
  description = "Whether to allow a non-empty bucket to be destroyed"
  default     = false
}

variable "s3_bucket_versioning_enabled" {
  type        = bool
  description = "Whether to enable object versioning in the S3 bucket"
  default     = false
}
