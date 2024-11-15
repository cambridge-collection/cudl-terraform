variable "name_prefix" {
  type        = string
  description = "Name prefix of AWS resources"
}

variable "cloudwatch_log_group_name" {
  type        = string
  description = "Name of the CloudWatch log group to trigger the lambda"
}

variable "cloudwatch_log_subscription_filter_pattern" {
  type        = string
  description = "A valid CloudWatch Logs filter pattern for subscribing to a filtered stream of log events"
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
