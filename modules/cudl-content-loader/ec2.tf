#resource "aws_ebs_volume" "cudl-content-loader-ec2-volume1" {
#  availability_zone = "eu-west-1a"
#  encrypted = false
#  size = 30
#  type = "gp2"
#  //snapshot_id = "snap-03440960b62ba3f73"
#  tags = {
#    Name = "${var.environment}-cudl-ecs-volume1"
#  }
#  depends_on = [
#    aws_vpc.cudl-content-loader-vpc,
#    aws_route_table.cudl-loader-cudl-rtb-private1-eu-west-1a,
#    aws_route53_zone.cudl-route53-zone
#  ]
#}

// defined in console
#resource "aws_key_pair" "EC2KeyPair" {
#  public_key = "REPLACEME" //TODO
#  key_name = "cudl-sandbox"
#}

resource "aws_instance" "cudl-content-loader-ec2-instance" {
  ami = "ami-064bfa32b2b2e0855" // public amazon ecs image
  instance_type = "t3.small"
  key_name = "cudl-sandbox"
  availability_zone = "eu-west-1a"
  tenancy = "default"
  subnet_id = aws_subnet.cudl-content-loader-ec2-subnet-public1.id

  ebs_optimized = false
  vpc_security_group_ids = [
    aws_security_group.cudl-loader-security-group.id
  ]
  source_dest_check = true
  root_block_device {
    volume_size = 30
    volume_type = "gp2"
    delete_on_termination = true
  }
  user_data = "#!/bin/bash\necho \"ECS_CLUSTER=${aws_ecs_cluster.cudl-loader-ecs-cluster.name}\" >> /etc/ecs/ecs.config"
  //user_data = "IyEvYmluL2Jhc2ggCgojY2F0IDw8J0VPRicgPj4gL2V0Yy9lY3MvZWNzLmNvbmZpZwojRUNTX0NMVVNURVI9Q1VETENvbnRlbnRDbHVzdGVyCiNFQ1NfTE9HTEVWRUw9ZGVidWcKI0VDU19FTkFCTEVfVEFTS19JQU1fUk9MRT10cnVlCiNFT0YKI3N0YXJ0IGVjcwojZWNobyAiRG9uZSIKCmVjaG8gIkVDU19DTFVTVEVSPUNVRExDb250ZW50Q2x1c3RlciIgPj4gL2V0Yy9lY3MvZWNzLmNvbmZpZw=="
  iam_instance_profile = aws_iam_instance_profile.cudl-content-loader-iam-instance-profile.name
  monitoring = true
  tags = {
    AmazonECSManaged = ""
  }
  depends_on = [
    aws_ecs_cluster.cudl-loader-ecs-cluster,
    aws_iam_role.cudl-content-loader-iam-task-role,
    aws_subnet.cudl-content-loader-ec2-subnet-public1,
    aws_security_group.cudl-loader-security-group
  ]
}

resource "aws_launch_template" "cudl-loader-ec2-launch-template" {
  name = "${var.environment}-cudl-loader-ec2-launch-template"
 # user_data = base64encode("#!/bin/bash\necho \"ECS_CLUSTER=${aws_ecs_cluster.cudl-loader-ecs-cluster.name}\" >> /etc/ecs/ecs.config")
  user_data = base64encode("#!/bin/bash\necho \"ECS_CLUSTER=${var.environment}-${var.cluster_name_suffix}\" >> /etc/ecs/ecs.config")
  #user_data = "IyEvYmluL2Jhc2ggCgojY2F0IDw8J0VPRicgPj4gL2V0Yy9lY3MvZWNzLmNvbmZpZwojRUNTX0NMVVNURVI9Q1VETENvbnRlbnRDbHVzdGVyCiNFQ1NfTE9HTEVWRUw9ZGVidWcKI0VDU19FTkFCTEVfVEFTS19JQU1fUk9MRT10cnVlCiNFT0YKI3N0YXJ0IGVjcwojZWNobyAiRG9uZSIKCmVjaG8gIkVDU19DTFVTVEVSPUNVRExDb250ZW50Q2x1c3RlciIgPj4gL2V0Yy9lY3MvZWNzLmNvbmZpZw=="
  iam_instance_profile {
    arn = aws_iam_instance_profile.cudl-content-loader-iam-instance-profile.arn
  }
  vpc_security_group_ids = [
    aws_security_group.cudl-loader-security-group.id
  ]
  key_name = "cudl-sandbox"
  image_id = "ami-064bfa32b2b2e0855" // public amazon ecs image
  instance_type = "t3.small"
  monitoring {
    enabled = true
  }
  depends_on = [
    aws_iam_role.cudl-content-loader-iam-task-role,
    aws_subnet.cudl-content-loader-ec2-subnet-public1,
    aws_security_group.cudl-loader-security-group
  ]
}

#resource "aws_volume_attachment" "cudl-loader-ec2-volume-attachment" {
#  volume_id = aws_ebs_volume.cudl-content-loader-ec2-volume1.id
#  instance_id = aws_instance.cudl-content-loader-ec2-instance.id
#  device_name = "/dev/xvda"
#  depends_on = [
#    aws_ebs_volume.cudl-content-loader-ec2-volume1,
#    aws_instance.cudl-content-loader-ec2-instance
#  ]
#}

data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

resource "aws_security_group" "cudl-loader-security-group" {
  name        = "${var.environment}-cudl-loader-security-group"
  description = "Allow access from CloudFront on port 443 and any access from same security group"
  vpc_id      = aws_vpc.cudl-content-loader-vpc.id

  tags = {
    Name = "${var.environment}-cudl-loader-security-group"
  }
}

resource "aws_security_group_rule" "cudl-loader-security-group-allow-443" {
  type              = "ingress"
  protocol          = "tcp"
  description = "${var.environment}-cudl-loader-HTTPS from CloudFront"
  security_group_id = aws_security_group.cudl-loader-security-group.id
  from_port         = 443
  to_port           = 443
  prefix_list_ids   = [data.aws_ec2_managed_prefix_list.cloudfront.id]
  depends_on = [aws_security_group.cudl-loader-security-group]
}

resource "aws_security_group_rule" "cudl-loader-security-group-allow-same-sg" {
  type              = "ingress"
  protocol          = "tcp"
  description = "${var.environment}-cudl-loader-allow-same-sg"
  security_group_id = aws_security_group.cudl-loader-security-group.id
  from_port         = 0 # all ports
  to_port           = 0 # all ports
  source_security_group_id   = aws_security_group.cudl-loader-security-group.id
  depends_on = [aws_security_group.cudl-loader-security-group]
}

resource "aws_security_group_rule" "cudl-loader-allow-all-out-ipv4" {
  type              = "egress"
  protocol          = "tcp"
  description = "${var.environment}-cudl-loader-allow-all-out-ipv4"
  security_group_id = aws_security_group.cudl-loader-security-group.id
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  from_port         = 0 # all ports
  to_port           = 0 # all ports
  depends_on = [aws_security_group.cudl-loader-security-group]
}



