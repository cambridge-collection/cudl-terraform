variable "environment" {
  type        = string
  description = "The environment you're working with. Live | Staging | Development | All"
}

variable "project" {
  type        = string
  description = "Project or Service name, e.g. DPS, CUDL, Darwin"
}

variable "component" {
  type        = string
  description = "e.g. Deposit Service | All"
}

variable "subcomponent" {
  type        = string
  description = "If applicable: any value, e.g. Fedora"
}

variable "deployment-aws-region" {
  description = "The AWS region to deploy resources to"
  type        = string
  default     = "eu-west-1"
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

variable "enhancements-bucket-name" {
  description = "The name of the s3 bucket that stores the Transkribus transcriptions. Will be prefixed with the environment value."
}

variable "compressed-lambdas-directory" {
  description = "The name of the local directory where the CUDL lambdas can be found"
  type        = string
}

variable "lambda-jar-bucket" {
  description = "The name of the s3 bucket that holds the lambda jars"
  type        = string
}

variable "transform-lambda-information" {
  description = "A list of objects containing information about the transformation lambda functions"
  type = list(object({
    name                           = string
    timeout                        = number
    memory                         = number
    queue_name                     = string
    vpc_name                       = optional(string)
    subnet_names                   = optional(list(string), [])
    security_group_names           = optional(list(string), [])
    description                    = optional(string)
    jar_path                       = optional(string)
    handler                        = optional(string)
    runtime                        = optional(string)
    environment_variables          = optional(map(string))
    image_uri                      = optional(string)
    batch_size                     = optional(number)
    batch_window                   = optional(number)
    maximum_concurrency            = optional(number)
    command                        = optional(string)
    entry_point                    = optional(string)
    working_directory              = optional(string)
    sqs_max_tries_before_deadqueue = optional(number)
    queue_delay_seconds            = optional(number, 0)
    use_datadog_variables          = optional(bool, true)
    use_additional_variables       = optional(bool, false)
    use_enhancements_variables     = optional(bool, false)
    mount_fs                       = optional(bool, false)
    ephemeral_storage              = optional(number, 512)
  }))
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

variable "lambda-alias-name" {
  description = "Use to set the name for the lambda function alias(es)"
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

variable "transform-lambda-bucket-sns-notifications" {
  description = "List of SNS notifications on an s3 bucket"
  type        = list(any)
}

variable "transform-lambda-bucket-sqs-notifications" {
  description = "List of SQS notifications on an s3 bucket"
  type        = list(any)
}

variable "data_processing_efs_throughput_mode" {
  type        = string
  description = "Throughput mode for the file system. Valid values: bursting, provisioned, or elastic"
}

variable "data_processing_efs_provisioned_throughput" {
  type        = number
  description = "The throughput, measured in MiB/s, that you want to provision for the file system"
}

variable "create_cloudfront_distribution" {
  description = "Whether to create a CloudFront distribution for access to the dest-bucket"
  type        = string
  default     = true
}

variable "cloudfront_route53_zone_id" {
  description = "Route 53 Zone ID for CloudFront distribution"
  type        = string
  default     = null
}

variable "cluster_name_suffix" {
  type        = string
  description = "Name suffix of the ECS Cluster"
}

variable "ec2_instance_type" {
  type        = string
  description = "EC2 Instance type used by EC2 Instances"
  default     = "t3.medium"
}

variable "asg_max_size" {
  type        = number
  description = "Maximum number of instances in the Autoscaling Group"
}

variable "asg_desired_capacity" {
  type        = number
  description = "Desired number of instances in the Autoscaling Group"
}

variable "asg_allow_all_egress" {
  type        = bool
  description = "Whether to allow EC2 instances in ASG egress to all targets"
}

variable "vpc_cidr_block" {
  type        = string
  description = "CIDR block for the base architecture VPC"
}

variable "vpc_public_subnet_public_ip" {
  type        = bool
  description = "Whether to automatically assign public IP addresses in the public subnets"
}

variable "vpc_endpoint_services" {
  type        = list(string)
  description = "List of services to create VPC Endpoints for"
}

variable "vpc_peering_vpc_ids" {
  type        = list(string)
  description = "List of VPC IDS for peering with the base architecture VPC"
  default     = []
}

variable "registered_domain_name" {
  type        = string
  description = "Registered Domain Name"
}

variable "route53_zone_id_existing" {
  type        = string
  description = "ID of an existing Route 53 Hosted zone as an alternative to creating a hosted zone"
}

variable "acm_certificate_arn" {
  type        = string
  description = "ARN of an existing ACM certificate suitable for the Route 53 domain"
}

variable "acm_certificate_arn_us-east-1" {
  type        = string
  description = "ARN of an existing ACM certificate in us-east-1 region suitable for the Route 53 domain"
}

variable "route53_zone_force_destroy" {
  type        = bool
  description = "Whether to destroy all records (possibly managed outside of Terraform) in the zone when destroying the zone"
}

variable "alb_enable_deletion_protection" {
  type        = bool
  description = "Whether to enable deletion protection for the ALB"
}

variable "alb_idle_timeout" {
  type        = string
  description = "Time in seconds that the client connection is allowed to be idle"
}

variable "cloudwatch_log_group" {
  type        = string
  description = "Name of the cloudwatch log group"
}

variable "cloudwatch_log_destination_arn" {
  type        = string
  description = "ARN of a CloudWatch Log Destination"
}

variable "content_loader_name_suffix" {
  type        = string
  description = "Suffix to add to Content Loader resource names"
}

variable "content_loader_domain_name" {
  type        = string
  description = "Domain Name for the Content Loader service"
}

variable "content_loader_application_port" {
  type        = number
  description = "Port number to be used for the Content Loader application"
}

variable "content_loader_target_group_port" {
  type        = number
  description = "Port number to be used for the Content Loader Target Group"
}

variable "content_loader_ecr_repositories" {
  type        = map(string)
  description = "Map of ECR Repository name and digest values for Content Loader"
}

variable "content_loader_ecs_task_def_volumes" {
  type        = map(string)
  description = "Map of volume names and container paths to attach to the Content Loader ECS Task Definition"
}

variable "content_loader_container_name_ui" {
  type        = string
  description = "Name of the Content Loader UI container"
}

variable "content_loader_container_name_db" {
  type        = string
  description = "Name of the Content Loader DB container"
}

variable "content_loader_health_check_status_code" {
  type        = string
  description = "HTTP Status Code to use in target group health check"
}

variable "content_loader_allowed_methods" {
  type        = list(string)
  description = "List of methods allowed by the CloudFront Distribution"
}

variable "content_loader_releases_bucket_production" {
  type        = string
  description = "Name of the production releases bucket for content loader deployments"
}

variable "content_loader_waf_common_ruleset_override_actions" {
  type        = list(string)
  description = "List of rules in the AWS WAF Core rule set (CRS) managed rule group to override"
}

variable "content_loader_cloudfront_origin_read_timeout" {
  type        = number
  description = "CloudFront origin response timeout for Content Loader"
}

variable "content_loader_ecs_task_def_memory" {
  type        = number
  description = "Amount (in MiB) of memory used by the Content loader tasks"
}

variable "solr_name_suffix" {
  type        = string
  description = "Suffix to add to SOLR resource names"
}

variable "solr_domain_name" {
  type        = string
  description = "Domain Name for the SOLR service"
}

variable "solr_application_port" {
  type        = number
  description = "Port number to be used for the SOLR application"
}

variable "solr_target_group_port" {
  type        = number
  description = "Port number to be used for the SOLR Target Group"
}

variable "solr_ecr_repositories" {
  type        = map(string)
  description = "Map of ECR Repository name and digest values for SOLR"
}

variable "solr_ecs_task_def_volumes" {
  type        = map(string)
  description = "Map of volume names and container paths to attach to the SOLR ECS Task Definition"
}

variable "solr_container_name_api" {
  type        = string
  description = "Name of the SOLR API container"
}

variable "solr_container_name_solr" {
  type        = string
  description = "Name of the SOLR container"
}

variable "solr_health_check_status_code" {
  type        = string
  description = "HTTP Status Code to use in target group health check"
}

variable "solr_allowed_methods" {
  type        = list(string)
  description = "List of methods allowed by the CloudFront Distribution"
}

variable "solr_ecs_task_def_cpu" {
  type        = number
  description = "Number of cpu units used by the SOLR tasks"
}

variable "solr_ecs_task_def_memory" {
  type        = number
  description = "Amount (in MiB) of memory used by the SOLR tasks"
}

variable "solr_use_service_discovery" {
  type        = bool
  description = "Whether SOLR should use Service Discovery"
}

variable "cudl_services_name_suffix" {
  type        = string
  description = "Suffix to add to CUDL services resource names"
}

variable "cudl_services_domain_name" {
  type        = string
  description = "Domain Name for the CUDL services service"
}

variable "cudl_services_target_group_port" {
  type        = number
  description = "Port number to be used for the CUDL services Target Group"
}

variable "cudl_services_container_port" {
  type        = number
  description = "Port number to be used for the CUDL services Container"
}

variable "cudl_services_ecr_repositories" {
  type        = map(string)
  description = "Map of ECR Repository name and digest values for CUDL Services"
}


variable "cudl_services_health_check_status_code" {
  type        = string
  description = "HTTP Status Code to use in target group health check"
}

# variable "cudl_services_ecs_task_def_volumes" {
#   type        = map(string)
#   description = "Map of volume names and container paths to attach to the CUDL Services ECS Task Definition"
# }

variable "cudl_services_allowed_methods" {
  type        = list(string)
  description = "List of methods allowed by the CloudFront Distribution"
}

variable "cudl_viewer_name_suffix" {
  type        = string
  description = "Suffix to add to CUDL viewer resource names"
}

variable "cudl_viewer_domain_name" {
  type        = string
  description = "Domain Name for the CUDL viewer service"
}

variable "cudl_viewer_target_group_port" {
  type        = number
  description = "Port number to be used for the CUDL viewer Target Group"
}

variable "cudl_viewer_container_port" {
  type        = number
  description = "Port number to be used for the CUDL viewer Container"
}

variable "cudl_viewer_ecr_repositories" {
  type        = map(string)
  description = "Map of ECR Repository name and digest values for CUDL viewer"
}


variable "cudl_viewer_health_check_status_code" {
  type        = string
  description = "HTTP Status Code to use in target group health check"
}

# variable "cudl_viewer_ecs_task_def_volumes" {
#   type        = map(string)
#   description = "Map of volume names and container paths to attach to the CUDL viewer ECS Task Definition"
# }

variable "cudl_viewer_allowed_methods" {
  type        = list(string)
  description = "List of methods allowed by the CloudFront Distribution"
}

variable "cudl_viewer_ecs_task_def_volumes" {
  type        = map(string)
  description = "Map of volume names and container paths to attach to the Cudl Viewer ECS Task Definition"
}

variable "cudl_viewer_datasync_task_s3_to_efs_pattern" {
  type        = string
  description = "Pattern regex used in S3 to EFS task"
}

variable "cudl_viewer_ecs_task_def_memory" {
  type        = number
  description = "Amount (in MiB) of memory used by the CUDL Viewer tasks"
}

variable "rti_image_server_name_suffix" {
  type        = string
  description = "Suffix for naming the RTI image server resources (e.g., for unique naming)."
}

variable "rti_image_server_bucket" {
  type        = string
  description = "Name of the S3 bucket used for storing RTI image server assets."
}

variable "rti_image_server_domain_name" {
  type        = string
  description = "Fully qualified domain name (FQDN) assigned to the RTI image server."
}

variable "rti_image_server_hosted_zone_domain" {
  type        = string
  description = "Base domain name of the hosted zone where the RTI image server record will be created."
}

variable "rti_image_server_route53_zone_id_existing" {
  type        = string
  description = "Existing Route 53 hosted zone ID to associate with the RTI image server domain."
}

variable "rti_image_server_cloudfront_viewer_response_function_arn" {
  type        = string
  description = "ARN of a CloudFront Function to add to CloudFront Distribution in Response"
  default     = null
}

variable "rti_image_server_cloudfront_cache_policy" {
  type        = string
  description = "Managed cache policy to use by default: 'optimized' (Managed-CachingOptimized) or 'disabled' (Managed-CachingDisabled)."
  default     = "optimized"

  validation {
    condition     = contains(["optimized", "disabled"], var.rti_image_server_cloudfront_cache_policy)
    error_message = "cloudfront_cache_policy must be 'optimized' or 'disabled'."
  }
}

variable "rti_image_server_cloudfront_origin_request_policy_name" {
  type        = string
  description = "Name of the CloudFront Origin Request Policy to use (e.g., Managed-CORS-S3Origin, Managed-AllViewer). If null, uses the managed S3+CORS policy."
  default     = null
}

variable "rti_image_server_cloudfront_response_headers_policy_name" {
  type        = string
  description = "Name of the CloudFront Response Headers Policy to attach (e.g., CORS-With-Preflight, SecurityHeadersPolicy). If null, none is attached."
  default     = null
}