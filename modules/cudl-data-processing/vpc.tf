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