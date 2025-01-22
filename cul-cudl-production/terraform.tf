terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.70.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "> 2.3.0"
    }
  }

  backend "s3" {
    bucket         = "cul-cudl-terraform-state"
    key            = "cul-cudl-infra-prod.tfstate"
    dynamodb_table = "terraform-state-lock-cudl" # LockID
    region         = "eu-west-1"
  }

  required_version = "~> 1.9.7"
}
