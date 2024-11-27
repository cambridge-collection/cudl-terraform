
module "cudl-data-processing" {
  source                                    = "../modules/cudl-data-processing"
  production_deployment                     = true
  compressed-lambdas-directory              = var.compressed-lambdas-directory
  destination-bucket-name                   = var.destination-bucket-name
  dst-efs-prefix                            = var.dst-efs-prefix
  dst-prefix                                = var.dst-prefix
  dst-s3-prefix                             = var.dst-s3-prefix
  efs-name                                  = var.efs-name
  efs_subnets                               = zipmap(["${local.base_name_prefix}-subnet-private-a", "${local.base_name_prefix}-subnet-private-b"], module.base_architecture.vpc_private_subnet_ids)
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
  cloudfront_distribution_name              = var.cloudfront_distribution_name
  cloudfront_default_root_object            = var.cloudfront_default_root_object
  cloudfront_origin_path                    = var.cloudfront_origin_path
  cloudfront_error_response_page_path       = var.cloudfront_error_response_page_path
  cloudfront_viewer_request_function_arn    = aws_cloudfront_function.darwin.arn
  providers = {
    aws.us-east-1 = aws.us-east-1
  }
}

module "base_architecture" {
  source = "git::https://github.com/cambridge-collection/terraform-aws-architecture-ecs.git?ref=v2.1.0"

  name_prefix                    = local.base_name_prefix
  ec2_instance_type              = var.ec2_instance_type
  ec2_additional_userdata        = var.ec2_additional_userdata
  route53_zone_domain_name       = var.registered_domain_name
  route53_zone_id_existing       = var.route53_zone_id_existing
  route53_zone_force_destroy     = var.route53_zone_force_destroy
  asg_desired_capacity           = var.asg_desired_capacity
  asg_max_size                   = var.asg_max_size
  alb_enable_deletion_protection = var.alb_enable_deletion_protection
  vpc_public_subnet_public_ip    = var.vpc_public_subnet_public_ip
  cloudwatch_log_group           = var.cloudwatch_log_group # TODO create log group
  vpc_cidr_block                 = var.vpc_cidr_block
  tags                           = local.default_tags
}

module "solr" {
  source = "git::https://github.com/cambridge-collection/terraform-aws-workload-ecs.git?ref=v3.4.0"

  name_prefix                                    = join("-", compact([local.environment, var.solr_name_suffix]))
  account_id                                     = data.aws_caller_identity.current.account_id
  domain_name                                    = join(".", [var.solr_domain_name, var.registered_domain_name])
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
  ecs_task_def_memory                            = local.solr_ecs_task_def_memory
  ecs_service_container_name                     = local.solr_container_name_api
  ecs_service_container_port                     = var.solr_target_group_port
  ecs_service_capacity_provider_name             = module.base_architecture.ecs_capacity_provider_name
  ecs_service_deployment_minimum_healthy_percent = 0
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
  tags                                           = local.default_tags
  providers = {
    aws.us-east-1 = aws.us-east-1
  }
}
