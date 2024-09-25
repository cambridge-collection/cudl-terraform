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
    random = {
      source  = "hashicorp/random"
      version = "> 2.3.0"
    }
  }

  backend "s3" {
    bucket         = "cul-cudl-terraform-state"
    key            = "cul-cudl-infra-staging.tfstate"
    dynamodb_table = "terraform-state-lock-cudl" # LockID
    region         = "eu-west-1"
  }

  required_version = "~> 1.7.5"
}
