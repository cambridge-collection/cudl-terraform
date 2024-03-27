// TODO This is still a work in progress
// At the moment I have manually created a Elastic IP and assigned it to the ec2 instance and put this
// instance into the public subnet so that I would easily connect to it for debugging.
// Note SSH is restricted by UL IP range in security group.
// However we possibly want the EC2 in the private subnet with NAT gateway?
// Using internet gateway from public subnet atm.

// Also the nameservers for Route 53 hosted Zones need to match nameservers from Route53 Registered domains
// This was done manually.  It would be good if terraform could sort that. (Note console does not always show correct
// info for nameservers use CLI to check nameservers

// Also we have manually created the Route53 records from the Certificate Manager in the two zones (it requires
// a certificate entry in eu-west-1 which is where most of our deployment is and in us-east-1 for CloudFront, both
// using the same domain registration). We need to update Terraform to do that.


#resource "aws_network_interface" "cudl-content-loader-ec2-network-interface" {
#  tags = {
#    Name = "${var.environment}-cudl-ec2-ni"
#  }
#  description = ""
#  private_ips = [
#    "10.0.10.25"
#  ]
#  subnet_id = aws_subnet.cudl-content-loader-ec2-subnet-public1.id
#  source_dest_check = true
#  security_groups = [
#    aws_security_group.cudl-loader-security-group.id
#  ]
#  depends_on = [
#    aws_subnet.cudl-content-loader-ec2-subnet-public1,
#    aws_security_group.cudl-loader-security-group
#  ]
#}

resource "aws_vpc" "cudl-content-loader-vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  instance_tenancy = "default"
  tags = {
    Name = "${var.environment}-cudl-content-loader-vpc"
  }
}

resource "aws_subnet" "cudl-content-loader-ec2-subnet-public1" {
  tags = {
    Name = "${var.environment}-cudl-subnet-public1"
  }
  availability_zone = "eu-west-1a"
  cidr_block = "10.0.0.0/20"
  vpc_id = aws_vpc.cudl-content-loader-vpc.id
  map_public_ip_on_launch = false
  depends_on = [
    aws_vpc.cudl-content-loader-vpc
  ]
}

resource "aws_subnet" "cudl-content-loader-ec2-subnet-private1" {
  tags = {
    Name = "${var.environment}-cudl-subnet-private1"
  }
  availability_zone = "eu-west-1a"
  cidr_block = "10.0.128.0/20"
  vpc_id = aws_vpc.cudl-content-loader-vpc.id
  map_public_ip_on_launch = false
  depends_on = [
    aws_vpc.cudl-content-loader-vpc
  ]
}

resource "aws_subnet" "cudl-content-loader-ec2-subnet-public2" {
  tags = {
    Name = "${var.environment}-cudl-subnet-public2"
  }
  availability_zone = "eu-west-1b"
  cidr_block = "10.0.16.0/20"
  vpc_id = aws_vpc.cudl-content-loader-vpc.id
  map_public_ip_on_launch = false
  depends_on = [
    aws_vpc.cudl-content-loader-vpc
  ]
}

resource "aws_subnet" "cudl-content-loader-ec2-subnet-private2" {
  tags = {
    Name = "${var.environment}-cudl-subnet-private1"
  }
  availability_zone = "eu-west-1b"
  cidr_block = "10.0.144.0/20"
  vpc_id = aws_vpc.cudl-content-loader-vpc.id
  map_public_ip_on_launch = false
  depends_on = [
    aws_vpc.cudl-content-loader-vpc
  ]
}

resource "aws_route_table" "cudl-loader-cudl-rtb-main" {
  tags = {
    Name = "${var.environment}-cudl-rtb-main"
  }
  vpc_id = aws_vpc.cudl-content-loader-vpc.id
  depends_on = [
    aws_vpc.cudl-content-loader-vpc
  ]
}

resource "aws_route_table" "cudl-loader-cudl-rtb-pubic" {
  vpc_id = aws_vpc.cudl-content-loader-vpc.id
  tags = {
    Name = "${var.environment}-cudl-rtb-public"
  }
  depends_on = [
    aws_vpc.cudl-content-loader-vpc
  ]
}

resource "aws_route_table" "cudl-loader-cudl-rtb-private1-eu-west-1a" {

  vpc_id = aws_vpc.cudl-content-loader-vpc.id
  tags = {
    Name = "${var.environment}-cudl-rtb-private1-eu-west-1a"
  }
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.cudl-nat-1a.id
  }
  depends_on = [
    aws_vpc.cudl-content-loader-vpc
  ]
}

resource "aws_route_table" "cudl-loader-cudl-rtb-private2-eu-west-1b" {
  vpc_id = aws_vpc.cudl-content-loader-vpc.id
  tags = {
    Name = "${var.environment}-cudl-rtb-private2-eu-west-1b"
  }
  depends_on = [
    aws_vpc.cudl-content-loader-vpc
  ]
}

resource "aws_route_table_association" "cudl-loader-cudl-vpc-route-table-association_1" {
  route_table_id = aws_route_table.cudl-loader-cudl-rtb-pubic.id
  subnet_id = aws_subnet.cudl-content-loader-ec2-subnet-public1.id
  depends_on = [
    aws_subnet.cudl-content-loader-ec2-subnet-public1,
    aws_route_table.cudl-loader-cudl-rtb-pubic
  ]
}

resource "aws_route_table_association" "cudl-loader-cudl-vpc-route-table-association_2" {
  route_table_id = aws_route_table.cudl-loader-cudl-rtb-private1-eu-west-1a.id
  subnet_id = aws_subnet.cudl-content-loader-ec2-subnet-private1.id
  depends_on = [
    aws_subnet.cudl-content-loader-ec2-subnet-private1,
    aws_route_table.cudl-loader-cudl-rtb-private1-eu-west-1a
  ]
}

resource "aws_route_table_association" "cudl-loader-cudl-vpc-route-table-association_3" {
  route_table_id = aws_route_table.cudl-loader-cudl-rtb-pubic.id
  subnet_id = aws_subnet.cudl-content-loader-ec2-subnet-public2.id
  depends_on = [
    aws_subnet.cudl-content-loader-ec2-subnet-public2,
    aws_route_table.cudl-loader-cudl-rtb-pubic
  ]
}

resource "aws_route_table_association" "cudl-loader-cudl-vpc-route-table-association_4" {
  route_table_id = aws_route_table.cudl-loader-cudl-rtb-private2-eu-west-1b.id
  subnet_id = aws_subnet.cudl-content-loader-ec2-subnet-private2.id
  depends_on = [
    aws_subnet.cudl-content-loader-ec2-subnet-private2,
    aws_route_table.cudl-loader-cudl-rtb-private2-eu-west-1b
  ]
}

resource "aws_vpc_dhcp_options_association" "cudl-loader-cudl-vpc-dhcp-options-association" {
  dhcp_options_id = aws_vpc_dhcp_options.cudl-loader-cudl-vpc-dhcp-options.id
  vpc_id = aws_vpc.cudl-content-loader-vpc.id
  depends_on = [
    aws_vpc.cudl-content-loader-vpc,
    aws_vpc_dhcp_options.cudl-loader-cudl-vpc-dhcp-options
  ]
}

resource "aws_vpc_dhcp_options" "cudl-loader-cudl-vpc-dhcp-options" {
  domain_name = "eu-west-1.compute.internal"
  domain_name_servers = ["AmazonProvidedDNS"]
  tags = {
    Name = "${var.environment}-cudl-loader-vpc-dhcp-options"
  }
}

resource "aws_internet_gateway" "cudl-loader-cudl-vpc-internet-gateway" {
  tags = {
    Name = "${var.environment}-cudl-igw"
  }
  vpc_id = aws_vpc.cudl-content-loader-vpc.id
  depends_on = [
    aws_vpc.cudl-content-loader-vpc
  ]
}

resource "aws_vpc_endpoint" "cudl-content-loader-vpc-endpoint" {
  tags = {
    name = "${var.environment}-cudl-content-loader-vpc-endpoint"
  }
  vpc_endpoint_type = "Gateway"
  vpc_id = aws_vpc.cudl-content-loader-vpc.id
  service_name = "com.amazonaws.eu-west-1.s3"
  policy = "{\"Version\":\"2008-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":\"*\",\"Action\":\"*\",\"Resource\":\"*\"}]}"
  route_table_ids = [
    aws_route_table.cudl-loader-cudl-rtb-private1-eu-west-1a.id,
    aws_route_table.cudl-loader-cudl-rtb-private2-eu-west-1b.id
  ]
  private_dns_enabled = false
  depends_on = [
    aws_vpc.cudl-content-loader-vpc,
    aws_route_table.cudl-loader-cudl-rtb-private1-eu-west-1a,
    aws_route_table.cudl-loader-cudl-rtb-private2-eu-west-1b
  ]
}

resource "aws_vpc_endpoint_route_table_association" "cudl-loader-cudl-vpc-ec2-route1-s3" {
  route_table_id = aws_route_table.cudl-loader-cudl-rtb-private1-eu-west-1a.id
  vpc_endpoint_id = aws_vpc_endpoint.cudl-content-loader-vpc-endpoint.id
  depends_on = [
    aws_vpc.cudl-content-loader-vpc,
    aws_vpc_endpoint.cudl-content-loader-vpc-endpoint,
    aws_route_table.cudl-loader-cudl-rtb-private1-eu-west-1a
  ]
}

resource "aws_vpc_endpoint_route_table_association" "cudl-loader-cudl-vpc-ec2-route2-s3" {
  route_table_id = aws_route_table.cudl-loader-cudl-rtb-private2-eu-west-1b.id
  vpc_endpoint_id = aws_vpc_endpoint.cudl-content-loader-vpc-endpoint.id
  depends_on = [
    aws_vpc.cudl-content-loader-vpc,
    aws_vpc_endpoint.cudl-content-loader-vpc-endpoint,
    aws_route_table.cudl-loader-cudl-rtb-private2-eu-west-1b
  ]
}


resource "aws_route_table_association" "cudl-route-table-association-nat" {
  subnet_id      = aws_subnet.cudl-content-loader-ec2-subnet-private1.id
  route_table_id = aws_route_table.cudl-loader-cudl-rtb-private1-eu-west-1a.id
  depends_on = [
    aws_route_table.cudl-loader-cudl-rtb-private1-eu-west-1a
  ]
}


resource "aws_route" "cudl-loader-cudl-vpc-ec2-route-ig" {
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.cudl-loader-cudl-vpc-internet-gateway.id
  route_table_id = aws_route_table.cudl-loader-cudl-rtb-pubic.id
  depends_on = [
    aws_vpc.cudl-content-loader-vpc,
    aws_internet_gateway.cudl-loader-cudl-vpc-internet-gateway,
    aws_route_table.cudl-loader-cudl-rtb-pubic
  ]
}

resource "aws_eip" "cudl-nat-1a-elastic-ip" {
  tags = {
    Name = "${var.environment}-cudl-nat-1a-elastic-ip"
  }
  vpc = true
}

resource "aws_nat_gateway" "cudl-nat-1a" {
  allocation_id = aws_eip.cudl-nat-1a-elastic-ip.id
  subnet_id     = aws_subnet.cudl-content-loader-ec2-subnet-public1.id

  tags = {
    Name = "${var.environment}-cudl-nat-1a"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.cudl-loader-cudl-vpc-internet-gateway]
}

## //TODO remove?
#resource "aws_network_interface_attachment" "cudl-loader-ec2-network-interface-attachment" {
#  network_interface_id = aws_network_interface.cudl-content-loader-ec2-network-interface.id
#  device_index = 0
#  instance_id = aws_instance.cudl-content-loader-ec2-instance.id
#  depends_on = [
#    aws_instance.cudl-content-loader-ec2-instance,
#    aws_network_interface.cudl-content-loader-ec2-network-interface
#  ]
#}

##// TODO remove
#resource "aws_eip_association" "cudl-loader-ec2-eip-association" {
#  allocation_id = "eipalloc-010c4577858fc4882" //TODO
#  instance_id = aws_instance.cudl-content-loader-ec2-instance.id
#  network_interface_id = aws_network_interface.cudl-content-loader-ec2-network-interface.id
#  private_ip_address = "10.0.10.25"
#  depends_on = [
#    aws_instance.cudl-content-loader-ec2-instance,
#    aws_network_interface.cudl-content-loader-ec2-network-interface
#  ]
#}
