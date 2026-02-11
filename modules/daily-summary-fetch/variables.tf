variable "name_prefix" {
  description = "Prefix to use for naming the Lambda, log group, and EventBridge rule"
  type        = string
}

variable "target_url" {
  description = "URL to fetch and store in S3"
  type        = string
}

variable "schedule_expression" {
  description = "CloudWatch Events schedule expression (e.g. rate(1 day) or cron(...))"
  type        = string
  default     = "rate(1 day)"
}

variable "results_bucket_name" {
  description = "Name of the existing S3 bucket to store the fetched summary in"
  type        = string
}

variable "results_key_prefix" {
  description = "Optional key prefix within the S3 bucket for stored summaries"
  type        = string
  default     = "cudl-summary/"
}

