data "aws_caller_identity" "current" {}

module "cudl-data-processing" {
  source                                  = "../modules/cudl-data-processing"
  compressed-lambdas-directory            = var.compressed-lambdas-directory
  destination-bucket-name                 = var.destination-bucket-name
  dst-efs-prefix                          = var.dst-efs-prefix
  dst-prefix                              = var.dst-prefix
  dst-s3-prefix                           = var.dst-s3-prefix
  efs-name                                = var.efs-name
  lambda-alias-name                       = var.lambda-alias-name
  releases-root-directory-path            = var.releases-root-directory-path
  tmp-dir                                 = var.tmp-dir
  transform-lambda-information            = var.transform-lambda-information
  additional_lambda_environment_variables = local.additional_lambda_variables
  enhancements_lambda_environment_variables = local.enhancements_lambda_variables
  vpc-id                                  = var.vpc-id
  security-group-id                       = var.security-group-id
  subnet-id                               = var.subnet-id
  lambda-jar-bucket                       = var.lambda-jar-bucket
  lambda-db-jdbc-driver                   = var.lambda-db-jdbc-driver
  lambda-db-secret-key                    = var.lambda-db-secret-key
  lambda-db-url                           = var.lambda-db-url
  aws-account-number                      = data.aws_caller_identity.current.account_id
  transform-lambda-bucket-sns-notifications         = var.transform-lambda-bucket-sns-notifications
  transform-lambda-bucket-sqs-notifications         = var.transform-lambda-bucket-sqs-notifications
  environment                             = local.environment
  source-bucket-name                      = var.source-bucket-name
  enhancements-bucket-name                = var.enhancements-bucket-name
  cloudfront_route53_zone_id              = var.cloudfront_route53_zone_id
  create_cloudfront_distribution          = var.create_cloudfront_distribution
  providers = {
    aws.us-east-1 = aws.us-east-1
  }
}
