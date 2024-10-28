provider "aws" {
  region = var.deployment-aws-region

  default_tags {
    tags = local.default_tags
  }
}

provider "aws" {
  region = "us-east-1"
  alias  = "us-east-1"

  default_tags {
    tags = local.default_tags
  }
}
