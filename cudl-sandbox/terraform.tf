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
    bucket         = "sandbox-cudl-terraform-state"
    key            = "mjh39-sandbox--content-loader-cudl-infra.tfstate"
    dynamodb_table = "terraform-state-lock-cudl"
    region         = "eu-west-1"
  }

  required_version = "~> 1.7.5"
}
