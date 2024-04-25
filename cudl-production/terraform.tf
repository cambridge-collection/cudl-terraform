terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.44.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.1.0"
    }
  }

  backend "s3" {
    bucket         = "terraform-state-kie4di"
    key            = "production-cudl-infra.tfstate"
    dynamodb_table = "terraform-state-lock-kie4di"
    region         = "eu-west-1"
  }

  required_version = ">= 0.14.9"
}
