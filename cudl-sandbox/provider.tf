provider "aws" {
  region = var.deployment-aws-region

  default_tags {
    tags = {
      Environment = title(var.environment)
      Project     = "CUDL"
      env         = title(var.environment)
      service     = "CUDL"
    }
  }
}
