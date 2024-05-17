/*
At the moment we want to use the existing VPC as this is what the CUDL viewer EC2 instances use
so we will just reference it using data blocks.
When we move the viewer and other EC2 instances over to Terraform management we can control the
VPC under here
*/

data "aws_vpc" "existing_cudl_vpc" {
  id = var.vpc-id
}

data "aws_subnet" "cudl_subnet" {
  id = var.subnet-id
}

data "aws_security_group" "default" {
  id = var.security-group-id
}

data "aws_vpc" "transform_lambda_vpc" {
  count = length(var.transform-lambda-information)

  tags = {
    Name = coalesce(var.transform-lambda-information[count.index].vpc_name, var.default-lambda-vpc)
  }
}

data "aws_subnets" "transform_lambda_subnets" {
  count = length(var.transform-lambda-information)

  filter {
    name   = "tag:Name"
    values = coalescelist(var.transform-lambda-information[count.index].subnet_names, [var.default-lambda-subnet])
  }

  # NOTE Filter by VPC to make sure subnets exist in the VPC selected
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.transform_lambda_vpc[count.index].id]
  }
}

data "aws_security_groups" "transform_lambda_security_groups" {
  count = length(var.transform-lambda-information)

  filter {
    name   = "group-name"
    values = coalescelist(var.transform-lambda-information[count.index].security_group_names, [var.default-lambda-security-group])
  }

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.transform_lambda_vpc[count.index].id]
  }
}

/*
resource "aws_vpc" "cudl_vpc" {
  cidr_block = var.cidr-blocks[0]

  tags = {
    Name = "${var.environment}-${var.vpc-name}"
  }
}

resource "aws_vpc_ipv4_cidr_block_association" "additional_cidr_blocks" {
  for_each = local.other-cidr-blocks

  vpc_id     = aws_vpc.cudl_vpc.id
  cidr_block = each.value
}

resource "aws_vpc_dhcp_options" "dhcp_options_set" {
  domain_name         = var.domain-name
  domain_name_servers = ["AmazonProvidedDNS"]

  tags = {
    Name = "${var.environment}-${var.dchp-options-name}"
  }
}

resource "aws_vpc_dhcp_options_association" "association" {
  vpc_id          = aws_vpc.cudl_vpc.id
  dhcp_options_id = aws_vpc_dhcp_options.dhcp_options_set.id
}

resource "aws_subnet" "subnet_private" {
  vpc_id                  = aws_vpc.cudl_vpc.id
  cidr_block              = var.cidr-blocks
  map_public_ip_on_launch = false
  tags = {
    Name = "${var.project}-subnet-private"
  }
}*/
