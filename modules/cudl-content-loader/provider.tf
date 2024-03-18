// Needs Certificate Manager entry for us-east-1 for CloudFront access
provider "aws" {
  region = "us-east-1"
  alias = "us-east-1"

  default_tags {
    tags = {
      Environment = title(var.environment)
      Project     = "CUDL"
      env         = title(var.environment)
      service     = "CUDL"
      creator     = "jlf44"
    }
  }
}
