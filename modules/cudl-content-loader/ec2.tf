resource "aws_launch_template" "cudl-loader-ec2-launch-template" {
  name = "${var.environment}-cudl-loader-ec2-launch-template"
  user_data = base64encode("#!/bin/bash\necho \"ECS_CLUSTER=${var.environment}-${var.cluster_name_suffix}\" >> /etc/ecs/ecs.config")
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

data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

resource "aws_security_group" "cudl-loader-security-group" {
  name        = "${var.environment}-cudl-loader-security-group"
  description = "Allow access from CloudFront on port 8081 and any access from same security group"
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
  protocol          = "all"
  description = "${var.environment}-cudl-loader-allow-same-sg"
  security_group_id = aws_security_group.cudl-loader-security-group.id
  from_port         = 0 # all ports
  to_port           = 0 # all ports
  source_security_group_id   = aws_security_group.cudl-loader-security-group.id
  depends_on = [aws_security_group.cudl-loader-security-group]
}

resource "aws_security_group_rule" "cudl-loader-allow-all-out-ipv4" {
  type              = "egress"
  protocol          = "all"
  description = "${var.environment}-cudl-loader-allow-all-out-ipv4"
  security_group_id = aws_security_group.cudl-loader-security-group.id
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  from_port         = 0 # all ports
  to_port           = 0 # all ports
  depends_on = [aws_security_group.cudl-loader-security-group]
}



