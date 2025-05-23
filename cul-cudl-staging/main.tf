module "base_architecture" {
  source = "git::https://github.com/cambridge-collection/terraform-aws-architecture-ecs.git?ref=v2.3.0"

  name_prefix                    = local.base_name_prefix
  ec2_instance_type              = var.ec2_instance_type
  route53_zone_domain_name       = var.registered_domain_name
  route53_zone_id_existing       = var.route53_zone_id_existing
  route53_zone_force_destroy     = var.route53_zone_force_destroy
  asg_desired_capacity           = var.asg_desired_capacity
  asg_max_size                   = var.asg_max_size
  alb_enable_deletion_protection = var.alb_enable_deletion_protection
  alb_idle_timeout               = var.alb_idle_timeout
  vpc_public_subnet_public_ip    = var.vpc_public_subnet_public_ip
  cloudwatch_log_group           = var.cloudwatch_log_group # TODO create log group
  vpc_cidr_block                 = var.vpc_cidr_block
  acm_create_certificate         = false
  acm_certificate_arn            = var.acm_certificate_arn
  tags                           = local.default_tags
}

module "cudl-data-processing" {
  source                                    = "../modules/cudl-data-processing"
  compressed-lambdas-directory              = var.compressed-lambdas-directory
  destination-bucket-name                   = var.destination-bucket-name
  dst-efs-prefix                            = var.dst-efs-prefix
  dst-prefix                                = var.dst-prefix
  dst-s3-prefix                             = var.dst-s3-prefix
  efs-name                                  = var.efs-name
  efs_subnets                               = zipmap(["${local.base_name_prefix}-subnet-private-a", "${local.base_name_prefix}-subnet-private-b"], module.base_architecture.vpc_private_subnet_ids)
  efs_file_system_throughput_mode           = var.data_processing_efs_throughput_mode
  efs_file_system_provisioned_throughput    = var.data_processing_efs_provisioned_throughput
  lambda-alias-name                         = var.lambda-alias-name
  releases-root-directory-path              = var.releases-root-directory-path
  tmp-dir                                   = var.tmp-dir
  transform-lambda-information              = var.transform-lambda-information
  additional_lambda_environment_variables   = local.additional_lambda_variables
  enhancements_lambda_environment_variables = local.enhancements_lambda_variables
  vpc-id                                    = module.base_architecture.vpc_id
  vpcs                                      = { "${local.base_name_prefix}-vpc" = module.base_architecture.vpc_id }
  default-lambda-vpc                        = join("-", [local.base_name_prefix, "vpc"])
  lambda-jar-bucket                         = var.lambda-jar-bucket
  aws-account-number                        = data.aws_caller_identity.current.account_id
  transform-lambda-bucket-sns-notifications = var.transform-lambda-bucket-sns-notifications
  transform-lambda-bucket-sqs-notifications = var.transform-lambda-bucket-sqs-notifications
  environment                               = local.environment
  source-bucket-name                        = var.source-bucket-name
  enhancements-bucket-name                  = var.enhancements-bucket-name
  cloudfront_route53_zone_id                = var.cloudfront_route53_zone_id
  create_cloudfront_distribution            = var.create_cloudfront_distribution
  acm_create_certificate                    = false
  acm_certificate_arn                       = var.acm_certificate_arn_us-east-1
  providers = {
    aws.us-east-1 = aws.us-east-1
  }
}

module "content_loader" {
  source = "git::https://github.com/cambridge-collection/terraform-aws-workload-ecs.git?ref=v3.5.0"

  name_prefix                               = join("-", compact([local.environment, var.content_loader_name_suffix]))
  account_id                                = data.aws_caller_identity.current.account_id
  domain_name                               = join(".", [join("-", compact([var.environment, var.content_loader_domain_name])), var.registered_domain_name])
  alb_target_group_port                     = var.content_loader_target_group_port
  alb_target_group_health_check_status_code = var.content_loader_health_check_status_code
  ecr_repository_names                      = keys(var.content_loader_ecr_repositories)
  ecr_repositories_exist                    = true
  s3_task_buckets                           = [module.cudl-data-processing.source_bucket]
  s3_task_execution_bucket                  = module.base_architecture.s3_bucket
  s3_task_execution_additional_buckets      = [var.lambda-jar-bucket]
  ecs_task_def_container_definitions        = jsonencode(local.content_loader_container_defs)
  ecs_task_def_volumes                      = keys(var.content_loader_ecs_task_def_volumes)
  ecs_service_container_name                = local.content_loader_container_name_ui
  ecs_service_container_port                = var.content_loader_application_port
  ecs_service_capacity_provider_name        = module.base_architecture.ecs_capacity_provider_name
  s3_task_execution_bucket_objects = {
    "${var.environment}-cudl-loader-ui.env" = templatefile("${path.root}/templates/content-loader/cl-ui.env.ttfpl", {
      region                     = var.deployment-aws-region
      source_bucket              = module.cudl-data-processing.source_bucket
      releases_bucket            = module.cudl-data-processing.destination_bucket
      releases_bucket_production = var.content_loader_releases_bucket_production
    })
  }
  vpc_id                         = module.base_architecture.vpc_id
  vpc_subnet_ids                 = module.base_architecture.vpc_private_subnet_ids
  alb_arn                        = module.base_architecture.alb_arn
  alb_dns_name                   = module.base_architecture.alb_dns_name
  alb_listener_arn               = module.base_architecture.alb_https_listener_arn
  ecs_cluster_arn                = module.base_architecture.ecs_cluster_arn
  route53_zone_id                = module.base_architecture.route53_public_hosted_zone
  asg_name                       = module.base_architecture.asg_name
  asg_security_group_id          = module.base_architecture.asg_security_group_id
  alb_security_group_id          = module.base_architecture.alb_security_group_id
  cloudwatch_log_group_arn       = module.base_architecture.cloudwatch_log_group_arn
  cloudfront_waf_acl_arn         = aws_wafv2_web_acl.content_loader.arn # custom WAF ACL for Content Loader
  cloudfront_origin_read_timeout = var.content_loader_cloudfront_origin_read_timeout
  cloudfront_allowed_methods     = var.content_loader_allowed_methods
  iam_task_additional_policies = {
    staging_releases    = aws_iam_policy.staging_cudl_data_releases.arn,
    staging_source      = aws_iam_policy.staging_cudl_data_source.arn,
    production_releases = aws_iam_policy.production_cudl_data_releases.arn
  }
  efs_create_file_system        = true
  acm_create_certificate        = false
  acm_certificate_arn           = var.acm_certificate_arn
  acm_certificate_arn_us-east-1 = var.acm_certificate_arn_us-east-1
  tags                          = local.default_tags
  providers = {
    aws.us-east-1 = aws.us-east-1
  }
}

module "solr" {
  source = "git::https://github.com/cambridge-collection/terraform-aws-workload-ecs.git?ref=v3.5.0"

  name_prefix                                    = join("-", compact([local.environment, var.solr_name_suffix]))
  account_id                                     = data.aws_caller_identity.current.account_id
  domain_name                                    = join(".", [join("-", compact([var.environment, var.solr_domain_name])), var.registered_domain_name])
  alb_target_group_port                          = var.solr_target_group_port
  alb_target_group_health_check_status_code      = var.solr_health_check_status_code
  alb_target_group_deregistration_delay          = 60
  alb_target_group_health_check_interval         = 30
  alb_target_group_health_check_timeout          = 10
  ecr_repository_names                           = keys(var.solr_ecr_repositories)
  ecr_repositories_exist                         = true
  s3_task_buckets                                = [module.cudl-data-processing.destination_bucket]
  s3_task_execution_bucket                       = module.base_architecture.s3_bucket
  ecs_network_mode                               = "awsvpc"
  ecs_task_def_container_definitions             = jsonencode(local.solr_container_defs)
  ecs_task_def_volumes                           = keys(var.solr_ecs_task_def_volumes)
  ecs_task_def_cpu                               = var.solr_ecs_task_def_cpu
  ecs_task_def_memory                            = var.solr_ecs_task_def_memory
  ecs_service_container_name                     = local.solr_container_name_api
  ecs_service_container_port                     = var.solr_target_group_port
  ecs_service_capacity_provider_name             = module.base_architecture.ecs_capacity_provider_name
  ecs_service_deployment_minimum_healthy_percent = 0 # setting to 100 prevents deployments but keeps services running
  ecs_service_deployment_maximum_percent         = 100
  vpc_id                                         = module.base_architecture.vpc_id
  vpc_subnet_ids                                 = module.base_architecture.vpc_private_subnet_ids
  alb_arn                                        = module.base_architecture.alb_arn
  alb_dns_name                                   = module.base_architecture.alb_dns_name
  alb_listener_arn                               = module.base_architecture.alb_https_listener_arn
  ecs_cluster_arn                                = module.base_architecture.ecs_cluster_arn
  route53_zone_id                                = module.base_architecture.route53_public_hosted_zone
  asg_name                                       = module.base_architecture.asg_name
  asg_security_group_id                          = module.base_architecture.asg_security_group_id
  alb_security_group_id                          = module.base_architecture.alb_security_group_id
  cloudwatch_log_group_arn                       = module.base_architecture.cloudwatch_log_group_arn
  cloudfront_waf_acl_arn                         = aws_wafv2_web_acl.solr.arn # custom WAF ACL for SOLR
  cloudfront_allowed_methods                     = var.solr_allowed_methods
  allow_private_access                           = var.solr_use_service_discovery
  ingress_security_group_id                      = aws_security_group.solr.id
  efs_create_file_system                         = true
  acm_create_certificate                         = false
  acm_certificate_arn                            = var.acm_certificate_arn
  acm_certificate_arn_us-east-1                  = var.acm_certificate_arn_us-east-1
  tags                                           = local.default_tags
  providers = {
    aws.us-east-1 = aws.us-east-1
  }
}

module "cudl_services" {
  source = "git::https://github.com/cambridge-collection/terraform-aws-workload-ecs.git?ref=v3.5.0"

  name_prefix                               = join("-", compact([local.environment, var.cudl_services_name_suffix]))
  account_id                                = data.aws_caller_identity.current.account_id
  domain_name                               = join(".", [join("-", compact([var.environment, var.cudl_services_domain_name])), var.registered_domain_name])
  alb_target_group_port                     = var.cudl_services_target_group_port
  alb_target_group_health_check_status_code = var.cudl_services_health_check_status_code
  ecr_repository_names                      = keys(var.cudl_services_ecr_repositories)
  ecr_repositories_exist                    = true
  s3_task_execution_bucket                  = module.base_architecture.s3_bucket
  ecs_task_def_container_definitions        = jsonencode(local.cudl_services_container_defs)
  ecs_service_container_name                = local.cudl_services_container_name
  ecs_service_container_port                = var.cudl_services_container_port
  ecs_service_capacity_provider_name        = module.base_architecture.ecs_capacity_provider_name
  s3_task_buckets                           = [module.cudl-data-processing.destination_bucket]
  ssm_task_execution_parameter_arns         = [data.aws_ssm_parameter.database_password.arn, data.aws_ssm_parameter.apikey_darwin.arn, data.aws_ssm_parameter.basicauth_credentials.arn]
  vpc_id                                    = module.base_architecture.vpc_id
  alb_arn                                   = module.base_architecture.alb_arn
  alb_dns_name                              = module.base_architecture.alb_dns_name
  alb_listener_arn                          = module.base_architecture.alb_https_listener_arn
  ecs_cluster_arn                           = module.base_architecture.ecs_cluster_arn
  route53_zone_id                           = module.base_architecture.route53_public_hosted_zone
  asg_name                                  = module.base_architecture.asg_name
  asg_security_group_id                     = module.base_architecture.asg_security_group_id
  alb_security_group_id                     = module.base_architecture.alb_security_group_id
  cloudwatch_log_group_arn                  = module.base_architecture.cloudwatch_log_group_arn
  cloudfront_waf_acl_arn                    = module.base_architecture.waf_acl_arn
  cloudfront_allowed_methods                = var.cudl_services_allowed_methods
  acm_create_certificate                    = false
  acm_certificate_arn                       = var.acm_certificate_arn
  acm_certificate_arn_us-east-1             = var.acm_certificate_arn_us-east-1
  tags                                      = local.default_tags
  providers = {
    aws.us-east-1 = aws.us-east-1
  }
}

module "cudl_viewer" {
  source = "git::https://github.com/cambridge-collection/terraform-aws-workload-ecs.git?ref=v3.5.0"

  name_prefix                               = join("-", compact([local.environment, var.cudl_viewer_name_suffix]))
  account_id                                = data.aws_caller_identity.current.account_id
  domain_name                               = join(".", [join("-", compact([var.environment, var.cudl_viewer_domain_name])), var.registered_domain_name])
  alb_target_group_port                     = var.cudl_viewer_container_port
  alb_target_group_health_check_status_code = var.cudl_viewer_health_check_status_code
  ecr_repository_names                      = keys(var.cudl_viewer_ecr_repositories)
  ecr_repositories_exist                    = true
  s3_task_execution_bucket                  = module.base_architecture.s3_bucket
  ecs_network_mode                          = "awsvpc"
  ecs_task_def_container_definitions        = jsonencode(local.cudl_viewer_container_defs)
  ecs_task_def_volumes                      = keys(var.cudl_viewer_ecs_task_def_volumes)
  ecs_task_def_memory                       = var.cudl_viewer_ecs_task_def_memory
  ecs_service_container_name                = local.cudl_viewer_container_name
  ecs_service_container_port                = var.cudl_viewer_container_port
  ecs_service_capacity_provider_name        = module.base_architecture.ecs_capacity_provider_name
  s3_task_bucket_objects = {
    "${module.cudl_viewer.name_prefix}/cudl-global.properties" = templatefile("${path.root}/templates/viewer/cudl-global.properties.ttfpl", {
      smtp_host               = format("email-smtp.%s.amazonaws.com", var.deployment-aws-region)
      smtp_username           = data.aws_ssm_parameter.cudl_viewer_smtp_username.value
      smtp_password           = data.aws_ssm_parameter.cudl_viewer_smtp_password.value
      smtp_port               = data.aws_ssm_parameter.cudl_viewer_smtp_port.value
      recaptcha_sitekey       = data.aws_ssm_parameter.cudl_viewer_recaptcha_sitekey.value
      recaptcha_secretkey     = data.aws_ssm_parameter.cudl_viewer_recaptcha_secretkey.value
      google_analytics_id     = data.aws_ssm_parameter.cudl_viewer_google_analytics_id.value
      ga4_google_analytics_id = data.aws_ssm_parameter.cudl_viewer_ga4_google_analytics_id.value
      mount_path              = var.cudl_viewer_ecs_task_def_volumes["cudl-viewer"]
      search_url              = format("http://%s:%s/", trimsuffix(module.solr.private_access_host, "."), var.solr_target_group_port)
      cudl_services_url       = module.cudl_services.link
      cudl_services_apikey    = data.aws_ssm_parameter.cudl_services_apikey.value
      root_url                = module.cudl_viewer.link
      json_url                = format("%s/json/", module.cudl_viewer.link)
    })
  }
  s3_task_buckets = [module.base_architecture.s3_bucket]
  vpc_id          = module.base_architecture.vpc_id
  vpc_subnet_ids  = module.base_architecture.vpc_private_subnet_ids
  vpc_security_groups_extra = [
    module.base_architecture.vpc_egress_security_group_id,
    aws_security_group.solr.id,
    aws_security_group.email.id,
  ]
  alb_arn                                = module.base_architecture.alb_arn
  alb_dns_name                           = module.base_architecture.alb_dns_name
  alb_listener_arn                       = module.base_architecture.alb_https_listener_arn
  ecs_cluster_arn                        = module.base_architecture.ecs_cluster_arn
  route53_zone_id                        = module.base_architecture.route53_public_hosted_zone
  asg_name                               = module.base_architecture.asg_name
  asg_security_group_id                  = module.base_architecture.asg_security_group_id
  alb_security_group_id                  = module.base_architecture.alb_security_group_id
  cloudwatch_log_group_arn               = module.base_architecture.cloudwatch_log_group_arn
  cloudfront_waf_acl_arn                 = module.base_architecture.waf_acl_arn
  cloudfront_allowed_methods             = var.cudl_viewer_allowed_methods
  cloudfront_viewer_request_function_arn = aws_cloudfront_function.viewer.arn
  efs_use_existing_filesystem            = true
  efs_file_system_id                     = module.cudl-data-processing.efs_file_system_id
  efs_security_group_id                  = module.cudl-data-processing.efs_security_group_id
  acm_create_certificate                 = false
  acm_certificate_arn                    = var.acm_certificate_arn
  acm_certificate_arn_us-east-1          = var.acm_certificate_arn_us-east-1
  tags                                   = local.default_tags
  providers = {
    aws.us-east-1 = aws.us-east-1
  }
}
