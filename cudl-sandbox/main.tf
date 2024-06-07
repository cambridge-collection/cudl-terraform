data "aws_caller_identity" "current" {}

module "cudl-data-processing" {
  source                                    = "../modules/cudl-data-processing"
  chunks                                    = var.chunks
  compressed-lambdas-directory              = var.compressed-lambdas-directory
  data-function-name                        = var.data-function-name
  destination-bucket-name                   = var.destination-bucket-name
  dst-efs-prefix                            = var.dst-efs-prefix
  dst-prefix                                = var.dst-prefix
  dst-s3-prefix                             = var.dst-s3-prefix
  efs-name                                  = var.efs-name
  lambda-alias-name                         = var.lambda-alias-name
  lambda-jar-bucket                         = var.lambda-jar-bucket
  lambda-layer-bucket                       = var.lambda-layer-bucket
  lambda-layer-filepath                     = var.lambda-layer-filepath
  lambda-layer-name                         = var.lambda-layer-name
  large-file-limit                          = var.large-file-limit
  releases-root-directory-path              = var.releases-root-directory-path
  tmp-dir                                   = var.tmp-dir
  transcription-function-name               = var.transcription-function-name
  transcriptions-bucket-name                = var.transcriptions-bucket-name
  transform-lambda-information              = var.transform-lambda-information
  additional_lambda_environment_variables   = local.additional_lambda_variables
  vpc-id                                    = var.vpc-id
  security-group-id                         = var.security-group-id
  subnet-id                                 = var.subnet-id
  lambda-db-jdbc-driver                     = var.lambda-db-jdbc-driver
  lambda-db-secret-key                      = var.lambda-db-secret-key
  lambda-db-url                             = var.lambda-db-url
  aws-account-number                        = data.aws_caller_identity.current.account_id
  transform-lambda-bucket-sns-notifications = var.transform-lambda-bucket-sns-notifications
  transform-lambda-bucket-sqs-notifications = var.transform-lambda-bucket-sqs-notifications
  environment                               = local.environment
  transcription-pagify-xslt                 = var.transcription-pagify-xslt
  transcription-mstei-xslt                  = var.transcription-mstei-xslt
  source-bucket-name                        = var.source-bucket-name
  cloudfront_route53_zone_id                = var.cloudfront_route53_zone_id
  create_cloudfront_distribution            = var.create_cloudfront_distribution
  providers = {
    aws.us-east-1 = aws.us-east-1
  }
}

module "cudl-data-enhancements" {
  source                               = "../modules/cudl-data-enhancements"
  environment                          = local.environment
  aws-account-number                   = data.aws_caller_identity.current.account_id
  transkribus-bucket-name              = var.transkribus-bucket-name
  enhancements-lambda-information      = var.enhancements-lambda-information
  lambda-jar-bucket                    = var.lambda-jar-bucket
  enhancements-lambda-layer-name       = var.enhancements-lambda-layer-name
  lambda-layer-bucket                  = var.lambda-layer-bucket
  enhancements-lambda-layer-filepath   = var.enhancements-lambda-layer-filepath
  subnet-id                            = var.subnet-id
  security-group-id                    = var.security-group-id
  dst-efs-prefix                       = var.dst-efs-prefix
  releases-root-directory-path         = var.releases-root-directory-path
  efs-name                             = var.efs-name
  enhancements-destination-bucket-name = var.enhancements-destination-bucket-name
  enhancements-dst-s3-prefix           = var.enhancements-dst-s3-prefix
  tmp-dir                              = var.tmp-dir

}
