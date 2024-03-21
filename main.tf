terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.24.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.1.0"
    }
  }

  backend "s3" {
    bucket         = "terraform-state-kie4di"
    key            = "dev-cudl-infra.tfstate"
    dynamodb_table = "terraform-state-lock-kie4di"
    region         = "eu-west-1"
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  region = var.deployment-aws-region
  profile = "default"

  default_tags {
    tags = {
      Environment = title(var.environment)
      Project     = "CUDL"
      env         = title(var.environment)
      service     = "CUDL"
    }
  }
}

module "cudl-data-processing" {
  source                          = "../modules/cudl-data-processing"
  chunks                          = var.chunks
  compressed-lambdas-directory    = var.compressed-lambdas-directory
  data-function-name              = var.data-function-name
  db-lambda-information           = var.db-lambda-information
  destination-bucket-name         = var.destination-bucket-name
  dst-efs-prefix                  = var.dst-efs-prefix
  dst-prefix                      = var.dst-prefix
  dst-s3-prefix                   = var.dst-s3-prefix
  efs-name                        = var.efs-name
  lambda-alias-name               = var.lambda-alias-name
  lambda-jar-bucket               = var.lambda-jar-bucket
  lambda-layer-bucket             = var.lambda-layer-bucket
  lambda-layer-filepath           = var.lambda-layer-filepath
  lambda-layer-name               = var.lambda-layer-name
  large-file-limit                = var.large-file-limit
  releases-root-directory-path    = var.releases-root-directory-path
  source-bucket-name              = var.source-bucket-name
  tmp-dir                         = var.tmp-dir
  transcription-function-name     = var.transcription-function-name
  transcriptions-bucket-name      = var.transcriptions-bucket-name
  transform-lambda-information    = var.transform-lambda-information
  vpc-id                          = var.vpc-id
  security-group-id               = var.security-group-id
  subnet-id                       = var.subnet-id
  lambda-db-jdbc-driver           = var.lambda-db-jdbc-driver
  lambda-db-secret-key            = var.lambda-db-secret-key
  lambda-db-url                   = var.lambda-db-url
  aws-account-number              = var.aws-account-number
  source-bucket-sns-notifications = var.source-bucket-sns-notifications
  source-bucket-sqs-notifications = var.source-bucket-sqs-notifications
  environment                     = var.environment
  db-only-processing              = var.db-only-processing
  transcription-pagify-xslt       = var.transcription-pagify-xslt
  transcription-mstei-xslt        = var.transcription-mstei-xslt
}

module "cudl-data-enhancements" {
  source                               = "../modules/cudl-data-enhancements"
  environment                          = var.environment
  aws-account-number                   = var.aws-account-number
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