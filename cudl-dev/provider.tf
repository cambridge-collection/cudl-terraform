provider "aws" {
  region = var.deployment-aws-region

  default_tags {
    tags = local.default_tags
  }
}
