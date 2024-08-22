/*
At the moment we want to use the existing VPC as this is what the CUDL viewer EC2 instances use
so we will just reference it using data blocks.
When we move the viewer and other EC2 instances over to Terraform management we can control the
VPC under here
*/

data "aws_vpc" "existing_cudl_vpc" {
  id = var.vpc-id
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

data "aws_subnets" "efs" {
  filter {
    name   = "subnet-id"
    values = var.efs_subnet_ids
  }

  # NOTE Filter by VPC to make sure subnets exist in the VPC selected
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.existing_cudl_vpc.id]
  }
}

data "aws_subnet" "efs" {
  for_each = toset(data.aws_subnets.efs.ids)
  id       = each.value
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

resource "aws_security_group" "efs" {
  name        = "${var.environment}-${var.efs-name}"
  description = "Allows access to EFS mount targets for ${var.efs-name}"
  vpc_id      = data.aws_vpc.existing_cudl_vpc.id

  tags = {
    Name = "${var.environment}-${var.efs-name}"
  }
}

resource "aws_security_group_rule" "efs_ingress_nfs_from_vpc" {
  type              = "ingress"
  protocol          = "tcp"
  description       = "EFS Ingress on port ${var.efs_nfs_mount_port} for ${var.efs-name}"
  security_group_id = aws_security_group.efs.id
  cidr_blocks       = [data.aws_vpc.existing_cudl_vpc.cidr_block]
  ipv6_cidr_blocks  = data.aws_vpc.existing_cudl_vpc.ipv6_cidr_block != "" ? [data.aws_vpc.existing_cudl_vpc.ipv6_cidr_block] : []
  from_port         = var.efs_nfs_mount_port
  to_port           = var.efs_nfs_mount_port
}

resource "aws_security_group_rule" "efs_egress_nfs_to_vpc" {
  type              = "egress"
  protocol          = "tcp"
  description       = "EFS Egress on port ${var.efs_nfs_mount_port} for ${var.efs-name}"
  security_group_id = aws_security_group.efs.id
  cidr_blocks       = [data.aws_vpc.existing_cudl_vpc.cidr_block]
  ipv6_cidr_blocks  = data.aws_vpc.existing_cudl_vpc.ipv6_cidr_block != "" ? [data.aws_vpc.existing_cudl_vpc.ipv6_cidr_block] : []
  from_port         = var.efs_nfs_mount_port
  to_port           = var.efs_nfs_mount_port
}
