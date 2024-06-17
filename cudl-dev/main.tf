data "aws_caller_identity" "current" {}

module "cudl-data-processing" {
  source                                    = "../modules/cudl-data-processing"
  compressed-lambdas-directory              = var.compressed-lambdas-directory
  destination-bucket-name                   = var.destination-bucket-name
  dst-efs-prefix                            = var.dst-efs-prefix
  dst-prefix                                = var.dst-prefix
  dst-s3-prefix                             = var.dst-s3-prefix
  efs-name                                  = var.efs-name
  lambda-alias-name                         = var.lambda-alias-name
  releases-root-directory-path              = var.releases-root-directory-path
  tmp-dir                                   = var.tmp-dir
  transform-lambda-information              = var.transform-lambda-information
  additional_lambda_environment_variables   = local.additional_lambda_variables
  enhancements_lambda_environment_variables = local.enhancements_lambda_variables
  vpc-id                                    = var.vpc-id
  security-group-id                         = var.security-group-id
  subnet-id                                 = var.subnet-id
  lambda-jar-bucket                         = var.lambda-jar-bucket
  lambda-db-jdbc-driver                     = var.lambda-db-jdbc-driver
  lambda-db-secret-key                      = var.lambda-db-secret-key
  lambda-db-url                             = var.lambda-db-url
  aws-account-number                        = data.aws_caller_identity.current.account_id
  transform-lambda-bucket-sns-notifications = var.transform-lambda-bucket-sns-notifications
  transform-lambda-bucket-sqs-notifications = var.transform-lambda-bucket-sqs-notifications
  environment                               = local.environment
  source-bucket-name                        = var.source-bucket-name
  enhancements-bucket-name                  = var.enhancements-bucket-name
  cloudfront_route53_zone_id                = var.cloudfront_route53_zone_id
  create_cloudfront_distribution            = var.create_cloudfront_distribution
  providers = {
    aws.us-east-1 = aws.us-east-1
  }
}


module "base_architecture" {
  source = "git::https://github.com/cambridge-collection/terraform-aws-architecture-ecs"

  name_prefix                    = join("-", compact([var.environment, var.cluster_name_suffix]))
  ec2_instance_type              = var.ec2_instance_type
  route53_zone_domain_name       = var.registered_domain_name
  route53_zone_id_existing       = var.route53_zone_id_existing
  route53_zone_force_destroy     = var.route53_zone_force_destroy
  asg_desired_capacity           = var.asg_desired_capacity
  asg_max_size                   = var.asg_max_size
  alb_enable_deletion_protection = var.alb_enable_deletion_protection
  vpc_public_subnet_public_ip    = var.vpc_public_subnet_public_ip
  cloudwatch_log_group           = var.cloudwatch_log_group # TODO create log group
  tags                           = local.default_tags
}

module "solr" {
  source = "../../terraform-aws-workload-ecs/"

  ecs_cluster_name                          = "CUDLSolr"
  name_prefix                               = join("-", compact([var.environment, var.solr_name_suffix]))
  account_id                                = data.aws_caller_identity.current.account_id
  domain_name                               = join(".", [join("-", compact([var.environment, var.cluster_name_suffix, var.solr_domain_name])), var.registered_domain_name])
  alb_target_group_port                     = var.solr_target_group_port
  alb_target_group_health_check_status_code = var.solr_health_check_status_code
  ecr_repository_names                      = var.solr_ecr_repository_names
  ecr_repositories_exist                    = true
  ecs_task_def_container_definitions = jsonencode(local.solr_container_defs)
  ecs_task_def_volumes               = keys(var.solr_ecs_task_def_volumes)
  ecs_task_def_cpu                   = var.solr_ecs_task_def_cpu
  ecs_task_def_memory                = var.solr_ecs_task_def_memory
  ecs_service_container_name         = local.solr_container_name_api
  ecs_service_container_port         = var.solr_api_port
  vpc_id                             = module.base_architecture.vpc_id
  alb_arn                            = module.base_architecture.alb_arn
  alb_dns_name                       = module.base_architecture.alb_dns_name
  alb_listener_arn                   = module.base_architecture.alb_https_listener_arn
  ecs_cluster_arn                    = module.base_architecture.ecs_cluster_arn
  route53_zone_id                    = module.base_architecture.route53_public_hosted_zone
  asg_name                           = module.base_architecture.asg_name
  asg_security_group_id              = module.base_architecture.asg_security_group_id
  alb_security_group_id              = module.base_architecture.alb_security_group_id
  cloudwatch_log_group_arn           = module.base_architecture.cloudwatch_log_group_arn
  cloudfront_waf_acl_arn             = module.base_architecture.waf_acl_arn
  cloudfront_allowed_methods         = var.solr_allowed_methods
  tags                               = local.default_tags
  providers = {
    aws.us-east-1 = aws.us-east-1
  }
}